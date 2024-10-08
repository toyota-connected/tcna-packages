// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'cef_webview.dart' as cef_webview;

/// Handles constructing objects and calling static methods for the Cef
/// WebView native library.
///
/// This class provides dependency injection for the implementations of the
/// platform interface classes. Improving the ease of unit testing and/or
/// overriding the underlying Cef WebView classes.
///
/// By default each function calls the default constructor of the WebView class
/// it intends to return.
class CefWebViewProxy {
  /// Constructs a [CefWebViewProxy].
  const CefWebViewProxy({
    this.createCefWebView = cef_webview.WebView.new,
    this.createCefWebChromeClient = cef_webview.WebChromeClient.new,
    this.createCefWebViewClient = cef_webview.WebViewClient.new,
    this.createFlutterAssetManager = cef_webview.FlutterAssetManager.new,
    this.createJavaScriptChannel = cef_webview.JavaScriptChannel.new,
    this.createDownloadListener = cef_webview.DownloadListener.new,
  });

  /// Constructs a [cef_webview.WebView].
  final cef_webview.WebView Function({
    void Function(int left, int top, int oldLeft, int oldTop)? onScrollChanged,
  }) createCefWebView;

  /// Constructs a [cef_webview.WebChromeClient].
  final cef_webview.WebChromeClient Function({
    void Function(cef_webview.WebView webView, int progress)?
        onProgressChanged,
    Future<List<String>> Function(
      cef_webview.WebView webView,
      cef_webview.FileChooserParams params,
    )? onShowFileChooser,
    void Function(
      cef_webview.WebChromeClient instance,
      cef_webview.PermissionRequest request,
    )? onPermissionRequest,
    Future<void> Function(String origin,
            cef_webview.GeolocationPermissionsCallback callback)?
        onGeolocationPermissionsShowPrompt,
    void Function(cef_webview.WebChromeClient instance)?
        onGeolocationPermissionsHidePrompt,
    void Function(cef_webview.WebChromeClient instance,
            cef_webview.ConsoleMessage message)?
        onConsoleMessage,
    void Function(
            cef_webview.WebChromeClient instance,
            cef_webview.View view,
            cef_webview.CustomViewCallback callback)?
        onShowCustomView,
    void Function(cef_webview.WebChromeClient instance)? onHideCustomView,
    Future<void> Function(String url, String message)? onJsAlert,
    Future<bool> Function(String url, String message)? onJsConfirm,
    Future<String> Function(String url, String message, String defaultValue)?
        onJsPrompt,
  }) createCefWebChromeClient;

  /// Constructs a [cef_webview.WebViewClient].
  final cef_webview.WebViewClient Function({
    void Function(cef_webview.WebView webView, String url)? onPageStarted,
    void Function(cef_webview.WebView webView, String url)? onPageFinished,
    void Function(
      cef_webview.WebView webView,
      cef_webview.WebResourceRequest request,
      cef_webview.WebResourceResponse response,
    )? onReceivedHttpError,
    void Function(
      cef_webview.WebView webView,
      cef_webview.WebResourceRequest request,
      cef_webview.WebResourceError error,
    )? onReceivedRequestError,
    @Deprecated('Only called on Cef version < 23.')
    void Function(
      cef_webview.WebView webView,
      int errorCode,
      String description,
      String failingUrl,
    )? onReceivedError,
    void Function(
      cef_webview.WebView webView,
      cef_webview.WebResourceRequest request,
    )? requestLoading,
    void Function(cef_webview.WebView webView, String url)? urlLoading,
    void Function(cef_webview.WebView webView, String url, bool isReload)?
        doUpdateVisitedHistory,
    void Function(
      cef_webview.WebView webView,
      cef_webview.HttpAuthHandler handler,
      String host,
      String realm,
    )? onReceivedHttpAuthRequest,
  }) createCefWebViewClient;

  /// Constructs a [cef_webview.FlutterAssetManager].
  final cef_webview.FlutterAssetManager Function()
      createFlutterAssetManager;

  /// Constructs a [cef_webview.JavaScriptChannel].
  final cef_webview.JavaScriptChannel Function(
    String channelName, {
    required void Function(String) postMessage,
  }) createJavaScriptChannel;

  /// Constructs a [cef_webview.DownloadListener].
  final cef_webview.DownloadListener Function({
    required void Function(
      String url,
      String userAgent,
      String contentDisposition,
      String mimetype,
      int contentLength,
    ) onDownloadStart,
  }) createDownloadListener;

  /// Enables debugging of web contents (HTML / CSS / JavaScript) loaded into any WebViews of this application.
  ///
  /// This flag can be enabled in order to facilitate debugging of web layouts
  /// and JavaScript code running inside WebViews. Please refer to
  /// [cef_webview.WebView] documentation for the debugging guide. The
  /// default is false.
  ///
  /// See [cef_webview.WebView].setWebContentsDebuggingEnabled.
  Future<void> setWebContentsDebuggingEnabled(bool enabled) {
    return cef_webview.WebView.setWebContentsDebuggingEnabled(enabled);
  }
}
