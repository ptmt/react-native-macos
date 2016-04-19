/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTDefines.h"

#if RCT_DEV

#import <dlfcn.h>

#import <mach/mach.h>

#import "RCTBridge.h"
#import "RCTDevMenu.h"
#import "RCTFPSGraph.h"
#import "RCTInvalidating.h"
#import "RCTJavaScriptExecutor.h"
#import "RCTJSCExecutor.h"
#import "RCTPerformanceLogger.h"
#import "RCTRootView.h"
#import "RCTUIManager.h"

static NSString *const RCTPerfMonitorKey = @"RCTPerfMonitorKey";
static NSString *const RCTPerfMonitorCellIdentifier = @"RCTPerfMonitorCellIdentifier";

static CGFloat const RCTPerfMonitorBarHeight = 50;
static CGFloat const RCTPerfMonitorExpandHeight = 250;

typedef BOOL (*RCTJSCSetOptionType)(const char *);

static BOOL RCTJSCSetOption(const char *option)
{
  static RCTJSCSetOptionType setOption;
  static dispatch_once_t onceToken;

  dispatch_once(&onceToken, ^{
    /**
     * JSC private C++ static method to toggle options at runtime
     *
     * JSC::Options::setOptions - JavaScriptCore/runtime/Options.h
     */
    setOption = dlsym(RTLD_DEFAULT, "_ZN3JSC7Options9setOptionEPKc");

    if (RCT_DEBUG && setOption == NULL) {
      RCTLogWarn(@"The symbol used to enable JSC runtime options is not available in this iOS version");
    }
  });

  if (setOption) {
    return setOption(option);
  } else {
    return NO;
  }
}

static vm_size_t RCTGetResidentMemorySize(void)
{
  struct task_basic_info info;
  mach_msg_type_number_t size = sizeof(info);
  kern_return_t kerr = task_info(mach_task_self(),
                                 TASK_BASIC_INFO,
                                 (task_info_t)&info,
                                 &size);
  if (kerr != KERN_SUCCESS) {
    return 0;
  }

  return info.resident_size;
}

@class RCTDevMenuItem;

@interface RCTPerfMonitor : NSObject <RCTBridgeModule, RCTInvalidating, NSTableViewDataSource, NSTableViewDelegate>

@property (nonatomic, strong, readonly) RCTDevMenuItem *devMenuItem;
@property (nonatomic, strong, readonly) NSView *container;
@property (nonatomic, strong, readonly) NSTextField *memory;
@property (nonatomic, strong, readonly) NSTextField *heap;
@property (nonatomic, strong, readonly) NSTextField *views;
@property (nonatomic, strong, readonly) NSTableView *metrics;
@property (nonatomic, strong, readonly) RCTFPSGraph *jsGraph;
@property (nonatomic, strong, readonly) RCTFPSGraph *uiGraph;
@property (nonatomic, strong, readonly) NSTextField *jsGraphLabel;
@property (nonatomic, strong, readonly) NSTextField *uiGraphLabel;

@end

@implementation RCTPerfMonitor {
  RCTDevMenuItem *_devMenuItem;
  NSView *_container;
  NSTextField *_memory;
  NSTextField *_heap;
  NSTextField *_views;
  NSTextField *_uiGraphLabel;
  NSTextField *_jsGraphLabel;
  NSTableView *_metrics;

  RCTFPSGraph *_uiGraph;
  RCTFPSGraph *_jsGraph;

//  CADisplayLink *_uiDisplayLink;
//  CADisplayLink *_jsDisplayLink;

  NSUInteger _heapSize;

  dispatch_queue_t _queue;
  dispatch_io_t _io;
  int _stderr;
  int _pipe[2];
  NSString *_remaining;

  CGRect _storedMonitorFrame;

  NSArray *_perfLoggerMarks;
}

@synthesize bridge = _bridge;

RCT_EXPORT_MODULE()

- (void)invalidate
{
  [self hide];
}

- (RCTDevMenuItem *)devMenuItem
{
  if (!_devMenuItem) {
    __weak __typeof__(self) weakSelf = self;
    _devMenuItem =
      [RCTDevMenuItem toggleItemWithKey:RCTPerfMonitorKey
                                  title:@"Show Perf Monitor"
                          selectedTitle:@"Hide Perf Monitor"
                                handler:
                                ^(BOOL selected) {
                                  //[_bridge.devMenu updateSetting:RCTPerfMonitorKey value:@(selected)];

                                  if (selected) {
                                   // [weakSelf show];
                                  } else {
                                    [weakSelf hide];
                                    //;
                                  }
                                }];
  }

  return _devMenuItem;
}

- (NSView *)container
{
  if (!_container) {
    _container = [[NSView alloc] initWithFrame:CGRectMake(10, 25, 180, RCTPerfMonitorBarHeight)];
    _container.layer.backgroundColor = [[NSColor whiteColor] CGColor];
    _container.layer.borderWidth = 2;
    _container.layer.borderColor = [NSColor lightGrayColor].CGColor;
//    [_container addGestureRecognizer:self.gestureRecognizer];
//    [_container addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self
//                                                                             action:@selector(tap)]];
  }

  return _container;
}

- (NSTextField *)memory
{
  if (!_memory) {
    _memory = [[NSTextField alloc] initWithFrame:CGRectMake(0, 0, 44, RCTPerfMonitorBarHeight)];
    _memory.font = [NSFont systemFontOfSize:12];
    _memory.alignment = NSTextAlignmentCenter;
  }

  return _memory;
}

- (NSTextField *)heap
{
  if (!_heap) {
    _heap = [[NSTextField alloc] initWithFrame:CGRectMake(44, 0, 44, RCTPerfMonitorBarHeight)];
    _heap.font = [NSFont systemFontOfSize:12];
    _heap.alignment = NSCenterTextAlignment;
  }

  return _heap;
}

- (NSTextField *)views
{
  if (!_views) {
    _views = [[NSTextField alloc] initWithFrame:CGRectMake(88, 0, 44, RCTPerfMonitorBarHeight)];
    _views.font = [NSFont systemFontOfSize:12];
    _views.alignment = NSTextAlignmentCenter;
  }

  return _views;
}

- (RCTFPSGraph *)uiGraph
{
  if (!_uiGraph) {
    _uiGraph = [[RCTFPSGraph alloc] initWithFrame:CGRectMake(134, 14, 40, 30)
                                            color:[NSColor lightGrayColor]];
  }
  return _uiGraph;
}

- (RCTFPSGraph *)jsGraph
{
  if (!_jsGraph) {
    _jsGraph = [[RCTFPSGraph alloc] initWithFrame:CGRectMake(178, 14, 40, 30)
                                            color:[NSColor lightGrayColor]];
  }
  return _jsGraph;
}

- (NSTextField *)uiGraphLabel
{
  if (!_uiGraphLabel) {
    _uiGraphLabel = [[NSTextField alloc] initWithFrame:CGRectMake(134, 3, 40, 10)];
    _uiGraphLabel.font = [NSFont systemFontOfSize:11];
    _uiGraphLabel.alignment = NSTextAlignmentCenter;
    _uiGraphLabel.stringValue = @"UI";
  }

  return _uiGraphLabel;
}

- (NSTextField *)jsGraphLabel
{
  if (!_jsGraphLabel) {
    _jsGraphLabel = [[NSTextField alloc] initWithFrame:CGRectMake(178, 3, 38, 10)];
    _jsGraphLabel.font = [NSFont systemFontOfSize:11];
    _jsGraphLabel.alignment = NSTextAlignmentCenter;
    _jsGraphLabel.stringValue = @"JS";
  }

  return _jsGraphLabel;
}

- (NSTableView *)metrics
{
  if (!_metrics) {
    _metrics = [[NSTableView alloc] initWithFrame:CGRectMake(
      0,
      RCTPerfMonitorBarHeight,
      self.container.frame.size.width,
      self.container.frame.size.height - RCTPerfMonitorBarHeight
    )];
    _metrics.dataSource = self;
    _metrics.delegate = self;
    _metrics.autoresizingMask = NSViewHeightSizable | NSViewWidthSizable;
    //[_metrics registerClass:[NSTableViewCell class] forCellReuseIdentifier:RCTPerfMonitorCellIdentifier];
  }

  return _metrics;
}

- (dispatch_queue_t)methodQueue
{
  return dispatch_get_main_queue();
}

- (void)setBridge:(RCTBridge *)bridge
{
  _bridge = bridge;

  [_bridge.devMenu addItem:self.devMenuItem];
}

- (void)show
{
  if (_container) {
    return;
  }

  [self.container addSubview:self.memory];
  [self.container addSubview:self.heap];
  [self.container addSubview:self.views];
  [self.container addSubview:self.uiGraph];
  [self.container addSubview:self.uiGraphLabel];

  [self redirectLogs];

  RCTJSCSetOption("logGC=1");

  [self updateStats];

//  NSWindow *window = [NSApplication sharedApplication].mainWindow;
//  [window.contentView addSubview:self.container];


//  _uiDisplayLink = [CADisplayLink displayLinkWithTarget:self
//                                               selector:@selector(threadUpdate:)];
//  [_uiDisplayLink addToRunLoop:[NSRunLoop mainRunLoop]
//                       forMode:NSRunLoopCommonModes];

  id<RCTJavaScriptExecutor> executor = [_bridge valueForKey:@"javaScriptExecutor"];
  if ([executor isKindOfClass:[RCTJSCExecutor class]]) {
    self.container.frame = (CGRect) {
      self.container.frame.origin, {
        self.container.frame.size.width + 44,
        self.container.frame.size.height
      }
    };
    [self.container addSubview:self.jsGraph];
    [self.container addSubview:self.jsGraphLabel];
    [executor executeBlockOnJavaScriptQueue:^{
//      _jsDisplayLink = [CADisplayLink displayLinkWithTarget:self
//                                                   selector:@selector(threadUpdate:)];
//      [_jsDisplayLink addToRunLoop:[NSRunLoop currentRunLoop]
//                           forMode:NSRunLoopCommonModes];
    }];
  }
}

- (void)hide
{
  if (!_container) {
    return;
  }

  [self.container removeFromSuperview];
  _container = nil;
  _jsGraph = nil;
  _uiGraph = nil;

  RCTJSCSetOption("logGC=0");

  [self stopLogs];

}

- (void)redirectLogs
{
  _stderr = dup(STDERR_FILENO);

  if (pipe(_pipe) != 0) {
    return;
  }

  dup2(_pipe[1], STDERR_FILENO);
  close(_pipe[1]);

  __weak __typeof__(self) weakSelf = self;
  _queue = dispatch_queue_create("com.facebook.react.RCTPerfMonitor", DISPATCH_QUEUE_SERIAL);
  _io = dispatch_io_create(
    DISPATCH_IO_STREAM,
    _pipe[0],
    _queue,
    ^(__unused int error) {});

  dispatch_io_set_low_water(_io, 20);

  dispatch_io_read(
    _io,
    0,
    SIZE_MAX,
    _queue,
    ^(__unused bool done, dispatch_data_t data, __unused int error) {
      if (!data) {
        return;
    }

      dispatch_data_apply(
        data,
        ^bool(
          __unused dispatch_data_t region,
          __unused size_t offset,
          const void *buffer,
          size_t size
        ) {
          write(_stderr, buffer, size);

          NSString *log = [[NSString alloc] initWithBytes:buffer
                                                   length:size
                                                 encoding:NSUTF8StringEncoding];
          [weakSelf parse:log];
          return true;
        });
    });
}

- (void)stopLogs
{
  dup2(_stderr, STDERR_FILENO);
  dispatch_io_close(_io, 0);
}

- (void)parse:(NSString *)log
{
  static NSRegularExpression *GCRegex;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    NSString *pattern = @"\\[GC: (Eden|Full)Collection, (?:Skipped copying|Did copy), ([\\d\\.]+) (\\wb), ([\\d.]+) (\\ws)\\]";
    GCRegex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                        options:0
                                                          error:nil];
  });

  if (_remaining) {
    log = [_remaining stringByAppendingString:log];
    _remaining = nil;
  }

  NSArray<NSString *> *lines = [log componentsSeparatedByString:@"\n"];
  if (lines.count == 1) { // no newlines
    _remaining = log;
    return;
  }

  for (NSString *line in lines) {
    NSTextCheckingResult *match = [GCRegex firstMatchInString:line options:0 range:NSMakeRange(0, line.length)];
    if (match) {
      NSString *heapSizeStr = [line substringWithRange:[match rangeAtIndex:2]];
      _heapSize = [heapSizeStr integerValue];
    }
  }
}

- (void)updateStats
{
  NSDictionary<NSNumber *, NSView *> *views = [_bridge.uiManager valueForKey:@"viewRegistry"];
  NSUInteger viewCount = views.count;
  NSUInteger visibleViewCount = 0;
  for (NSView *view in views.allValues) {
    if (view.window || view.superview.window) {
      visibleViewCount++;
    }
  }

  double mem = (double)RCTGetResidentMemorySize() / 1024 / 1024;
  self.memory.stringValue  =[NSString stringWithFormat:@"RAM\n%.2lf\nMB", mem];
  self.heap.stringValue = [NSString stringWithFormat:@"JSC\n%.2lf\nMB", (double)_heapSize / 1024];
  self.views.stringValue = [NSString stringWithFormat:@"Views\n%lu\n%lu", (unsigned long)visibleViewCount, (unsigned long)viewCount];

  __weak __typeof__(self) weakSelf = self;
  dispatch_after(
    dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
    dispatch_get_main_queue(),
    ^{
      __strong __typeof__(weakSelf) strongSelf = weakSelf;
      if (strongSelf && strongSelf->_container.superview) {
        [strongSelf updateStats];
      }
    });
}

- (void)tap
{
  if (CGRectIsEmpty(_storedMonitorFrame)) {
    _storedMonitorFrame = CGRectMake(0, 20, self.container.window.frame.size.width, RCTPerfMonitorExpandHeight);
    [self.container addSubview:self.metrics];
    [self loadPerformanceLoggerData];
  }

  //[NSView animateWithDuration:.25 animations:^{
    CGRect tmp = self.container.frame;
    self.container.frame = _storedMonitorFrame;
    _storedMonitorFrame = tmp;
  //}];
}

- (void)threadUpdate
{
//  RCTFPSGraph *graph = displayLink == _jsDisplayLink ? _jsGraph : _uiGraph;
//  [graph onTick:displayLink.timestamp];
}

- (void)loadPerformanceLoggerData
{
  NSMutableArray *data = [NSMutableArray new];
  NSArray<NSNumber *> *values = RCTPerformanceLoggerOutput();
  NSUInteger i = 0;
  for (NSString *label in RCTPerformanceLoggerLabels()) {
    long long value = values[i+1].longLongValue - values[i].longLongValue;
    NSString *unit = @"ms";
    if ([label hasSuffix:@"Size"]) {
      unit = @"b";
    } else if ([label hasSuffix:@"Count"]) {
      unit = @"";
    }
    [data addObject:[NSString stringWithFormat:@"%@: %lld%@", label, value, unit]];
    i += 2;
  }
  _perfLoggerMarks = [data copy];
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(__unused NSTableView *)tableView
{
  return 1;
}

- (NSInteger)tableView:(__unused NSTableView *)tableView
 numberOfRowsInSection:(__unused NSInteger)section
{
  return _perfLoggerMarks.count;
}

//- (NSTableViewCell *)tableView:(NSTableView *)tableView
//         cellForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//  NSTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:RCTPerfMonitorCellIdentifier
//                                                          forIndexPath:indexPath];
//
//  if (!cell) {
//    cell = [[NSTableViewCell alloc] initWithStyle:NSTableViewCellStyleDefault
//                                  reuseIdentifier:RCTPerfMonitorCellIdentifier];
//  }
//
//  cell.textLabel.text = _perfLoggerMarks[indexPath.row];
//  cell.textLabel.font = [NSFont systemFontOfSize:12];
//
//  return cell;
//}

#pragma mark - NSTableViewDelegate

- (CGFloat)tableView:(__unused NSTableView *)tableView
heightForRowAtIndexPath:(__unused NSIndexPath *)indexPath
{
  return 20;
}

@end

#endif
