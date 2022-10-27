//
//  ChallengerEngine.h
//  Runner
//
//  Created by 贺照云 on 2022/9/1.
//  Copyright © 2022 The Chromium Authors. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>

#define State       int
#define Ready       0
#define Thinking    1

@interface ChallengerEngine : NSObject {
    NSOperationQueue *operationQueue;
}

@property(nonatomic) State state;

-(int) startup;

-(int) changeSearchDepth: (int) depth;

-(int) send: (NSString *) command;

-(NSString *) read;

-(int) shutdown;

-(BOOL) isReady;

-(BOOL) isThinking;

@end
