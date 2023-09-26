import 'dart:async';

import 'package:dsbridge/dsbridge.dart';

class JsApi extends JavaScriptNamespaceInterface {
  @override
  void register() {
    registerFunction(testSyn);
    registerFunction(testAsyn);
    registerFunction(testNoArgSyn);
    registerFunction(testNoArgAsyn);
    registerFunction(callProgress);
  }

  String testSyn(dynamic msg) {
    return "$msg［syn call］";
  }

  void testAsyn(dynamic msg, CompletionHandler handler) {
    handler.complete("$msg [ asyn call]");
  }

  String testNoArgSyn(dynamic arg) {
    return "testNoArgSyn called [ syn call]";
  }

  void testNoArgAsyn(dynamic arg, CompletionHandler handler) {
    handler.complete("testNoArgAsyn called [ asyn call]");
  }

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

  dynamic syn(dynamic args) {
    return args;
  }

  void asyn(dynamic args, CompletionHandler handler) {
    handler.complete(args);
  }
}
