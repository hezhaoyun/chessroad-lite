//
//  challenger-queue.cpp
//  Runner
//
//  Created by 贺照云 on 2020/3/10.
//

#include <string.h>
#include "challenger-queue.h"

#pragma warning (disable: 4996)

ChallengeQueue::ChallengeQueue() {
    
    for (int i = 0; i < MAX_COMMAND_COUNT; i++) {
        strcpy(commands[i], "");
    }

    writeIndex = 0;
    readIndex = -1;
}

bool ChallengeQueue::write(const char *command) {
    
    if (strlen(commands[writeIndex]) != 0) {
        return false;
    }

    strcpy(commands[writeIndex], command);

    if (readIndex == -1) {
        readIndex = writeIndex;
    }

    if (++writeIndex == MAX_COMMAND_COUNT) {
        writeIndex = 0;
    }
    
    return true;
}

bool ChallengeQueue::read(char *dest) {
    
    if (readIndex == -1) return false;

    strcpy(dest, commands[readIndex]);
    strcpy(commands[readIndex], "");

    if (++readIndex == MAX_COMMAND_COUNT) {
        readIndex = 0;
    }

    if (readIndex == writeIndex) {
        readIndex = -1;
    }

    return true;
}
