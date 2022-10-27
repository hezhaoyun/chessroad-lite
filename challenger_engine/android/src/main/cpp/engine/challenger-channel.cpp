//
//  challenger-channel.cpp
//  Runner
//
//  Created by 贺照云 on 2020/3/10.
//

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>

#include "challenger-queue.h"
#include "challenger-channel.h"

#ifdef _WIN32
#include "windows.h"
static void idle() { Sleep(1); }
#else
#include "unistd.h"
static void idle() { usleep(1000); }
#endif

void PrintLn(const char *sz, ...) {

    va_list args;
    va_start(args, sz);

    char buffer[1024] = {0};
    vsprintf(buffer, sz, args);

    va_end(args);

    CommandChannel *channel = CommandChannel::getInstance();
    while (!channel->pushResponse(buffer)) idle();
}

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
