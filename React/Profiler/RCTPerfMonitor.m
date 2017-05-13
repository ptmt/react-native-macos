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
#import "RCTDevSettings.h"
#import "RCTFPSGraph.h"
#import "RCTInvalidating.h"
#import "RCTJavaScriptExecutor.h"
#import "RCTPerformanceLogger.h"
#import "RCTRootView.h"
#import "RCTUIManager.h"
#import "RCTBridge+Private.h"
#import "RCTUtils.h"

#if __has_include("RCTDevMenu.h")
#import "RCTDevMenu.h"
#endif

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

@interface RCTPerfMonitor : NSObject <RCTBridgeModule, RCTInvalidating, UITableViewDataSource, UITableViewDelegate>

#if __has_include("RCTDevMenu.h")
@property (nonatomic, strong, readonly) RCTDevMenuItem *devMenuItem;
#endif
@property (nonatomic, strong, readonly) UIPanGestureRecognizer *gestureRecognizer;
@property (nonatomic, strong, readonly) UIView *container;
@property (nonatomic, strong, readonly) UILabel *memory;
@property (nonatomic, strong, readonly) UILabel *heap;
@property (nonatomic, strong, readonly) UILabel *views;
@property (nonatomic, strong, readonly) UITableView *metrics;
@property (nonatomic, strong, readonly) RCTFPSGraph *jsGraph;
@property (nonatomic, strong, readonly) RCTFPSGraph *uiGraph;
@property (nonatomic, strong, readonly) NSTextField *jsGraphLabel;
@property (nonatomic, strong, readonly) NSTextField *uiGraphLabel;

@end

@implementation RCTPerfMonitor {
#if __has_include("RCTDevMenu.h")
  RCTDevMenuItem *_devMenuItem;
  NSWindow *_window;
  NSView *_container;
  NSTextField *_memory;
  NSTextField *_heap;
  NSTextField *_views;
  NSTextField *_layers;
  NSTextField *_uiGraphLabel;
  NSTextField *_jsGraphLabel;
  NSTableView *_metrics;

  RCTFPSGraph *_uiGraph;
  RCTFPSGraph *_jsGraph;

  NSTimer *_uiTimer;
  NSTimer *_jsTimer;

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

- (instancetype)init
{
  // We're only overriding this to ensure the module gets created at startup
  // TODO (t11106126): Remove once we have more declarative control over module setup.
  return [super init];
}

- (dispatch_queue_t)methodQueue
{
  return dispatch_get_main_queue();
}

- (void)setBridge:(RCTBridge *)bridge
{
  _bridge = bridge;

#if __has_include("RCTDevMenu.h")
  [_bridge.devMenu addItem:self.devMenuItem];
#endif
}

- (void)invalidate
{
  [self hide];
}

#if __has_include("RCTDevMenu.h")
- (RCTDevMenuItem *)devMenuItem
{
  if (!_devMenuItem) {
    __weak __typeof__(self) weakSelf = self;
    __weak RCTDevSettings *devSettings = self.bridge.devSettings;
    _devMenuItem =
    [RCTDevMenuItem buttonItemWithTitleBlock:^NSString *{
      return (devSettings.isPerfMonitorShown) ?
        @"Hide Perf Monitor" :
        @"Show Perf Monitor";
    } handler:^{
      if (devSettings.isPerfMonitorShown) {
        [weakSelf hide];
        devSettings.isPerfMonitorShown = NO;
      } else {
        [weakSelf show];
        devSettings.isPerfMonitorShown = YES;
      }
    }];
  }

  return _devMenuItem;
}
#endif

- (NSView *)container
{
  if (!_container) {
    _container = [[NSView alloc] initWithFrame:CGRectMake(10, 50, 280, RCTPerfMonitorBarHeight)];
    _container.layer.backgroundColor = [[NSColor whiteColor] CGColor];
    _container.layer.borderWidth = 1;
    _container.layer.borderColor = [NSColor lightGrayColor].CGColor;
  }

  return _container;
}

- (NSTextField *)memory
{
  if (!_memory) {
    _memory = [[NSTextField alloc] initWithFrame:CGRectMake(0, 0, 44, RCTPerfMonitorBarHeight)];
    _memory.font = [NSFont systemFontOfSize:10];
    _memory.alignment = NSTextAlignmentCenter;
    _memory.editable = NO;
    _memory.drawsBackground = NO;
    _memory.bezeled = NO;
  }

  return _memory;
}

- (NSTextField *)heap
{
  if (!_heap) {
    _heap = [[NSTextField alloc] initWithFrame:CGRectMake(44, 0, 44, RCTPerfMonitorBarHeight)];
    _heap.font = [NSFont systemFontOfSize:10];
    _heap.alignment = NSCenterTextAlignment;
    _heap.editable = NO;
    _heap.drawsBackground = NO;
    _heap.bezeled = NO;
  }

  return _heap;
}

- (NSTextField *)views
{
  if (!_views) {
    _views = [[NSTextField alloc] initWithFrame:CGRectMake(88, 0, 44, RCTPerfMonitorBarHeight)];
    _views.font = [NSFont systemFontOfSize:10];
    _views.alignment = NSTextAlignmentCenter;
    _views.editable = NO;
    _views.drawsBackground = NO;
    _views.bezeled = NO;
  }

  return _views;
}

- (NSTextField *)layers
{
  if (!_layers) {
    _layers = [[NSTextField alloc] initWithFrame:CGRectMake(132, 0, 44, RCTPerfMonitorBarHeight)];
    _layers.font = [NSFont systemFontOfSize:10];
    _layers.alignment = NSTextAlignmentCenter;
    _layers.editable = NO;
    _layers.drawsBackground = NO;
    _layers.bezeled = NO;
  }
  return _layers;
}

- (RCTFPSGraph *)uiGraph
{
  if (!_uiGraph) {
    _uiGraph = [[RCTFPSGraph alloc] initWithFrame:CGRectMake(174, self.container.frame.size.height - 45, 40, 30)
                                            color:[NSColor lightGrayColor]];
  }
  return _uiGraph;
}

- (RCTFPSGraph *)jsGraph
{
  if (!_jsGraph) {
    _jsGraph = [[RCTFPSGraph alloc] initWithFrame:CGRectMake(218, self.container.frame.size.height - 75, 40, 30)
                                            color:[NSColor lightGrayColor]];
  }
  return _jsGraph;
}

- (NSTextField *)uiGraphLabel
{
  if (!_uiGraphLabel) {
    _uiGraphLabel = [[NSTextField alloc] initWithFrame:CGRectMake(174, self.container.frame.size.height - 10, 40, 10)];
    _uiGraphLabel.font = [NSFont systemFontOfSize:10];
    _uiGraphLabel.alignment = NSTextAlignmentCenter;
    _uiGraphLabel.stringValue = @"UI";
    _uiGraphLabel.editable = NO;
    _uiGraphLabel.bezeled = NO;
    _uiGraphLabel.drawsBackground = NO;
  }

  return _uiGraphLabel;
}

- (NSTextField *)jsGraphLabel
{
  if (!_jsGraphLabel) {
    _jsGraphLabel = [[NSTextField alloc] initWithFrame:CGRectMake(218, self.container.frame.size.height - 40, 38, 10)];
    _jsGraphLabel.font = [NSFont systemFontOfSize:10];
    _jsGraphLabel.alignment = NSTextAlignmentCenter;
    _jsGraphLabel.stringValue = @"JS";
    _jsGraphLabel.editable = NO;
    _jsGraphLabel.bezeled = NO;
    _jsGraphLabel.drawsBackground = NO;
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

- (void)show
{
  if (_container) {
    return;
  }

  [self.container addSubview:self.memory];
  [self.container addSubview:self.heap];
  [self.container addSubview:self.views];
  [self.container addSubview:self.layers];
  [self.container addSubview:self.uiGraph];
  [self.container addSubview:self.uiGraphLabel];

  [self redirectLogs];

  RCTJSCSetOption("logGC=1");

  [self updateStats];

  UIWindow *window = RCTSharedApplication().delegate.window;
  [window addSubview:self.container];

  NSRect frame = NSMakeRect(100, 100, self.container.frame.size.width, self.container.frame.size.height + 30);

  _window = [[NSWindow alloc] initWithContentRect:frame
                                                 styleMask:NSTitledWindowMask |  NSClosableWindowMask | NSFullSizeContentViewWindowMask
                                                   backing:NSBackingStoreBuffered
                                                     defer:NO];
  NSWindowController *windowController = [[NSWindowController alloc] initWithWindow:_window];
  [_window setContentView:self.container];
  [_window setTitle:@"Perf Monitor"];
  [_window setHidesOnDeactivate:NO];
  [_window setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameVibrantLight ]];
  [windowController showWindow:_window];


  _uiTimer = [NSTimer
              timerWithTimeInterval:RCT_TIME_PER_FRAME
              target:self
              selector:@selector(threadUpdate:)
              userInfo:nil
              repeats:YES];
  [[NSRunLoop mainRunLoop] addTimer:_uiTimer forMode:NSRunLoopCommonModes];

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
      _jsTimer = [NSTimer
                  timerWithTimeInterval:RCT_TIME_PER_FRAME
                  target:self
                  selector:@selector(threadUpdate:)
                  userInfo:nil
                  repeats:YES];
      [[NSRunLoop mainRunLoop] addTimer:_jsTimer forMode:NSRunLoopCommonModes];
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
  [_window close];
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
          write(self->_stderr, buffer, size);

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
    NSString *pattern = @"\\[GC: [\\d\\.]+ \\wb => (Eden|Full)Collection, (?:Skipped copying|Did copy), ([\\d\\.]+) \\wb, [\\d.]+ \\ws\\]";
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
  NSUInteger layerBackedCount = 0;
  NSUInteger layersCount = 0;
  for (NSView *view in views.allValues) {
    if (view.window || view.superview.window) {
      visibleViewCount++;
    }
    if (view.wantsLayer) {
      layerBackedCount++;
    }
    if (view.layer) {
      layersCount++;
    }
  }

  double mem = (double)RCTGetResidentMemorySize() / 1024 / 1024;
  self.memory.stringValue  =[NSString stringWithFormat:@"RAM\n%.2lf\nMB", mem];
  self.heap.stringValue = [NSString stringWithFormat:@"JSC\n%.2lf\nMB", (double)_heapSize / 1024];
  self.views.stringValue = [NSString stringWithFormat:@"Views\n%lu\n%lu", (unsigned long)visibleViewCount, (unsigned long)viewCount];
  self.layers.stringValue = [NSString stringWithFormat:@"Layers\n%lu\n%lu", (unsigned long)layerBackedCount, (unsigned long)layersCount];

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
  [self loadPerformanceLoggerData];
  if (CGRectIsEmpty(_storedMonitorFrame)) {
    _storedMonitorFrame = CGRectMake(0, 20, self.container.window.frame.size.width, RCTPerfMonitorExpandHeight);
    [self.container addSubview:self.metrics];
  } else {
    [_metrics reloadData];
  }

  // [NSView animateWithDuration:.25 animations:^{
    CGRect tmp = self.container.frame;
    self.container.frame = self->_storedMonitorFrame;
    self->_storedMonitorFrame = tmp;
  // }];
}

- (void)threadUpdate:(id)sender
{
  RCTFPSGraph *graph = sender == _jsTimer ? _jsGraph : _uiGraph;
  [graph onTick:CACurrentMediaTime()];
}

- (void)loadPerformanceLoggerData
{
  NSUInteger i = 0;
  NSMutableArray<NSString *> *data = [NSMutableArray new];
  RCTPerformanceLogger *performanceLogger = [_bridge performanceLogger];
  NSArray<NSNumber *> *values = [performanceLogger valuesForTags];
  for (NSString *label in [performanceLogger labelsForTags]) {
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
