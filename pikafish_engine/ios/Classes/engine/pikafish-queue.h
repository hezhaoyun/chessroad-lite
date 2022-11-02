//
//  pikafish-queue.h
//  Runner
//
//  Created by 贺照云 on 2020/3/10.
//

#ifndef pikafish_queue_h
#define pikafish_queue_h

class PikafishQueue {
    
    enum {
        MAX_COMMAND_COUNT = 128,
        COMMAND_LENGTH = 2048,
    };
    
    char commands[MAX_COMMAND_COUNT][COMMAND_LENGTH];
    int readIndex, writeIndex;
    
public:
    PikafishQueue();
    
    bool write(const char *command);
    bool read(char *dest);
};

#endif /* pikafish_queue_h */
