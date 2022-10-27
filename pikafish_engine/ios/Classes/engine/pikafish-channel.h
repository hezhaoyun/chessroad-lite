//
//  pikafish-channel.h
//  Runner
//
//  Created by 贺照云 on 2020/3/10.
//

#ifndef pikafish_channel_h
#define pikafish_channel_h

void PrintLn(const char *sz, ...);

class CommandQueue;

class CommandChannel {

    CommandChannel();

public:
    static CommandChannel *getInstance();
    static void release();
    
    virtual ~CommandChannel();

    bool pushCommand(const char *cmd);
    bool popupCommand(char *buffer);
    bool pushResponse(const char *resp);
    bool popupResponse(char *buffer);

private:
    static CommandChannel *instance;

    CommandQueue *commandQueue;
    CommandQueue *responseQueue;
};

#endif /* pikafish_channel_h */
