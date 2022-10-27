package cn.chessroad.challenger_engine;

public class ChallengerEngineNative {
    
    static {
        System.loadLibrary("challenger");
    }

    public native int startup();
    
    public native int send(String command);
    
    public native String read();
    
    public native boolean isReady();
    
    public native boolean isThinking();

    public native int shutdown();
}
