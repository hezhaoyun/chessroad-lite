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

void challengerOut(const char *sz, ...) {

    va_list args;
    va_start(args, sz);

    char buffer[1024] = {0};
    vsprintf(buffer, sz, args);

    va_end(args);

    ChallengeChannel *channel = ChallengeChannel::getInstance();
    while (!channel->pushResponse(buffer)) idle();
}

ChallengeChannel *ChallengeChannel::instance = NULL;

ChallengeChannel::ChallengeChannel() {
    commandQueue = new ChallengeQueue();
    responseQueue = new ChallengeQueue();
}

ChallengeChannel *ChallengeChannel::getInstance() {
    
    if (instance == NULL) {
        instance = new ChallengeChannel();
    }

    return instance;
}

void ChallengeChannel::release() {
    if (instance != NULL) {
        delete instance;
        instance = NULL;
    }
}

ChallengeChannel::~ChallengeChannel() {
    if (commandQueue != NULL) {
        delete commandQueue;
        commandQueue = NULL;
    }

    if (responseQueue != NULL) {
        delete responseQueue;
        responseQueue = NULL;
    }
}

bool ChallengeChannel::pushCommand(const char *cmd) {
    return commandQueue->write(cmd);
}

bool ChallengeChannel::popupCommand(char *buffer) {
    return commandQueue->read(buffer);
}

bool ChallengeChannel::pushResponse(const char *resp) {
    return responseQueue->write(resp);
}

bool ChallengeChannel::popupResponse(char *buffer) {
    return responseQueue->read(buffer);
}
