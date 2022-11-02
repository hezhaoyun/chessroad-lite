//
//  eleeye-channel.h
//  Runner
//
//  Created by 贺照云 on 2020/3/10.
//

#ifndef eleeye_channel_h
#define eleeye_channel_h

class EleeyeQueue;

class EleeyeChannel {

    EleeyeChannel();

public:
    static EleeyeChannel *getInstance();
    static void release();
    
    virtual ~EleeyeChannel();

    bool pushCommand(const char *cmd);
    bool popupCommand(char *buffer);
    bool pushResponse(const char *resp);
    bool popupResponse(char *buffer);

private:
    static EleeyeChannel *instance;

    EleeyeQueue *commandQueue;
    EleeyeQueue *responseQueue;
};

#endif /* eleeye_channel_h */
