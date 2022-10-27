package cn.chessroad.pikafish_engine;

public class PikafishEngineNative {
    
    static {
        System.loadLibrary("pikafish");
    }

    public native int startup();
    
    public native int send(String command);
    
    public native String read();
    
    public native boolean isReady();
    
    public native boolean isThinking();

    public native int shutdown();
}
