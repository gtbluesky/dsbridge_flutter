import 'package:dsbridge/dsbridge.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:webview_flutter/webview_flutter.dart';
// Import for iOS features.
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
// #enddocregion platform_imports

class NativeCallJsPage extends StatefulWidget {
  const NativeCallJsPage({super.key});

  @override
  State<NativeCallJsPage> createState() => _NativeCallJsPageState();
}

class _NativeCallJsPageState extends State<NativeCallJsPage> {
  late final DWebViewController _controller;

  @override
  void initState() {
    super.initState();

    // #docregion platform_features
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final DWebViewController controller =
        DWebViewController.fromPlatformCreationParams(params);
    // #enddocregion platform_features

    controller
      ..setBackgroundColor(Colors.white)
      ..loadFlutterAsset('assets/native-call-js.html');

    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Native call JavaScript'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton(
                child: const Text('addValue(3,4)'),
                onPressed: () {
                  _controller.callHandler('addValue', args: [3, 4],
                      handler: (retValue) {
                    Fluttertoast.showToast(msg: retValue.toString());
                  });
                },
              ),
              FilledButton(
                child: const Text("append('I','love','you')"),
                onPressed: () {
                  _controller.callHandler('append', args: ["I", "love", "you"],
                      handler: (retValue) {
                    Fluttertoast.showToast(msg: retValue.toString());
                  });
                },
              ),
              FilledButton(
                child: const Text('startTimer()'),
                onPressed: () {
                  _controller.callHandler('startTimer', handler: (retValue) {
                    Fluttertoast.showToast(msg: retValue.toString());
                  });
                },
              ),
              FilledButton(
                child: const Text('syn.addValue(5,6)'),
                onPressed: () {
                  _controller.callHandler('syn.addValue', args: [5, 6],
                      handler: (retValue) {
                    Fluttertoast.showToast(msg: retValue.toString());
                  });
                },
              ),
              FilledButton(
                child: const Text('syn.getInfo()'),
                onPressed: () {
                  _controller.callHandler('syn.getInfo', handler: (retValue) {
                    Fluttertoast.showToast(msg: retValue.toString());
                  });
                },
              ),
              FilledButton(
                child: const Text('asyn.addValue(5,6)'),
                onPressed: () {
                  _controller.callHandler('asyn.addValue', args: [5, 6],
                      handler: (retValue) {
                    Fluttertoast.showToast(msg: retValue.toString());
                  });
                },
              ),
              FilledButton(
                child: const Text('asyn.getInfo()'),
                onPressed: () {
                  _controller.callHandler('asyn.getInfo', handler: (retValue) {
                    Fluttertoast.showToast(msg: retValue.toString());
                  });
                },
              ),
              FilledButton(
                child: const Text("hasJavascriptMethod('addValue')"),
                onPressed: () {
                  _controller.hasJavaScriptMethod('addValue', (retValue) {
                    Fluttertoast.showToast(msg: retValue.toString());
                  });
                },
              ),
              FilledButton(
                child: const Text("hasJavascriptMethod('XX')"),
                onPressed: () {
                  _controller.hasJavaScriptMethod('XX', (retValue) {
                    Fluttertoast.showToast(msg: retValue.toString());
                  });
                },
              ),
              FilledButton(
                child: const Text("hasJavascriptMethod('asyn.addValue')"),
                onPressed: () {
                  _controller.hasJavaScriptMethod('asyn.addValue', (retValue) {
                    Fluttertoast.showToast(msg: retValue.toString());
                  });
                },
              ),
              FilledButton(
                child: const Text("hasJavascriptMethod('asyn.XX')"),
                onPressed: () {
                  _controller.hasJavaScriptMethod('asyn.XX', (retValue) {
                    Fluttertoast.showToast(msg: retValue.toString());
                  });
                },
              ),
              SizedBox(
                height: 10,
                child: DWebViewWidget(controller: _controller),
              )
            ],
          ),
        ),
      ),
    );
  }
}
