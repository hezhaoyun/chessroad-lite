//
//  pikafish-channel.cpp
//  Runner
//
//  Created by 贺照云 on 2020/3/10.
//

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>

#include "pikafish-queue.h"
#include "pikafish-channel.h"

#ifdef _WIN32
#include "windows.h"
static void idle() { Sleep(1); }
#else
#include "unistd.h"
static void idle() { usleep(1000); }
#endif

void pikafishOut(const char *sz, ...) {

    va_list args;
    va_start(args, sz);

    char buffer[1024] = {0};
    vsnprintf(buffer, 1024, sz, args);

    va_end(args);

    PikafishChannel *channel = PikafishChannel::getInstance();
    while (!channel->pushResponse(buffer)) idle();
}

PikafishChannel *PikafishChannel::instance = NULL;

PikafishChannel::PikafishChannel() {
    commandQueue = new PikafishQueue();
    responseQueue = new PikafishQueue();
}

PikafishChannel *PikafishChannel::getInstance() {
    
    if (instance == NULL) {
        instance = new PikafishChannel();
    }

    return instance;
}

void PikafishChannel::release() {
    if (instance != NULL) {
        delete instance;
        instance = NULL;
    }
}

PikafishChannel::~PikafishChannel() {
    if (commandQueue != NULL) {
        delete commandQueue;
        commandQueue = NULL;
    }

    if (responseQueue != NULL) {
        delete responseQueue;
        responseQueue = NULL;
    }
}

bool PikafishChannel::pushCommand(const char *cmd) {
    return commandQueue->write(cmd);
}

bool PikafishChannel::popupCommand(char *buffer) {
    return commandQueue->read(buffer);
}

bool PikafishChannel::pushResponse(const char *resp) {
    return responseQueue->write(resp);
}

bool PikafishChannel::popupResponse(char *buffer) {
    return responseQueue->read(buffer);
}
