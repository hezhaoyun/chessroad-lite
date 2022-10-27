#include <jni.h>
#include <string>
#include <pthread.h>
#include <unistd.h>

#include "engine/challenger.h"
#include "engine/challenger-channel.h"

#define State       int
#define Ready       0
#define Thinking    1

extern "C" {

    State state = Ready;
    pthread_t thread_id = 0;

    JNIEXPORT jint JNICALL
    Java_cn_chessroad_challenger_1engine_ChallengerEngineNative_send(JNIEnv *env, jobject, jstring command);

    JNIEXPORT jint JNICALL
    Java_cn_chessroad_challenger_1engine_ChallengerEngineNative_shutdown(JNIEnv *, jobject);

    void *engineThread(void *) {

        printf("Engine Think Thread enter.\n");

        engineMain();

        printf("Engine Think Thread exit.\n");

        return nullptr;
    }

    JNIEXPORT jint JNICALL
    Java_cn_chessroad_challenger_1engine_ChallengerEngineNative_startup(JNIEnv *env, jobject obj) {

        printf("<<< %s\n", "#####11111");

        if (thread_id) {
            Java_cn_chessroad_challenger_1engine_ChallengerEngineNative_shutdown(env, obj);
            pthread_join(thread_id, nullptr);
        }

        printf("<<< %s\n", "#####22222");

        // getInstance() 有并发问题，这里首先主动建立实例，避免后续创建重复
        CommandChannel::getInstance();

        usleep(10);

        printf("<<< %s\n", "#####33333");

        pthread_create(&thread_id, nullptr, engineThread, nullptr);

        printf("<<< %s\n", "#####44444");

        Java_cn_chessroad_challenger_1engine_ChallengerEngineNative_send(env, obj, env->NewStringUTF("ucci"));

        printf("<<< %s\n", "#####55555");

        return 0;
    }

    JNIEXPORT jint JNICALL
    Java_cn_chessroad_challenger_1engine_ChallengerEngineNative_changeSearchDepth(JNIEnv *, jobject, jint depth) {

        if (depth > 0 && depth <= 64) {
            SearchDepth = depth;
            return 0;
        }

        return -1;
    }

    JNIEXPORT jint JNICALL
    Java_cn_chessroad_challenger_1engine_ChallengerEngineNative_send(JNIEnv *env, jobject, jstring command) {

        const char *pCommand = env->GetStringUTFChars(command, JNI_FALSE);

        if (pCommand[0] == 'g' && pCommand[1] == 'o') state = Thinking;

        CommandChannel *channel = CommandChannel::getInstance();

        bool success = channel->pushCommand(pCommand);
        if (success) printf(">>> %s\n", pCommand);

        env->ReleaseStringUTFChars(command, pCommand);

        return success ? 0 : -1;
    }

    JNIEXPORT jstring JNICALL
    Java_cn_chessroad_challenger_1engine_ChallengerEngineNative_read(JNIEnv *env, jobject) {

        char line[4096] = {0};

        CommandChannel *channel = CommandChannel::getInstance();
        bool got_response = channel->popupResponse(line);

        if (!got_response) return nullptr;

        printf("<<< %s\n", line);

        if (strstr(line, "readyok") ||
            strstr(line, "ucciok") ||
            strstr(line, "bestmove") ||
            strstr(line, "nobestmove")) {

            state = Ready;
        }

        return env->NewStringUTF(line);
    }

    JNIEXPORT jint JNICALL
    Java_cn_chessroad_challenger_1engine_ChallengerEngineNative_shutdown(JNIEnv *env, jobject obj) {

        Java_cn_chessroad_challenger_1engine_ChallengerEngineNative_send(env, obj, env->NewStringUTF("quit"));

        pthread_join(thread_id, nullptr);

        thread_id = 0;

        return 0;
    }

    JNIEXPORT jboolean JNICALL
    Java_cn_chessroad_challenger_1engine_ChallengerEngineNative_isReady(JNIEnv *, jobject) {

        return static_cast<jboolean>(state == Ready);
    }

    JNIEXPORT jboolean JNICALL
    Java_cn_chessroad_challenger_1engine_ChallengerEngineNative_isThinking(JNIEnv *, jobject) {

        return static_cast<jboolean>(state == Thinking);
    }

}