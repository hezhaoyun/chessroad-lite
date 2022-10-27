//
//  eleeye-channel.cpp
//  Runner
//
//  Created by 贺照云 on 2020/3/10.
//

#include <stdlib.h>
#include "eleeye-queue.h"
#include "eleeye-channel.h"

CommandChannel *CommandChannel::instance = NULL;

CommandChannel::CommandChannel() {
    commandQueue = new CommandQueue();
    responseQueue = new CommandQueue();
}

CommandChannel *CommandChannel::getInstance() {
    
    if (instance == NULL) {
        instance = new CommandChannel();
    }

    return instance;
}

void CommandChannel::release() {
    if (instance != NULL) {
        delete instance;
        instance = NULL;
    }
}

CommandChannel::~CommandChannel() {
    if (commandQueue != NULL) {
        delete commandQueue;
        commandQueue = NULL;
    }

    if (responseQueue != NULL) {
        delete responseQueue;
        responseQueue = NULL;
    }
}

bool CommandChannel::pushCommand(const char *cmd) {
    return commandQueue->write(cmd);
}

bool CommandChannel::popupCommand(char *buffer) {
    return commandQueue->read(buffer);
}

bool CommandChannel::pushResponse(const char *resp) {
    return responseQueue->write(resp);
}

bool CommandChannel::popupResponse(char *buffer) {
    return responseQueue->read(buffer);
}
