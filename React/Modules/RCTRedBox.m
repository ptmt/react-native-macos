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

#import "RCTView.h"
#import "RCTBridge.h"
#import "RCTConvert.h"
#import "RCTDefines.h"
#import "RCTErrorInfo.h"
#import "RCTEventDispatcher.h"
#import "RCTJSStackFrame.h"
// #import "RCTRedBoxExtraDataViewController.h"
#import "RCTUtils.h"

#if RCT_DEBUG

const CGFloat buttonHeight = 50;
const CGFloat buttonMargin = 10;

@interface ErrorNSTableView : NSTableView;
@end

@implementation ErrorNSTableView

- (BOOL)isFlipped
{
  return YES;
}

- (void)setFrameSize:(NSSize)newSize
{
  // Add padding to the bottom of the scroll view.
  newSize.height += buttonHeight + (buttonMargin * 2);
  [super setFrameSize:newSize];
}

@end

@class RCTRedBoxWindow;

@interface RCTRedBoxButton : NSButton
- (void)setBackgroundColor:(NSColor *)backgroundColor;
@end

@protocol RCTRedBoxWindowActionDelegate <NSObject>

- (void)redBoxWindow:(RCTRedBoxWindow *)redBoxWindow openStackFrameInEditor:(RCTJSStackFrame *)stackFrame;
- (void)reloadFromRedBoxWindow:(RCTRedBoxWindow *)redBoxWindow;
- (void)loadExtraDataViewController;

@end

@interface RCTRedBoxWindow : NSWindow <NSTableViewDelegate, NSTableViewDataSource>
@property (nonatomic, weak) id<RCTRedBoxWindowActionDelegate> actionDelegate;
@property (nonatomic, weak) RCTBridge *bridge;
@end

@implementation RCTRedBoxWindow
{
  NSTableView *_stackTraceTableView;
  NSString *_lastErrorMessage;
  NSArray<RCTJSStackFrame *> *_lastStackTrace;
  NSTextField * _temporaryHeader;
}

- (instancetype)initWithContentRect:(NSRect)frame
{
  self = [super initWithContentRect:frame
                          styleMask:NSWindowStyleMaskClosable | NSWindowStyleMaskTitled
                            backing:NSBackingStoreBuffered defer:NO];
  if (self) {
    NSColor *backgroundColor = [NSColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:1];
    RCTView *rootView = [[RCTView alloc] initWithFrame:frame];
    rootView.backgroundColor = backgroundColor;
    
    NSColor *buttonColor = [NSColor colorWithRed:0.8 green:0.15 blue:0.15 alpha:1];
    CGSize  buttonSize   = {(frame.size.width / 3) - (buttonMargin * 2), buttonHeight};
    CGPoint buttonOrigin = {buttonMargin, frame.size.height - buttonHeight - buttonMargin};
    NSDictionary *buttonAttributes = @{
      NSFontAttributeName: [NSFont systemFontOfSize:20],
      NSForegroundColorAttributeName: [NSColor whiteColor],
      NSBackgroundColorAttributeName: [NSColor clearColor],
    };
    
    RCTRedBoxButton *dismissButton = [RCTRedBoxButton new];
    dismissButton.frame = (CGRect){buttonOrigin, buttonSize};
    dismissButton.backgroundColor = buttonColor;
    dismissButton.accessibilityIdentifier = @"redbox-dismiss";
    dismissButton.attributedTitle = [[NSAttributedString alloc] initWithString:@"Dismiss (ESC)" attributes:buttonAttributes];
    dismissButton.target = self;
    dismissButton.action = @selector(dismiss);
    
    buttonOrigin.x += frame.size.width / 3;
    RCTRedBoxButton *reloadButton = [RCTRedBoxButton new];
    reloadButton.frame = (CGRect){buttonOrigin, buttonSize};
    reloadButton.backgroundColor = buttonColor;
    reloadButton.accessibilityIdentifier = @"redbox-reload";
    reloadButton.attributedTitle = [[NSAttributedString alloc] initWithString:@"Reload JS (\u2318R)" attributes:buttonAttributes];
    reloadButton.target = self;
    reloadButton.action = @selector(reload);
    
    buttonOrigin.x += frame.size.width / 3;
    RCTRedBoxButton *copyButton = [RCTRedBoxButton new];
    copyButton.frame = (CGRect){buttonOrigin, buttonSize};
    copyButton.backgroundColor = buttonColor;
    copyButton.accessibilityIdentifier = @"redbox-copy";
    copyButton.attributedTitle = [[NSAttributedString alloc] initWithString:@"Copy (\u2325\u2318C)" attributes:buttonAttributes];
    copyButton.target = self;
    copyButton.action = @selector(copyStack);
    
    _stackTraceTableView = [[ErrorNSTableView alloc] initWithFrame:CGRectZero];
    _stackTraceTableView.backgroundColor = [NSColor clearColor];
    _stackTraceTableView.headerView = nil;
    _stackTraceTableView.dataSource = self;
    _stackTraceTableView.delegate = self;
    
    NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:@"column"];
    [_stackTraceTableView addTableColumn:column];
    
    CGFloat scrollPadding = 20;
    frame = NSInsetRect(frame, scrollPadding, scrollPadding);
    frame.size.width += scrollPadding;
    frame.size.height += scrollPadding;
    
    NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:frame];
    scrollView.backgroundColor = [NSColor clearColor];
    scrollView.documentView = _stackTraceTableView;
    scrollView.contentView.backgroundColor = backgroundColor;
    
    [rootView addSubview:scrollView];
    [rootView addSubview:dismissButton];
    [rootView addSubview:reloadButton];
    [rootView addSubview:copyButton];
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

- (void)showErrorMessage:(NSString *)message withStack:(NSArray<RCTJSStackFrame *> *)stack isUpdate:(BOOL)isUpdate
{
  if (!self.isVisible || isUpdate) {
    _lastStackTrace = stack;
    _lastErrorMessage = [message substringToIndex:MIN((NSUInteger)10000, message.length)];

    [_stackTraceTableView reloadData];
    [_stackTraceTableView sizeToFit];
    
    NSApplication *app = [NSApplication sharedApplication];
    [app setActivationPolicy:NSApplicationActivationPolicyRegular];
    
    [self makeKeyAndOrderFront:nil];
    [self becomeFirstResponder];
  }
}

- (void)dismiss
{
  [self resignFirstResponder];
  [[[NSApplication sharedApplication] mainWindow] makeKeyWindow];
  [self orderOut:nil];
}

- (void)reload
{
    [_actionDelegate reloadFromRedBoxWindow:self];
}

- (void)showExtraDataViewController
{
    [_actionDelegate loadExtraDataViewController];
}

- (void)copyStack
{
  NSMutableString *fullStackTrace;

  if (_lastErrorMessage != nil) {
    fullStackTrace = [_lastErrorMessage mutableCopy];
    [fullStackTrace appendString:@"\n\n"];
  }
  else {
    fullStackTrace = [NSMutableString string];
  }

  for (RCTJSStackFrame *stackFrame in _lastStackTrace) {
    [fullStackTrace appendString:[NSString stringWithFormat:@"%@\n", stackFrame.methodName]];
    if (stackFrame.file) {
      [fullStackTrace appendFormat:@"    %@\n", [self formatFrameSource:stackFrame]];
    }
  }

  NSPasteboard *pb = [NSPasteboard generalPasteboard];
  [pb writeObjects:[NSArray arrayWithObject:fullStackTrace]];
}

- (NSString *)formatFrameSource:(RCTJSStackFrame *)stackFrame
{
  NSString *fileName = RCTNilIfNull(stackFrame.file) ? [stackFrame.file lastPathComponent] : @"<unknown file>";
  NSString *lineInfo = [NSString stringWithFormat:@"%@:%lld",
                        fileName,
                        (long long)stackFrame.lineNumber];

  if (stackFrame.column != 0) {
    lineInfo = [lineInfo stringByAppendingFormat:@":%lld", (long long)stackFrame.column];
  }
  return lineInfo;
}

#pragma mark - TableView

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(__unused NSTableColumn *)tableColumn row:(NSInteger)row
{
  if (row == 0) {
    NSTextField *cell = [tableView makeViewWithIdentifier:@"msg-cell" owner:self];
    return [self reuseCell:cell forErrorMessage:_lastErrorMessage];
  }
  NSTextField *cell = [tableView makeViewWithIdentifier:@"cell" owner:self];
  NSDictionary *stackFrame = [_lastStackTrace[row - 1] toDictionary];
  return [self reuseCell:cell forStackFrame:stackFrame];
}

- (NSTextField *)reuseCell:(NSTextField *)cell forErrorMessage:(NSString *)message
{
  if (!cell) {
    cell = [[NSTextField alloc] initWithFrame:self.contentView.frame];
    cell.accessibilityIdentifier = @"redbox-error-message";
    cell.textColor = [NSColor whiteColor];
    cell.font = [NSFont boldSystemFontOfSize:16];
    cell.lineBreakMode = NSLineBreakByWordWrapping;
    cell.backgroundColor = [NSColor clearColor];
    cell.bordered = false;
    cell.editable = false;
  }
  [cell setStringValue:message];
  return cell;
}

- (NSTextField *)reuseCell:(NSTextField *)cell forStackFrame:(NSDictionary *)stackFrame
{
  if (!cell) {
    cell = [[NSTextField alloc] initWithFrame:self.contentView.frame];
    cell.accessibilityIdentifier = @"redbox-stack-frame";
    cell.textColor = [NSColor whiteColor];
    cell.font = [NSFont fontWithName:@"Menlo-Regular" size:16];
    cell.lineBreakMode = NSLineBreakByCharWrapping;
    cell.backgroundColor = [NSColor clearColor];
    cell.bordered = false;
    cell.editable = false;
  }

  if (stackFrame[@"file"]) {
    [cell setStringValue:[NSString stringWithFormat:@"%@ @ %zd:%zd",
                        [stackFrame[@"file"] lastPathComponent],
                        [stackFrame[@"lineNumber"] integerValue],
                        [stackFrame[@"column"] integerValue]]];
  } else {
    [cell setStringValue:@""];
  }

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
  return 1 + _lastStackTrace.count;
}

-(NSInteger)numberOfColumns:(__unused NSTableView *)tableView
{
  return 1;
}

- (BOOL)tableView:(__unused NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
  return row > 0;
}

- (void)tableViewSelectionDidChange:(__unused NSNotification *)notification
{
  NSInteger row = _stackTraceTableView.selectedRow;
  [_actionDelegate redBoxWindow:self openStackFrameInEditor:_lastStackTrace[row - 1]];
  [_stackTraceTableView deselectRow:row];
}

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

  // Copy = Cmd-Option C since Cmd-C in the simulator copies the pasteboard from
  // the simulator to the desktop pasteboard.
  if (theEvent.modifierFlags == (NSCommandKeyMask & NSAlternateKeyMask)
      && [theEvent.characters isEqualToString:@"c"]) {
    [self copyStack];
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

@interface RCTRedBox () <RCTInvalidating, RCTRedBoxWindowActionDelegate>
@end

@implementation RCTRedBox
{
    RCTRedBoxWindow *_window;
    NSMutableArray<id<RCTErrorCustomizer>> *_errorCustomizers;
    //RCTRedBoxExtraDataViewController *_extraDataViewController;
}

@synthesize bridge = _bridge;

RCT_EXPORT_MODULE()

- (void)registerErrorCustomizer:(id<RCTErrorCustomizer>)errorCustomizer
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self->_errorCustomizers) {
            self->_errorCustomizers = [NSMutableArray array];
        }
        if (![self->_errorCustomizers containsObject:errorCustomizer]) {
            [self->_errorCustomizers addObject:errorCustomizer];
        }
    });
}

// WARNING: Should only be called from the main thread/dispatch queue.
- (RCTErrorInfo *)_customizeError:(RCTErrorInfo *)error
{
    RCTAssertMainQueue();
    if (!self->_errorCustomizers) {
        return error;
    }
    for (id<RCTErrorCustomizer> customizer in self->_errorCustomizers) {
        RCTErrorInfo *newInfo = [customizer customizeErrorInfo:error];
        if (newInfo) {
            error = newInfo;
        }
    }
    return error;
}

- (void)showError:(NSError *)error
{
    [self showErrorMessage:error.localizedDescription
               withDetails:error.localizedFailureReason
                     stack:error.userInfo[RCTJSStackTraceKey]];
}

- (void)showErrorMessage:(NSString *)message
{
    [self showErrorMessage:message withParsedStack:nil isUpdate:NO];
}

- (void)showErrorMessage:(NSString *)message withDetails:(NSString *)details
{
    [self showErrorMessage:message withDetails:details stack:nil];
}

- (void)showErrorMessage:(NSString *)message withDetails:(NSString *)details stack:(NSArray<RCTJSStackFrame *> *)stack {
    NSString *combinedMessage = message;
    if (details) {
        combinedMessage = [NSString stringWithFormat:@"%@\n\n%@", message, details];
    }
    [self showErrorMessage:combinedMessage withParsedStack:stack isUpdate:NO];
}

- (void)showErrorMessage:(NSString *)message withRawStack:(NSString *)rawStack
{
    NSArray<RCTJSStackFrame *> *stack = [RCTJSStackFrame stackFramesWithLines:rawStack];
    [self showErrorMessage:message withParsedStack:stack isUpdate:NO];
}

- (void)showErrorMessage:(NSString *)message withStack:(NSArray<NSDictionary *> *)stack
{
    [self showErrorMessage:message withParsedStack:[RCTJSStackFrame stackFramesWithDictionaries:stack] isUpdate:NO];
}

- (void)updateErrorMessage:(NSString *)message withStack:(NSArray<NSDictionary *> *)stack
{
    [self showErrorMessage:message withParsedStack:[RCTJSStackFrame stackFramesWithDictionaries:stack] isUpdate:YES];
}

- (void)showErrorMessage:(NSString *)message withParsedStack:(NSArray<RCTJSStackFrame *> *)stack
{
    [self showErrorMessage:message withParsedStack:stack isUpdate:NO];
}

- (void)updateErrorMessage:(NSString *)message withParsedStack:(NSArray<RCTJSStackFrame *> *)stack
{
    [self showErrorMessage:message withParsedStack:stack isUpdate:YES];
}

- (void)showErrorMessage:(NSString *)message withParsedStack:(NSArray<RCTJSStackFrame *> *)stack isUpdate:(BOOL)isUpdate
{
    dispatch_async(dispatch_get_main_queue(), ^{
        // if (self->_extraDataViewController == nil) {
        //     self->_extraDataViewController = [RCTRedBoxExtraDataViewController new];
        //     self->_extraDataViewController.actionDelegate = self;
        // }
        [self->_bridge.eventDispatcher sendDeviceEventWithName:@"collectRedBoxExtraData" body:nil];

        if (!self->_window) {
          NSSize screenSize = NSScreen.mainScreen.frame.size;
          NSRect contentRect = (CGRect){NSZeroPoint, {screenSize.width / 3, screenSize.height / 1.5}};

          self->_window = [[RCTRedBoxWindow alloc] initWithContentRect:contentRect];
          self->_window.actionDelegate = self;
          [self->_window center];
        }

        RCTErrorInfo *errorInfo = [[RCTErrorInfo alloc] initWithErrorMessage:message
                                                                       stack:stack];
        errorInfo = [self _customizeError:errorInfo];
        [self->_window showErrorMessage:errorInfo.errorMessage
                              withStack:errorInfo.stack
                               isUpdate:isUpdate];
    });
}

- (void)loadExtraDataViewController {
    dispatch_async(dispatch_get_main_queue(), ^{
        // Make sure the CMD+E shortcut doesn't call this twice
        NSLog(@"_extraDataViewController is not yet implemented");
      // if (self->_extraDataViewController != nil && ![self->_window.contentViewController presentedViewControllers]) {
      //     [self->_window.contentViewController presentViewControllerAsSheet:self->_extraDataViewController];
      //   }
    });
}

RCT_EXPORT_METHOD(setExtraData:(NSDictionary *)extraData forIdentifier:(__unused NSString *)identifier) {
    // [_extraDataViewController addExtraData:extraData forIdentifier:identifier];
    NSLog(@"_extraDataViewController is not yet implemented %@", extraData);
}

RCT_EXPORT_METHOD(dismiss)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->_window dismiss];
    });
}

- (void)invalidate
{
    [self dismiss];
}

- (void)redBoxWindow:(__unused RCTRedBoxWindow *)redBoxWindow openStackFrameInEditor:(RCTJSStackFrame *)stackFrame
{
    NSURL *const bundleURL = _overrideBundleURL ?: _bridge.bundleURL;
    if (![bundleURL.scheme hasPrefix:@"http"]) {
        RCTLogWarn(@"Cannot open stack frame in editor because you're not connected to the packager.");
        return;
    }

    NSData *stackFrameJSON = [RCTJSONStringify([stackFrame toDictionary], NULL) dataUsingEncoding:NSUTF8StringEncoding];
    NSString *postLength = [NSString stringWithFormat:@"%tu", stackFrameJSON.length];
    NSMutableURLRequest *request = [NSMutableURLRequest new];
    request.URL = [RCTConvert NSURL:@"http://localhost:8081/open-stack-frame"];
    request.HTTPMethod = @"POST";
    request.HTTPBody = stackFrameJSON;
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    [[[NSURLSession sharedSession] dataTaskWithRequest:request] resume];
}

- (void)reload
{
    // Window is not used and can be nil
    [self reloadFromRedBoxWindow:nil];
}

- (void)reloadFromRedBoxWindow:(__unused RCTRedBoxWindow *)redBoxWindow
{
    if (_overrideReloadAction) {
        _overrideReloadAction();
    } else {
        [_bridge reload];
    }
    [self dismiss];
}

@end

@interface RCTRedBoxButtonCell : NSButtonCell
@end

@implementation RCTRedBoxButton

+ (Class)cellClass {
  return [RCTRedBoxButtonCell class];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.bezelStyle = NSBezelStyleRecessed;
    }
    return self;
}

- (void)setBackgroundColor:(NSColor *)backgroundColor
{
  self.wantsLayer = true;
  self.layer.backgroundColor = backgroundColor.CGColor;
}

@end

@implementation RCTRedBoxButtonCell

- (NSRect)titleRectForBounds:(NSRect)rect
{
    NSRect titleFrame = [super titleRectForBounds:rect];
    NSSize titleSize = self.attributedTitle.size;
    titleFrame.origin.x = (rect.size.width - titleSize.width) / 2;
    titleFrame.origin.y = (rect.size.height - titleSize.height) / 2;
    return titleFrame;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(__unused NSView *)controlView
{
    NSRect titleRect = [self titleRectForBounds:cellFrame];
    [self.attributedTitle drawInRect:titleRect];
}

@end

@implementation RCTBridge (RCTRedBox)

- (RCTRedBox *)redBox
{
    return [self moduleForClass:[RCTRedBox class]];
}

@end

#else // Disabled

@implementation RCTRedBox

+ (NSString *)moduleName { return nil; }
- (void)registerErrorCustomizer:(id<RCTErrorCustomizer>)errorCustomizer {}
- (void)showError:(NSError *)message {}
- (void)showErrorMessage:(NSString *)message {}
- (void)showErrorMessage:(NSString *)message withDetails:(NSString *)details {}
- (void)showErrorMessage:(NSString *)message withRawStack:(NSString *)rawStack {}
- (void)showErrorMessage:(NSString *)message withStack:(NSArray<NSDictionary *> *)stack {}
- (void)updateErrorMessage:(NSString *)message withStack:(NSArray<NSDictionary *> *)stack {}
- (void)showErrorMessage:(NSString *)message withParsedStack:(NSArray<RCTJSStackFrame *> *)stack {}
- (void)updateErrorMessage:(NSString *)message withParsedStack:(NSArray<RCTJSStackFrame *> *)stack {}
- (void)showErrorMessage:(NSString *)message withStack:(NSArray<NSDictionary *> *)stack isUpdate:(BOOL)isUpdate {}
- (void)dismiss {}

@end

@implementation RCTBridge (RCTRedBox)

- (RCTRedBox *)redBox { return nil; }

@end

#endif
