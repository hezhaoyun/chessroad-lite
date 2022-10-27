#import "EleeyeEnginePlugin.h"


@implementation EleeyeEnginePlugin

- (id)init {
    
    self = [super init];
    
    if (self) {
        engine = [[EleeyeEngine alloc] init];
    }
    
    return self;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:@"eleeye_engine"
                                     binaryMessenger:[registrar messenger]];
    
    EleeyeEnginePlugin* instance = [[EleeyeEnginePlugin alloc] init];
    
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    
    __weak EleeyeEngine* weakEngine = engine;
    
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
