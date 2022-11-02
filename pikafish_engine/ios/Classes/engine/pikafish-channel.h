//
//  pikafish-channel.h
//  Runner
//
//  Created by 贺照云 on 2020/3/10.
//

#ifndef pikafish_channel_h
#define pikafish_channel_h

void pikafishOut(const char *sz, ...);

class PikafishQueue;

class PikafishChannel {

    PikafishChannel();

public:
    static PikafishChannel *getInstance();
    static void release();
    
    virtual ~PikafishChannel();

    bool pushCommand(const char *cmd);
    bool popupCommand(char *buffer);
    bool pushResponse(const char *resp);
    bool popupResponse(char *buffer);

private:
    static PikafishChannel *instance;

    PikafishQueue *commandQueue;
    PikafishQueue *responseQueue;
};

#endif /* pikafish_channel_h */
