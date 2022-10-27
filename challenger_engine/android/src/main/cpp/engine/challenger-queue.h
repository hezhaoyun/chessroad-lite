//
//  challenger-queue.h
//  Runner
//
//  Created by 贺照云 on 2020/3/10.
//

#ifndef challenger_queue_h
#define challenger_queue_h

class CommandQueue {
    
    enum {
        MAX_COMMAND_COUNT = 128,
        COMMAND_LENGTH = 2048,
    };
    
    char commands[MAX_COMMAND_COUNT][COMMAND_LENGTH];
    int readIndex, writeIndex;
    
public:
    CommandQueue();
    
    bool write(const char *command);
    bool read(char *dest);
};

#endif /* challenger_queue_h */
