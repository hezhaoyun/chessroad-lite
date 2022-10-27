#import "ChallengerEnginePlugin.h"

@implementation ChallengerEnginePlugin

- (id)init {
    
    self = [super init];
    
    if (self) {
        engine = [[ChallengerEngine alloc] init];
    }
    
    return self;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"challenger_engine"
            binaryMessenger:[registrar messenger]];
  ChallengerEnginePlugin* instance = [[ChallengerEnginePlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {

    __weak ChallengerEngine* weakEngine = engine;
    
    if ([@"startup" isEqualToString:call.method]) {
        result(@([weakEngine startup]));
    }
    else if ([@"changeSearchDepth" isEqualToString:call.method]) {
        result(@([weakEngine changeSearchDepth: (int) [call.arguments integerValue]]));
    }
    else if ([@"send" isEqualToString:call.method]) {
        result(@([weakEngine send: call.arguments]));
    }
    else if ([@"read" isEqualToString:call.method]) {
        result([weakEngine read]);
    }
    else if ([@"shutdown" isEqualToString:call.method]) {
        result(@([weakEngine shutdown]));
    }
    else if ([@"isReady" isEqualToString:call.method]) {
        result(@([weakEngine isReady]));
    }
    else if ([@"isThinking" isEqualToString:call.method]) {
        result(@([weakEngine isThinking]));
    }
    else {
        result(FlutterMethodNotImplemented);
    }
}

@end
