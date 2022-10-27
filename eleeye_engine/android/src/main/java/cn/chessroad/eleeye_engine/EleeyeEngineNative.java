package cn.chessroad.eleeye_engine;

public class EleeyeEngineNative {
    
    static {
        System.loadLibrary("eleeye");
    }

    public native int startup();
    
    public native int send(String command);
    
    public native String read();
    
    public native boolean isReady();
    
    public native boolean isThinking();

    public native int shutdown();
}
