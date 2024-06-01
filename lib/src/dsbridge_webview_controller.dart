import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import 'dsbridge_extension.dart';
import 'dsbridge_js_namespace_interfaces.dart';
import 'dsbridge_result.dart';

class DWebViewController extends WebViewController {
  static const String _jsChannel = '_dswk';
  static const String _prefix = '_dsbridge=';
  // ignore: unused_field
  bool _alertBoxBlock = true;
  final _javaScriptNamespaceInterfaces =
      <String, JavaScriptNamespaceInterface>{};
  BuildContext? _context;
  int _callID = 0;
  List<_CallInfo>? _callInfoList;
  final _handlerMap = <int, OnReturnValue>{};

  /// a listener for javascript closing the current page.
  void Function()? javaScriptCloseWindowListener;

  /// a callback for notifying the host application that the web page
  /// wants to display a JavaScript alert() dialog.
  Future<void> Function(String message)? javaScriptAlertCallback;

  /// a callback for notifying the host application that the web page
  /// wants to display a JavaScript confirm() dialog.
  Future<bool> Function(String message)? javaScriptConfirmCallback;

  /// a callback for notifying the host application that the web page
  /// wants to display a JavaScript prompt() dialog.
  Future<String> Function(String message, String? defaultText)?
      javaScriptPromptCallback;

  DWebViewController({
    void Function(WebViewPermissionRequest request)? onPermissionRequest,
  }) : this.fromPlatformCreationParams(
          const PlatformWebViewControllerCreationParams(),
          onPermissionRequest: onPermissionRequest,
        );

  DWebViewController.fromPlatformCreationParams(
    PlatformWebViewControllerCreationParams params, {
    void Function(WebViewPermissionRequest request)? onPermissionRequest,
  }) : this.fromPlatform(
          PlatformWebViewController(params),
          onPermissionRequest: onPermissionRequest,
        );

  DWebViewController.fromPlatform(
    PlatformWebViewController platform, {
    void Function(WebViewPermissionRequest request)? onPermissionRequest,
  }) : super.fromPlatform(platform, onPermissionRequest: onPermissionRequest) {
    setJavaScriptMode(JavaScriptMode.unrestricted);
    _addInternalJavaScriptObject();
    addJavaScriptChannel(_jsChannel, onMessageReceived: (message) {});
    _setJavaScriptAlertCallback();
    _setJavaScriptConfirmCallback();
    _setJavaScriptPromptCallback();
    platform.setOnJavaScriptAlertDialog((request) async {
      // if (!_alertBoxBlock) {
      //   return;
      // }
      javaScriptAlertCallback?.call(request.message);
    });

    platform.setOnJavaScriptConfirmDialog((request) async {
      // if (!_alertBoxBlock) {
      //   return true;
      // }
      return javaScriptConfirmCallback?.call(request.message) ??
          Future.value(false);
    });

    platform.setOnJavaScriptTextInputDialog((request) async {
      if (request.message.startsWith(_prefix)) {
        return _call(
            request.message.substring(_prefix.length), request.defaultText);
      }
      // if (!_alertBoxBlock) {
      //   return '';
      // }
      return javaScriptPromptCallback?.call(
              request.message, request.defaultText) ??
          Future.value('');
    });
  }

  String _call(String methodName, String? argStr) {
    final ret = <String, dynamic>{'code': -1};
    final list = _parseNamespace(methodName.trim());
    final namespace = list[0];
    methodName = list[1];
    final jsb = _javaScriptNamespaceInterfaces[namespace];
    if (jsb == null) {
      _printDebugInfo(
          "Js bridge called, but can't find a corresponded JavascriptInterface object, please check your code!");
      return json.encode(ret);
    }
    dynamic arg;
    String? callback;
    if (argStr != null && argStr.isNotEmpty) {
      try {
        Map<String, dynamic> args = json.decode(argStr);
        if (args.containsKey('_dscbstub')) {
          callback = args['_dscbstub'];
        }
        if (args.containsKey('data')) {
          arg = args['data'];
        }
      } catch (e) {
        _printDebugInfo(
            'The argument of "$methodName" must be a JSON object string!');
        return json.encode(ret);
      }
    }
    bool asyn = false;
    final method = jsb.functionMap[methodName];
    if (method == null) {
      _printDebugInfo(
          'Not find method "$methodName" implementation! please check if the  signature or namespace of the method is right.');
      return json.encode(ret);
    }
    if (method.runtimeType.toString().contains((#CompletionHandler).name)) {
      asyn = true;
    }
    try {
      if (asyn) {
        method.call(arg, _InnerCompletionHandler(this, callback));
      } else {
        final retData = method.call(arg);
        ret['code'] = 0;
        ret['data'] = retData;
      }
    } on NoSuchMethodError {
      _printDebugInfo(
          'Call failed：The parameter of "$methodName" in Dart is invalid.');
    }
    return json.encode(ret);
  }

  List<String> _parseNamespace(String method) {
    final pos = method.indexOf('.');
    var namespace = '';
    if (pos != -1) {
      namespace = method.substring(0, pos);
      method = method.substring(pos + 1);
    }
    return [namespace, method];
  }

  void _setJavaScriptAlertCallback() {
    javaScriptAlertCallback = (message) async {
      final context = _context;
      if (context == null) {
        return;
      }
      await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                )
              ],
            );
          });
    };
  }

  void _setJavaScriptConfirmCallback() {
    javaScriptConfirmCallback = (message) async {
      final context = _context;
      if (context == null) {
        return false;
      }
      final result = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('OK'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: const Text('Cancel'),
                )
              ],
            );
          });
      return result ?? false;
    };
  }

  void _setJavaScriptPromptCallback() {
    javaScriptPromptCallback = (message, defaultText) async {
      final context = _context;
      if (context == null) {
        return '';
      }
      final textEditingController = TextEditingController();
      textEditingController.text = defaultText ?? '';
      final result = await showDialog<String>(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              title: Text(message),
              content: TextField(
                controller: textEditingController,
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(textEditingController.text);
                  },
                  child: const Text('OK'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop('');
                  },
                  child: const Text('Cancel'),
                )
              ],
            );
          });
      return result ?? '';
    };
  }

  void _printDebugInfo(String error) {
    assert(() {
      error = error.replaceAll("'", "\\'");
      runJavaScript("alert('DEBUG ERR MSG:\\n$error')");
      return true;
    }());
  }

  void _addInternalJavaScriptObject() {
    addJavaScriptObject(_InnerJavaScriptNamespaceInterface(this), '_dsb');
  }

  /// Add a dart object which implemented the javascript interfaces to dsBridge with namespace.
  /// Remove the object using {@link #removeJavascriptObject(String) removeJavascriptObject(String)}
  void addJavaScriptObject(
      JavaScriptNamespaceInterface? object, String? namespace) {
    namespace ??= '';
    if (object == null) {
      return;
    }
    _javaScriptNamespaceInterfaces[namespace] = object;
  }

  /// remove the javascript object with supplied namespace.
  void removeJavaScriptObject(String? namespace) {
    namespace ??= '';
    _javaScriptNamespaceInterfaces.remove(namespace);
  }

  void disableJavaScriptDialogBlock(bool disable) {
    _alertBoxBlock = !disable;
  }

  /// set BuildContext
  void setContext(BuildContext context) {
    _context = context;
  }

  void _dispatchStartupQueue() {
    if (_callInfoList == null) {
      return;
    }
    for (final info in _callInfoList!) {
      _dispatchJavaScriptCall(info);
    }
    _callInfoList = null;
  }

  void _dispatchJavaScriptCall(_CallInfo info) {
    runJavaScript('window._handleMessageFromNative(${info.toString()})');
  }

  void callHandler(String method, {List? args, OnReturnValue? handler}) {
    final callInfo = _CallInfo(method, ++_callID, args);
    if (handler != null) {
      _handlerMap[callInfo.callbackId] = handler;
    }
    if (_callInfoList != null) {
      _callInfoList?.add(callInfo);
    } else {
      _dispatchJavaScriptCall(callInfo);
    }
  }

  /// Test whether the handler exist in javascript
  void hasJavaScriptMethod(String handlerName, OnReturnValue existCallback) {
    callHandler('_hasJavascriptMethod',
        args: [handlerName], handler: existCallback);
  }

  @override
  Future<void> loadFile(String absoluteFilePath) {
    _callInfoList = [];
    return super.loadFile(absoluteFilePath);
  }

  @override
  Future<void> loadFlutterAsset(String key) {
    _callInfoList = [];
    return super.loadFlutterAsset(key);
  }

  @override
  Future<void> loadHtmlString(String html, {String? baseUrl}) {
    _callInfoList = [];
    return super.loadHtmlString(html, baseUrl: baseUrl);
  }

  @override
  Future<void> loadRequest(
    Uri uri, {
    LoadRequestMethod method = LoadRequestMethod.get,
    Map<String, String> headers = const <String, String>{},
    Uint8List? body,
  }) {
    if (!uri.scheme.startsWith('javascript')) {
      _callInfoList = [];
    }
    return super.loadRequest(uri, method: method, headers: headers, body: body);
  }

  @override
  Future<void> reload() {
    _callInfoList = [];
    return super.reload();
  }

  /// release
  void dispose() {
    _javaScriptNamespaceInterfaces.clear();
    removeJavaScriptChannel(_jsChannel);
  }
}

class _InnerJavaScriptNamespaceInterface extends JavaScriptNamespaceInterface {
  final DWebViewController controller;

  _InnerJavaScriptNamespaceInterface(this.controller);

  @override
  void register() {
    registerFunction(hasNativeMethod);
    registerFunction(closePage);
    registerFunction(disableJavascriptDialogBlock);
    registerFunction(dsinit);
    registerFunction(returnValue);
  }

  bool hasNativeMethod(dynamic args) {
    if (args == null || args.isEmpty) {
      return false;
    }
    var methodName = args['name'].trim();
    final type = args['type'].trim();
    final list = controller._parseNamespace(methodName);
    final namespace = list[0];
    methodName = list[1];
    final jsb = controller._javaScriptNamespaceInterfaces[namespace];
    if (jsb == null) {
      return false;
    }
    bool asyn = false;
    final method = jsb.functionMap[methodName];
    if (method == null) {
      return false;
    }
    if (method.runtimeType.toString().contains((#CompletionHandler).name)) {
      asyn = true;
    }
    if (type == 'all' || (asyn && type == 'asyn') || (!asyn && type == 'syn')) {
      return true;
    }
    return false;
  }

  void closePage(dynamic args) {
    controller.javaScriptCloseWindowListener?.call();
  }

  void disableJavascriptDialogBlock(dynamic args) {
    controller._alertBoxBlock = !args['disable'];
  }

  void dsinit(dynamic args) {
    controller._dispatchStartupQueue();
  }

  void returnValue(dynamic args) {
    int id = args['id'];
    bool isCompleted = args['complete'];
    final handler = controller._handlerMap[id];
    dynamic data;
    if (args.containsKey('data')) {
      data = args['data'];
    }
    handler?.call(data);
    if (isCompleted) {
      controller._handlerMap.remove(id);
    }
  }
}

class _InnerCompletionHandler extends CompletionHandler {
  final DWebViewController controller;
  final String? cb;

  _InnerCompletionHandler(this.controller, this.cb);

  @override
  void complete([retValue]) {
    completeProcess(retValue, true);
  }

  @override
  void setProgressData(value) {
    completeProcess(value, false);
  }

  void completeProcess(dynamic retValue, bool complete) {
    final ret = {'code': 0, 'data': retValue};
    if (cb == null) {
      return;
    }
    var script = '$cb(${json.encode(ret)}.data);';
    if (complete) {
      script += 'delete window.$cb';
    }
    controller.runJavaScript(script);
  }
}

class _CallInfo {
  late String data;
  late int callbackId;
  late String method;

  _CallInfo(String handlerName, int id, List? args) {
    args ??= [];
    data = json.encode(args);
    callbackId = id;
    method = handlerName;
  }

  @override
  String toString() {
    final jsonMap = {
      'method': method,
      'callbackId': callbackId,
      'data': data,
    };
    return json.encode(jsonMap);
  }
}
