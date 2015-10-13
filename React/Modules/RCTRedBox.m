/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */
#import <AppKit/AppKit.h>

#import "RCTRedBox.h"

#import "RCTBridge.h"
#import "RCTConvert.h"
#import "RCTDefines.h"
#import "RCTUtils.h"
#import "RCTView.h"

#if RCT_DEBUG

@interface ErrorNSTableView : NSTableView;
@end

@implementation ErrorNSTableView
- (BOOL)isFlipped
{
  return YES;
}
@end


@interface RCTRedBoxWindow : NSWindow <NSTableViewDelegate, NSTableViewDataSource>
@end

@implementation RCTRedBoxWindow
{
  ErrorNSTableView *_stackTraceTableView;
  NSString *_lastErrorMessage;
  NSArray *_lastStackTrace;
  NSTextField * _temporaryHeader;
}



- (instancetype)initWithContentRect:(NSRect)frame
{

  if ((self = [super initWithContentRect:frame
                               styleMask:NSClosableWindowMask | NSResizableWindowMask
                                 backing:NSBackingStoreBuffered defer:NO])) {

    RCTView *rootView = [[RCTView alloc] initWithFrame:frame];

    [rootView setBackgroundColor:[NSColor colorWithRed:0.8 green:0 blue:0 alpha:1]];
    rootView.autoresizesSubviews = true;

    const CGFloat buttonHeight = 60;

    CGRect detailsFrame = self.frame;
    detailsFrame.size.height -= buttonHeight;

    _stackTraceTableView = [[ErrorNSTableView alloc] initWithFrame:detailsFrame];
//    _stackTraceTableView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    //_stackTraceTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _stackTraceTableView.delegate = self;
    _stackTraceTableView.dataSource = self;
    NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:@"column"];
    column.width = frame.size.width;
    [_stackTraceTableView addTableColumn:column];

    CALayer *viewLayer = [CALayer layer];
    [_stackTraceTableView setBackgroundColor:[NSColor colorWithRed:0.8 green:0 blue:0 alpha:1]];
    [_stackTraceTableView setWantsLayer:YES];
    [_stackTraceTableView setLayer:viewLayer];
    //[self.contentView addSubview:_stackTraceTableView];


    _temporaryHeader = [[NSTextField alloc] initWithFrame: CGRectMake(20, 20, self.frame.size.width, self.frame.size.height - buttonHeight)];
    _temporaryHeader.textColor = [NSColor whiteColor];
    [_temporaryHeader setBackgroundColor:[NSColor colorWithRed:0.8 green:0 blue:0 alpha:1]];
    //_temporaryHeader.alignment = NSTextAlignmentCenter;
    _temporaryHeader.font = [NSFont boldSystemFontOfSize:14];
    _temporaryHeader.lineBreakMode = NSLineBreakByWordWrapping;
    _temporaryHeader.bordered = NO;
    _temporaryHeader.selectable = YES;
    _temporaryHeader.editable = false;
    [rootView addSubview:_temporaryHeader];


    NSButton *dismissButton = [[NSButton alloc] init];
    [dismissButton setBezelStyle:NSRecessedBezelStyle];
    dismissButton.autoresizingMask = NSViewMaxXMargin | NSViewMaxYMargin;
    dismissButton.accessibilityIdentifier = @"redbox-dismiss";
    dismissButton.font = [NSFont systemFontOfSize:20];
    [dismissButton setTitle:@"Dismiss (ESC)"];
    [dismissButton setTarget:self];
    [dismissButton setAction:@selector(dismiss)];


    NSButton *reloadButton = [[NSButton alloc] init];
    [reloadButton setBezelStyle:NSRecessedBezelStyle];
    reloadButton.autoresizingMask = NSViewMaxXMargin | NSViewMaxYMargin;
    reloadButton.accessibilityIdentifier = @"redbox-reload";
    reloadButton.font = [NSFont systemFontOfSize:20];
    [reloadButton setTitle:@"Reload JS"];
    [reloadButton setTarget:self];
    [reloadButton setAction:@selector(reload)];

    CGFloat buttonWidth = self.frame.size.width / 2;
    dismissButton.frame = CGRectMake(0, self.frame.size.height - buttonHeight, buttonWidth, buttonHeight);
    reloadButton.frame = CGRectMake(buttonWidth, self.frame.size.height - buttonHeight, buttonWidth, buttonHeight);
    [rootView addSubview:dismissButton];
    [rootView addSubview:reloadButton];
    [self setContentView:rootView];
  }
  return self;
}

RCT_NOT_IMPLEMENTED(- (instancetype)initWithCoder:(NSCoder *)aDecoder)

- (void)dealloc
{
  _stackTraceTableView.dataSource = nil;
  _stackTraceTableView.delegate = nil;
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}



- (void)openStackFrameInEditor:(NSDictionary *)stackFrame
{
  NSData *stackFrameJSON = [RCTJSONStringify(stackFrame, nil) dataUsingEncoding:NSUTF8StringEncoding];
  NSString *postLength = [NSString stringWithFormat:@"%tu", stackFrameJSON.length];
  NSMutableURLRequest *request = [NSMutableURLRequest new];
  request.URL = [RCTConvert NSURL:@"http://localhost:8081/open-stack-frame"];
  request.HTTPMethod = @"POST";
  request.HTTPBody = stackFrameJSON;
  [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
  [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

  [[[NSURLSession sharedSession] dataTaskWithRequest:request] resume];
}

- (void)showErrorMessage:(NSString *)message withStack:(NSArray *)stack showIfHidden:(BOOL)shouldShow
{
  //if ((self.hidden && shouldShow) || (!self.hidden && [_lastErrorMessage isEqualToString:message])) {
  if (shouldShow) {
    _lastStackTrace = stack;
    _lastErrorMessage = message;
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:stack.count];
    [stack enumerateObjectsUsingBlock:^(id obj, __unused NSUInteger idx, __unused BOOL *stop) {
      NSString *methodName = obj[@"methodName"];
      NSString *fileAndLine = [obj[@"file"] lastPathComponent];
      NSString *details = fileAndLine ? [fileAndLine stringByAppendingFormat:@":%@", obj[@"lineNumber"]] : nil;
      [result addObject:[methodName stringByAppendingFormat:@"\t%@", details]];
    }];


    [_temporaryHeader setStringValue:[message stringByAppendingString:[result componentsJoinedByString:@"\n"]]];

    [_stackTraceTableView reloadData];

//    if (self.hidden) {
//      [_stackTraceTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
//                                  atScrollPosition:UITableViewScrollPositionTop
//                                          animated:NO];
//    }

    //[self makeKeyWindow];
    [self makeKeyAndOrderFront:nil];
    [self becomeFirstResponder];
  }
}

- (void)dismiss
{
  [self resignFirstResponder];
  [[[NSApplication sharedApplication] mainWindow] makeKeyWindow];
  //[self close]; // TODO: fix BAD_ACCESS when uncommented
}

- (void)reload
{
  [[NSNotificationCenter defaultCenter] postNotificationName:RCTReloadNotification object:nil userInfo:nil];
}

#pragma mark - TableView

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(__unused NSTableColumn *)tableColumn row:(NSInteger)row {

  NSLog(@"RCTRedBox: viewForTableColumn %ld", (long)row);

  if (row == 0) {
    NSTextField *cell = [tableView makeViewWithIdentifier:@"msg-cell" owner:self];
    return [self reuseCell:cell forErrorMessage:_lastErrorMessage];
  }
  NSTextField *cell = [tableView makeViewWithIdentifier:@"cell" owner:self];
  //NSUInteger index = indexPath.row;
  NSDictionary *stackFrame = _lastStackTrace[row];
  return [self reuseCell:cell forStackFrame:stackFrame];
}

- (NSTextField *)reuseCell:(NSTextField *)cell forErrorMessage:(NSString *)message
{
  if (!cell) {
    cell = [[NSTextField alloc] initWithFrame:self.frame];
    cell.accessibilityIdentifier = @"redbox-error";
    cell.textColor = [NSColor blackColor];
    cell.alignment = NSTextAlignmentCenter;
    cell.font = [NSFont boldSystemFontOfSize:16];
    cell.lineBreakMode = NSLineBreakByWordWrapping;
    cell.backgroundColor = [NSColor colorWithRed:0.8 green:0 blue:0 alpha:1];
    cell.editable = false;
  }
  [cell setStringValue:message];
  return cell;
}

- (NSTextField *)reuseCell:(NSTextField *)cell forStackFrame:(NSDictionary *)stackFrame
{
  if (!cell) {
    cell = [[NSTextField alloc] initWithFrame:self.frame];
    cell.textColor = [NSColor whiteColor];
    cell.font = [NSFont boldSystemFontOfSize:11];
    cell.lineBreakMode = NSLineBreakByWordWrapping;
    cell.backgroundColor = [NSColor clearColor];
    cell.editable = false;
  }
  NSString *methodName = stackFrame[@"methodName"];
  NSString *fileAndLine = [methodName stringByAppendingString: [stackFrame[@"file"] lastPathComponent]];
  NSString *details = fileAndLine ? [fileAndLine stringByAppendingFormat:@":%@", stackFrame[@"lineNumber"]] : nil;
  [cell setStringValue:details];
  return cell;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
  if (row == 0) {
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;

    NSDictionary *attributes = @{NSFontAttributeName: [NSFont boldSystemFontOfSize:16],
                                 NSParagraphStyleAttributeName: paragraphStyle};
    CGRect boundingRect = [_lastErrorMessage boundingRectWithSize:CGSizeMake(tableView.frame.size.width - 30, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:nil];
    return ceil(boundingRect.size.height) + 40;
  } else {
    return 50;
  }
}

- (NSInteger)numberOfRowsInTableView:(__unused NSTableView *)tableView
{
  NSInteger count = (_lastStackTrace ? _lastStackTrace.count : 1);
  return _lastStackTrace ? _lastStackTrace.count : 1;
}

-(NSInteger)numberOfColumns:(__unused NSTableView *)tableView {
  return 1;
}


//- (void)tableView:(NSTableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//{
//  if (indexPath.section == 1) {
//    NSUInteger row = indexPath.row;
//    NSDictionary *stackFrame = _lastStackTrace[row];
//    [self openStackFrameInEditor:stackFrame];
//  }
//  [tableView deselectRowAtIndexPath:indexPath animated:YES];
//}

#pragma mark - Key commands

- (void)keyDown:(NSEvent *)theEvent {
  [super keyDown:theEvent];
  if (theEvent.modifierFlags == (NSCommandKeyMask & NSDeviceIndependentModifierFlagsMask)
      && [theEvent.characters isEqualToString:@"r"]) {
    [self reload];
  }
  if (theEvent.keyCode == 53)
  {
    [self dismiss];
  }
}

- (BOOL)canBecomeFirstResponder
{
  return YES;
}

- (BOOL)canBecomeKeyWindow
{
  return YES;
}

@end

@interface RCTRedBox () <RCTInvalidating>
@end

@implementation RCTRedBox
{
  RCTRedBoxWindow *_window;
}

RCT_EXPORT_MODULE()

- (void)showError:(NSError *)error
{
  [self showErrorMessage:error.localizedDescription withDetails:error.localizedFailureReason];
}

- (void)showErrorMessage:(NSString *)message
{
  [self showErrorMessage:message withStack:nil showIfHidden:YES];
}

- (void)showErrorMessage:(NSString *)message withDetails:(NSString *)details
{
  NSString *combinedMessage = message;
  if (details) {
    combinedMessage = [NSString stringWithFormat:@"%@\n\n%@", message, details];
  }
  [self showErrorMessage:combinedMessage];
}

- (void)showErrorMessage:(NSString *)message withStack:(NSArray *)stack
{
  [self showErrorMessage:message withStack:stack showIfHidden:YES];
}

- (void)updateErrorMessage:(NSString *)message withStack:(NSArray *)stack
{
  [self showErrorMessage:message withStack:stack showIfHidden:NO];
}

- (void)showErrorMessage:(NSString *)message withStack:(NSArray *)stack showIfHidden:(BOOL)shouldShow
{
  dispatch_async(dispatch_get_main_queue(), ^{
    if (!_window) {
      _window = [[RCTRedBoxWindow alloc] initWithContentRect:[[NSApplication sharedApplication] mainWindow].frame];
    }
    [_window showErrorMessage:message withStack:stack showIfHidden:shouldShow];
  });
}

- (void)dismiss
{
  dispatch_async(dispatch_get_main_queue(), ^{
    [_window dismiss];
  });
}

- (void)invalidate
{
  [self dismiss];
}

@end

@implementation RCTBridge (RCTRedBox)

- (RCTRedBox *)redBox
{
  return self.modules[RCTBridgeModuleNameForClass([RCTRedBox class])];
}

@end

#else // Disabled

@implementation RCTRedBox

+ (NSString *)moduleName { return nil; }
- (void)showError:(NSError *)message {}
- (void)showErrorMessage:(NSString *)message {}
- (void)showErrorMessage:(NSString *)message withDetails:(NSString *)details {}
- (void)showErrorMessage:(NSString *)message withStack:(NSArray *)stack {}
- (void)updateErrorMessage:(NSString *)message withStack:(NSArray *)stack {}
- (void)showErrorMessage:(NSString *)message withStack:(NSArray *)stack showIfHidden:(BOOL)shouldShow {}
- (void)dismiss {}

@end

@implementation RCTBridge (RCTRedBox)

- (RCTRedBox *)redBox { return nil; }

@end

#endif
