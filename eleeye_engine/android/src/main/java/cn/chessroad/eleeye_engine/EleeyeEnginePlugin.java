package cn.chessroad.eleeye_engine;

import java.lang.annotation.Native;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/** EleeyeEnginePlugin */
public class EleeyeEnginePlugin implements FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native
  /// Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine
  /// and unregister it
  /// when the Flutter Engine is detached from the Activity
  private MethodChannel channel;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "eleeye_engine");
    channel.setMethodCallHandler(this);
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {

    EleeyeEngineNative engine = new EleeyeEngineNative();

    if (call.method.equals("startup")) {
      result.success(engine.startup());
    } else if (call.method.equals("send")) {
      result.success(engine.send(call.arguments.toString()));
    } else if (call.method.equals("read")) {
      result.success(engine.read());
    } else if (call.method.equals("isReady")) {
      result.success(engine.isReady());
    } else if (call.method.equals("isThinking")) {
      result.success(engine.isThinking());
    } else if (call.method.equals("shutdown")) {
      result.success(engine.shutdown());
    } else {
      result.notImplemented();
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }
}
