//
//  eleeye-channel.cpp
//  Runner
//
//  Created by 贺照云 on 2020/3/10.
//

#include <stdlib.h>
#include "eleeye-queue.h"
#include "eleeye-channel.h"

EleeyeChannel *EleeyeChannel::instance = NULL;

EleeyeChannel::EleeyeChannel() {
    commandQueue = new EleeyeQueue();
    responseQueue = new EleeyeQueue();
}

EleeyeChannel *EleeyeChannel::getInstance() {
    
    if (instance == NULL) {
        instance = new EleeyeChannel();
    }

    return instance;
}

void EleeyeChannel::release() {
    if (instance != NULL) {
        delete instance;
        instance = NULL;
    }
}

EleeyeChannel::~EleeyeChannel() {
    if (commandQueue != NULL) {
        delete commandQueue;
        commandQueue = NULL;
    }

    if (responseQueue != NULL) {
        delete responseQueue;
        responseQueue = NULL;
    }
}

bool EleeyeChannel::pushCommand(const char *cmd) {
    return commandQueue->write(cmd);
}

bool EleeyeChannel::popupCommand(char *buffer) {
    return commandQueue->read(buffer);
}

bool EleeyeChannel::pushResponse(const char *resp) {
    return responseQueue->write(resp);
}

bool EleeyeChannel::popupResponse(char *buffer) {
    return responseQueue->read(buffer);
}
