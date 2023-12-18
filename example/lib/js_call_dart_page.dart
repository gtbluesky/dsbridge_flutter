import 'package:dsbridge/dsbridge.dart';
import 'package:example/js_api.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
// Import for iOS features.
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
// #enddocregion platform_imports

class JsCallDartPage extends StatefulWidget {
  const JsCallDartPage({super.key});

  @override
  State<JsCallDartPage> createState() => _JsCallDartPageState();
}

class _JsCallDartPageState extends State<JsCallDartPage> {
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
      ..loadFlutterAsset('assets/js-call-dart.html')
      ..addJavaScriptObject(JsApi(), null)
      ..addJavaScriptObject(JsEchoApi(), 'echo');
    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('JavaScript call Dart'),
      ),
      body: DWebViewWidget(controller: _controller),
      // floatingActionButton: favoriteButton(),
    );
  }

  Widget favoriteButton() {
    return FloatingActionButton(
      onPressed: () async {
        final String? url = await _controller.currentUrl();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Favorited $url')),
          );
        }
      },
      child: const Icon(Icons.favorite),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
