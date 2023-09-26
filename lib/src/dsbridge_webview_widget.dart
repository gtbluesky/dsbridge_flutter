import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_platform_interface/src/platform_webview_widget.dart';

import 'dsbridge_webview_controller.dart';

class DWebViewWidget extends WebViewWidget {
  DWebViewController? _controller;

  DWebViewWidget({
    Key? key,
    required DWebViewController controller,
    TextDirection layoutDirection = TextDirection.ltr,
    Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers =
        const <Factory<OneSequenceGestureRecognizer>>{},
  })  : _controller = controller,
        super.fromPlatformCreationParams(
          key: key,
          params: PlatformWebViewWidgetCreationParams(
            controller: controller.platform,
            layoutDirection: layoutDirection,
            gestureRecognizers: gestureRecognizers,
          ),
        );

  DWebViewWidget.fromPlatformCreationParams({
    Key? key,
    required PlatformWebViewWidgetCreationParams params,
  }) : super.fromPlatform(key: key, platform: PlatformWebViewWidget(params));

  DWebViewWidget.fromPlatform(
      {Key? key, required PlatformWebViewWidget platform})
      : super.fromPlatform(key: key, platform: platform);

  @override
  Widget build(BuildContext context) {
    _controller?.setContext(context);
    return super.build(context);
  }
}
