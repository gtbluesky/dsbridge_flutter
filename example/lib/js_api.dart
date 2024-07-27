import 'dart:async';

import 'package:dsbridge_flutter/dsbridge_flutter.dart';

class JsApi extends JavaScriptNamespaceInterface {
  @override
  void register() {
    registerFunction(testSyn, functionName: 'testSyn');
    registerFunction(testAsyn);
    registerFunction(testNoArgSyn);
    registerFunction(testNoArgAsyn);
    registerFunction(callProgress);
  }

  String testSyn(dynamic msg) {
    print('msg=$msg');
    return "$msg［syn call］";
  }

  @pragma('vm:entry-point')
  void testAsyn(dynamic msg, CompletionHandler handler) {
    handler.complete("$msg [ asyn call]");
  }

  @pragma('vm:entry-point')
  String testNoArgSyn(dynamic arg) {
    return "testNoArgSyn called [ syn call]";
  }

  @pragma('vm:entry-point')
  void testNoArgAsyn(dynamic arg, CompletionHandler handler) {
    handler.complete("testNoArgAsyn called [ asyn call]");
  }

  @pragma('vm:entry-point')
  void callProgress(dynamic args, CompletionHandler handler) {
    var i = 10;
    final timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (i == 0) {
        timer.cancel();
        handler.complete(0);
      } else {
        handler.setProgressData(i--);
      }
    });
  }
}

class JsEchoApi extends JavaScriptNamespaceInterface {
  @override
  void register() {
    registerFunction(syn);
    registerFunction(asyn);
  }

  @pragma('vm:entry-point')
  dynamic syn(dynamic args) {
    return args;
  }

  @pragma('vm:entry-point')
  void asyn(dynamic args, CompletionHandler handler) {
    handler.complete(args);
  }
}
