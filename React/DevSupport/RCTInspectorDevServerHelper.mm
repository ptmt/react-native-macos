#import "RCTInspectorDevServerHelper.h"

#if RCT_DEV

#import <jschelpers/JSCWrapper.h>
#import <AppKit/AppKit.h>
#import <React/RCTLog.h>

#import "RCTDefines.h"
#import "RCTInspectorPackagerConnection.h"

using namespace facebook::react;

static NSString *const kDebuggerMsgDisable = @"{ \"id\":1,\"method\":\"Debugger.disable\" }";

static NSString *getServerHost(NSURL *bundleURL, NSNumber *port)
{
  NSString *host = [bundleURL host];
  if (!host) {
    host = @"localhost";
  }

  // this is consistent with the Android implementation, where http:// is the
  // hardcoded implicit scheme for the debug server. Note, packagerURL
  // technically looks like it could handle schemes/protocols other than HTTP,
  // so rather than force HTTP, leave it be for now, in case someone is relying
  // on that ability when developing against iOS.
  return [NSString stringWithFormat:@"%@:%@", host, port];
}

static NSURL *getInspectorDeviceUrl(NSURL *bundleURL)
{
  NSNumber *inspectorProxyPort = @8082;
  NSString *escapedDeviceName = [[[NSHost currentHost] localizedName] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
  NSString *escapedAppName = [[[NSBundle mainBundle] bundleIdentifier] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
  return [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/inspector/device?name=%@&app=%@",
                                                        getServerHost(bundleURL, inspectorProxyPort),
                                                        escapedDeviceName,
                                                        escapedAppName]];
}

static NSURL *getAttachDeviceUrl(NSURL *bundleURL, NSString *title)
{
  NSNumber *metroBundlerPort = @8081;
  NSString *escapedDeviceName = [[[NSHost currentHost] localizedName] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
  NSString *escapedAppName = [[[NSBundle mainBundle] bundleIdentifier] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
  return [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/attach-debugger-nuclide?title=%@&device=%@&app=%@",
                               getServerHost(bundleURL, metroBundlerPort),
                               title,
                               escapedDeviceName,
                               escapedAppName]];
}

@implementation RCTInspectorDevServerHelper

RCT_NOT_IMPLEMENTED(- (instancetype)init)

static NSMutableDictionary<NSString *, RCTInspectorPackagerConnection *> *socketConnections = nil;

static void sendEventToAllConnections(NSString *event)
{
  for (NSString *socketId in socketConnections) {
    [socketConnections[socketId] sendEventToAllConnections:event];
  }
}

static void displayErrorAlert(NSViewController *view, NSString *message) {
  NSAlert *alert = [[NSAlert alloc] init];
  alert.messageText = message;
  [alert runModal];
}

+ (void)attachDebugger:(NSString *)owner
         withBundleURL:(NSURL *)bundleURL
              withView:(NSViewController *)view
{
  NSURL *url = getAttachDeviceUrl(bundleURL, owner);

  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
  [request setHTTPMethod:@"GET"];

  __weak NSViewController *viewCapture = view;
  [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:
    ^(NSData *_Nullable data,
      NSURLResponse *_Nullable response,
      NSError *_Nullable error) {
      NSViewController *viewCaptureStrong = viewCapture;
      if (error != nullptr && viewCaptureStrong != nullptr) {
        displayErrorAlert(viewCaptureStrong, @"The request to attach Nuclide couldn't reach Metro Bundler!");
      }
    }] resume];
}

+ (void)disableDebugger
{
  sendEventToAllConnections(kDebuggerMsgDisable);
}

+ (void)connectWithBundleURL:(NSURL *)bundleURL
{
  NSURL *inspectorURL = getInspectorDeviceUrl(bundleURL);

  // Note, using a static dictionary isn't really the greatest design, but
  // the packager connection does the same thing, so it's at least consistent.
  // This is a static map that holds different inspector clients per the inspectorURL
  if (socketConnections == nil) {
    socketConnections = [NSMutableDictionary new];
  }

  NSString *key = [inspectorURL absoluteString];
  RCTInspectorPackagerConnection *connection = socketConnections[key];
  if (!connection) {
    connection = [[RCTInspectorPackagerConnection alloc] initWithURL:inspectorURL];
    socketConnections[key] = connection;
    [connection connect];
  }
}

@end

#endif
