// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import 'cef_webview_controller.dart';
import 'cef_webview_cookie_manager.dart';

/// Implementation of [WebViewPlatform] using the WebKit API.
class CefWebViewPlatform extends WebViewPlatform {
  /// Registers this class as the default instance of [WebViewPlatform].
  static void registerWith() {
    WebViewPlatform.instance = CefWebViewPlatform();
  }

  @override
  CefWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) {
    return CefWebViewController(params);
  }

  @override
  CefNavigationDelegate createPlatformNavigationDelegate(
    PlatformNavigationDelegateCreationParams params,
  ) {
    return CefNavigationDelegate(params);
  }

  @override
  CefWebViewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) {
    return CefWebViewWidget(params);
  }

  @override
  CefWebViewCookieManager createPlatformCookieManager(
    PlatformWebViewCookieManagerCreationParams params,
  ) {
    return CefWebViewCookieManager(params);
  }
}
