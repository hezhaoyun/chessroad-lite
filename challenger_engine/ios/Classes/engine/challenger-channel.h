//
//  challenger-channel.h
//  Runner
//
//  Created by 贺照云 on 2020/3/10.
//

#ifndef challenger_channel_h
#define challenger_channel_h

void challengerOut(const char *sz, ...);

class ChallengeQueue;

class ChallengeChannel {

    ChallengeChannel();

public:
    static ChallengeChannel *getInstance();
    static void release();
    
    virtual ~ChallengeChannel();

    bool pushCommand(const char *cmd);
    bool popupCommand(char *buffer);
    bool pushResponse(const char *resp);
    bool popupResponse(char *buffer);

private:
    static ChallengeChannel *instance;

    ChallengeQueue *commandQueue;
    ChallengeQueue *responseQueue;
};

#endif /* challenger_channel_h */
