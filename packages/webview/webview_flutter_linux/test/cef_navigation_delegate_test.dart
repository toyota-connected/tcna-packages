// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:webview_flutter_linux/src/cef_proxy.dart';
import 'package:webview_flutter_linux/src/cef_webview.dart'
    as cef_webview;
import 'package:webview_flutter_linux/webview_flutter_linux.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import 'cef_navigation_delegate_test.mocks.dart';
import 'test_cef_webview.g.dart';

@GenerateMocks(<Type>[
  TestInstanceManagerHostApi,
  cef_webview.HttpAuthHandler,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mocks the call to clear the native InstanceManager.
  TestInstanceManagerHostApi.setup(MockTestInstanceManagerHostApi());

  group('CefNavigationDelegate', () {
    test('onPageFinished', () {
      final CefNavigationDelegate cefNavigationDelegate =
          CefNavigationDelegate(_buildCreationParams());

      late final String callbackUrl;
      cefNavigationDelegate
          .setOnPageFinished((String url) => callbackUrl = url);

      CapturingWebViewClient.lastCreatedDelegate.onPageFinished!(
        cef_webview.WebView.detached(),
        'https://www.google.com',
      );

      expect(callbackUrl, 'https://www.google.com');
    });

    test('onPageStarted', () {
      final CefNavigationDelegate cefNavigationDelegate =
          CefNavigationDelegate(_buildCreationParams());

      late final String callbackUrl;
      cefNavigationDelegate
          .setOnPageStarted((String url) => callbackUrl = url);

      CapturingWebViewClient.lastCreatedDelegate.onPageStarted!(
        cef_webview.WebView.detached(),
        'https://www.google.com',
      );

      expect(callbackUrl, 'https://www.google.com');
    });

    test('onHttpError from onReceivedHttpError', () {
      final CefNavigationDelegate cefNavigationDelegate =
          CefNavigationDelegate(_buildCreationParams());

      late final HttpResponseError callbackError;
      cefNavigationDelegate.setOnHttpError(
          (HttpResponseError httpError) => callbackError = httpError);

      CapturingWebViewClient.lastCreatedDelegate.onReceivedHttpError!(
          cef_webview.WebView.detached(),
          cef_webview.WebResourceRequest(
            url: 'https://www.google.com',
            isForMainFrame: false,
            isRedirect: true,
            hasGesture: true,
            method: 'GET',
            requestHeaders: <String, String>{'X-Mock': 'mocking'},
          ),
          cef_webview.WebResourceResponse(statusCode: 401));

      expect(callbackError.response?.statusCode, 401);
    });

    test('onWebResourceError from onReceivedRequestError', () {
      final CefNavigationDelegate cefNavigationDelegate =
          CefNavigationDelegate(_buildCreationParams());

      late final WebResourceError callbackError;
      cefNavigationDelegate.setOnWebResourceError(
          (WebResourceError error) => callbackError = error);

      CapturingWebViewClient.lastCreatedDelegate.onReceivedRequestError!(
        cef_webview.WebView.detached(),
        cef_webview.WebResourceRequest(
          url: 'https://www.google.com',
          isForMainFrame: false,
          isRedirect: true,
          hasGesture: true,
          method: 'GET',
          requestHeaders: <String, String>{'X-Mock': 'mocking'},
        ),
        cef_webview.WebResourceError(
          errorCode: cef_webview.WebViewClient.errorFileNotFound,
          description: 'Page not found.',
        ),
      );

      expect(callbackError.errorCode,
          cef_webview.WebViewClient.errorFileNotFound);
      expect(callbackError.description, 'Page not found.');
      expect(callbackError.errorType, WebResourceErrorType.fileNotFound);
      expect(callbackError.isForMainFrame, false);
    });

    test('onWebResourceError from onRequestError', () {
      final CefNavigationDelegate cefNavigationDelegate =
          CefNavigationDelegate(_buildCreationParams());

      late final WebResourceError callbackError;
      cefNavigationDelegate.setOnWebResourceError(
          (WebResourceError error) => callbackError = error);

      CapturingWebViewClient.lastCreatedDelegate.onReceivedError!(
        cef_webview.WebView.detached(),
        cef_webview.WebViewClient.errorFileNotFound,
        'Page not found.',
        'https://www.google.com',
      );

      expect(callbackError.errorCode,
          cef_webview.WebViewClient.errorFileNotFound);
      expect(callbackError.description, 'Page not found.');
      expect(callbackError.errorType, WebResourceErrorType.fileNotFound);
      expect(callbackError.isForMainFrame, true);
    });

    test(
        'onNavigationRequest from requestLoading should not be called when loadUrlCallback is not specified',
        () {
      final CefNavigationDelegate cefNavigationDelegate =
          CefNavigationDelegate(_buildCreationParams());

      NavigationRequest? callbackNavigationRequest;
      cefNavigationDelegate
          .setOnNavigationRequest((NavigationRequest navigationRequest) {
        callbackNavigationRequest = navigationRequest;
        return NavigationDecision.prevent;
      });

      CapturingWebViewClient.lastCreatedDelegate.requestLoading!(
        cef_webview.WebView.detached(),
        cef_webview.WebResourceRequest(
          url: 'https://www.google.com',
          isForMainFrame: true,
          isRedirect: true,
          hasGesture: true,
          method: 'GET',
          requestHeaders: <String, String>{'X-Mock': 'mocking'},
        ),
      );

      expect(callbackNavigationRequest, isNull);
    });

    test(
        'onNavigationRequest from requestLoading should be called when request is for main frame',
        () {
      final CefNavigationDelegate cefNavigationDelegate =
          CefNavigationDelegate(_buildCreationParams());

      NavigationRequest? callbackNavigationRequest;
      cefNavigationDelegate
          .setOnNavigationRequest((NavigationRequest navigationRequest) {
        callbackNavigationRequest = navigationRequest;
        return NavigationDecision.prevent;
      });

      cefNavigationDelegate.setOnLoadRequest((_) async {});

      CapturingWebViewClient.lastCreatedDelegate.requestLoading!(
        cef_webview.WebView.detached(),
        cef_webview.WebResourceRequest(
          url: 'https://www.google.com',
          isForMainFrame: true,
          isRedirect: true,
          hasGesture: true,
          method: 'GET',
          requestHeaders: <String, String>{'X-Mock': 'mocking'},
        ),
      );

      expect(callbackNavigationRequest, isNotNull);
    });

    test(
        'onNavigationRequest from requestLoading should not be called when request is not for main frame',
        () {
      final CefNavigationDelegate cefNavigationDelegate =
          CefNavigationDelegate(_buildCreationParams());

      NavigationRequest? callbackNavigationRequest;
      cefNavigationDelegate
          .setOnNavigationRequest((NavigationRequest navigationRequest) {
        callbackNavigationRequest = navigationRequest;
        return NavigationDecision.prevent;
      });

      cefNavigationDelegate.setOnLoadRequest((_) async {});

      CapturingWebViewClient.lastCreatedDelegate.requestLoading!(
        cef_webview.WebView.detached(),
        cef_webview.WebResourceRequest(
          url: 'https://www.google.com',
          isForMainFrame: false,
          isRedirect: true,
          hasGesture: true,
          method: 'GET',
          requestHeaders: <String, String>{'X-Mock': 'mocking'},
        ),
      );

      expect(callbackNavigationRequest, isNull);
    });

    test(
        'onLoadRequest from requestLoading should not be called when navigationRequestCallback is not specified',
        () {
      final Completer<void> completer = Completer<void>();
      final CefNavigationDelegate cefNavigationDelegate =
          CefNavigationDelegate(_buildCreationParams());

      cefNavigationDelegate.setOnLoadRequest((_) {
        completer.complete();
        return completer.future;
      });

      CapturingWebViewClient.lastCreatedDelegate.requestLoading!(
        cef_webview.WebView.detached(),
        cef_webview.WebResourceRequest(
          url: 'https://www.google.com',
          isForMainFrame: true,
          isRedirect: true,
          hasGesture: true,
          method: 'GET',
          requestHeaders: <String, String>{'X-Mock': 'mocking'},
        ),
      );

      expect(completer.isCompleted, false);
    });

    test(
        'onLoadRequest from requestLoading should not be called when onNavigationRequestCallback returns NavigationDecision.prevent',
        () {
      final Completer<void> completer = Completer<void>();
      final CefNavigationDelegate cefNavigationDelegate =
          CefNavigationDelegate(_buildCreationParams());

      cefNavigationDelegate.setOnLoadRequest((_) {
        completer.complete();
        return completer.future;
      });

      late final NavigationRequest callbackNavigationRequest;
      cefNavigationDelegate
          .setOnNavigationRequest((NavigationRequest navigationRequest) {
        callbackNavigationRequest = navigationRequest;
        return NavigationDecision.prevent;
      });

      CapturingWebViewClient.lastCreatedDelegate.requestLoading!(
        cef_webview.WebView.detached(),
        cef_webview.WebResourceRequest(
          url: 'https://www.google.com',
          isForMainFrame: true,
          isRedirect: true,
          hasGesture: true,
          method: 'GET',
          requestHeaders: <String, String>{'X-Mock': 'mocking'},
        ),
      );

      expect(callbackNavigationRequest.isMainFrame, true);
      expect(callbackNavigationRequest.url, 'https://www.google.com');
      expect(completer.isCompleted, false);
    });

    test(
        'onLoadRequest from requestLoading should complete when onNavigationRequestCallback returns NavigationDecision.navigate',
        () {
      final Completer<void> completer = Completer<void>();
      late final LoadRequestParams loadRequestParams;
      final CefNavigationDelegate cefNavigationDelegate =
          CefNavigationDelegate(_buildCreationParams());

      cefNavigationDelegate.setOnLoadRequest((LoadRequestParams params) {
        loadRequestParams = params;
        completer.complete();
        return completer.future;
      });

      late final NavigationRequest callbackNavigationRequest;
      cefNavigationDelegate
          .setOnNavigationRequest((NavigationRequest navigationRequest) {
        callbackNavigationRequest = navigationRequest;
        return NavigationDecision.navigate;
      });

      CapturingWebViewClient.lastCreatedDelegate.requestLoading!(
        cef_webview.WebView.detached(),
        cef_webview.WebResourceRequest(
          url: 'https://www.google.com',
          isForMainFrame: true,
          isRedirect: true,
          hasGesture: true,
          method: 'GET',
          requestHeaders: <String, String>{'X-Mock': 'mocking'},
        ),
      );

      expect(loadRequestParams.uri.toString(), 'https://www.google.com');
      expect(loadRequestParams.headers, <String, String>{'X-Mock': 'mocking'});
      expect(callbackNavigationRequest.isMainFrame, true);
      expect(callbackNavigationRequest.url, 'https://www.google.com');
      expect(completer.isCompleted, true);
    });

    test(
        'onNavigationRequest from urlLoading should not be called when loadUrlCallback is not specified',
        () {
      final CefNavigationDelegate cefNavigationDelegate =
          CefNavigationDelegate(_buildCreationParams());

      NavigationRequest? callbackNavigationRequest;
      cefNavigationDelegate
          .setOnNavigationRequest((NavigationRequest navigationRequest) {
        callbackNavigationRequest = navigationRequest;
        return NavigationDecision.prevent;
      });

      CapturingWebViewClient.lastCreatedDelegate.urlLoading!(
        cef_webview.WebView.detached(),
        'https://www.google.com',
      );

      expect(callbackNavigationRequest, isNull);
    });

    test(
        'onLoadRequest from urlLoading should not be called when navigationRequestCallback is not specified',
        () {
      final Completer<void> completer = Completer<void>();
      final CefNavigationDelegate cefNavigationDelegate =
          CefNavigationDelegate(_buildCreationParams());

      cefNavigationDelegate.setOnLoadRequest((_) {
        completer.complete();
        return completer.future;
      });

      CapturingWebViewClient.lastCreatedDelegate.urlLoading!(
        cef_webview.WebView.detached(),
        'https://www.google.com',
      );

      expect(completer.isCompleted, false);
    });

    test(
        'onLoadRequest from urlLoading should not be called when onNavigationRequestCallback returns NavigationDecision.prevent',
        () {
      final Completer<void> completer = Completer<void>();
      final CefNavigationDelegate cefNavigationDelegate =
          CefNavigationDelegate(_buildCreationParams());

      cefNavigationDelegate.setOnLoadRequest((_) {
        completer.complete();
        return completer.future;
      });

      late final NavigationRequest callbackNavigationRequest;
      cefNavigationDelegate
          .setOnNavigationRequest((NavigationRequest navigationRequest) {
        callbackNavigationRequest = navigationRequest;
        return NavigationDecision.prevent;
      });

      CapturingWebViewClient.lastCreatedDelegate.urlLoading!(
        cef_webview.WebView.detached(),
        'https://www.google.com',
      );

      expect(callbackNavigationRequest.isMainFrame, true);
      expect(callbackNavigationRequest.url, 'https://www.google.com');
      expect(completer.isCompleted, false);
    });

    test(
        'onLoadRequest from urlLoading should complete when onNavigationRequestCallback returns NavigationDecision.navigate',
        () {
      final Completer<void> completer = Completer<void>();
      late final LoadRequestParams loadRequestParams;
      final CefNavigationDelegate cefNavigationDelegate =
          CefNavigationDelegate(_buildCreationParams());

      cefNavigationDelegate.setOnLoadRequest((LoadRequestParams params) {
        loadRequestParams = params;
        completer.complete();
        return completer.future;
      });

      late final NavigationRequest callbackNavigationRequest;
      cefNavigationDelegate
          .setOnNavigationRequest((NavigationRequest navigationRequest) {
        callbackNavigationRequest = navigationRequest;
        return NavigationDecision.navigate;
      });

      CapturingWebViewClient.lastCreatedDelegate.urlLoading!(
        cef_webview.WebView.detached(),
        'https://www.google.com',
      );

      expect(loadRequestParams.uri.toString(), 'https://www.google.com');
      expect(loadRequestParams.headers, <String, String>{});
      expect(callbackNavigationRequest.isMainFrame, true);
      expect(callbackNavigationRequest.url, 'https://www.google.com');
      expect(completer.isCompleted, true);
    });

    test('setOnNavigationRequest should override URL loading', () {
      final CefNavigationDelegate cefNavigationDelegate =
          CefNavigationDelegate(_buildCreationParams());

      cefNavigationDelegate.setOnNavigationRequest(
        (NavigationRequest request) => NavigationDecision.navigate,
      );

      expect(
          CapturingWebViewClient.lastCreatedDelegate
              .synchronousReturnValueForShouldOverrideUrlLoading,
          isTrue);
    });

    test(
        'onLoadRequest from onDownloadStart should not be called when navigationRequestCallback is not specified',
        () {
      final Completer<void> completer = Completer<void>();
      final CefNavigationDelegate cefNavigationDelegate =
          CefNavigationDelegate(_buildCreationParams());

      cefNavigationDelegate.setOnLoadRequest((_) {
        completer.complete();
        return completer.future;
      });

      CapturingDownloadListener.lastCreatedListener.onDownloadStart(
        '',
        '',
        '',
        '',
        0,
      );

      expect(completer.isCompleted, false);
    });

    test(
        'onLoadRequest from onDownloadStart should not be called when onNavigationRequestCallback returns NavigationDecision.prevent',
        () {
      final Completer<void> completer = Completer<void>();
      final CefNavigationDelegate cefNavigationDelegate =
          CefNavigationDelegate(_buildCreationParams());

      cefNavigationDelegate.setOnLoadRequest((_) {
        completer.complete();
        return completer.future;
      });

      late final NavigationRequest callbackNavigationRequest;
      cefNavigationDelegate
          .setOnNavigationRequest((NavigationRequest navigationRequest) {
        callbackNavigationRequest = navigationRequest;
        return NavigationDecision.prevent;
      });

      CapturingDownloadListener.lastCreatedListener.onDownloadStart(
        'https://www.google.com',
        '',
        '',
        '',
        0,
      );

      expect(callbackNavigationRequest.isMainFrame, true);
      expect(callbackNavigationRequest.url, 'https://www.google.com');
      expect(completer.isCompleted, false);
    });

    test(
        'onLoadRequest from onDownloadStart should complete when onNavigationRequestCallback returns NavigationDecision.navigate',
        () {
      final Completer<void> completer = Completer<void>();
      late final LoadRequestParams loadRequestParams;
      final CefNavigationDelegate cefNavigationDelegate =
          CefNavigationDelegate(_buildCreationParams());

      cefNavigationDelegate.setOnLoadRequest((LoadRequestParams params) {
        loadRequestParams = params;
        completer.complete();
        return completer.future;
      });

      late final NavigationRequest callbackNavigationRequest;
      cefNavigationDelegate
          .setOnNavigationRequest((NavigationRequest navigationRequest) {
        callbackNavigationRequest = navigationRequest;
        return NavigationDecision.navigate;
      });

      CapturingDownloadListener.lastCreatedListener.onDownloadStart(
        'https://www.google.com',
        '',
        '',
        '',
        0,
      );

      expect(loadRequestParams.uri.toString(), 'https://www.google.com');
      expect(loadRequestParams.headers, <String, String>{});
      expect(callbackNavigationRequest.isMainFrame, true);
      expect(callbackNavigationRequest.url, 'https://www.google.com');
      expect(completer.isCompleted, true);
    });

    test('onUrlChange', () {
      final CefNavigationDelegate cefNavigationDelegate =
          CefNavigationDelegate(_buildCreationParams());

      late final CefUrlChange urlChange;
      cefNavigationDelegate.setOnUrlChange(
        (UrlChange change) {
          urlChange = change as CefUrlChange;
        },
      );

      CapturingWebViewClient.lastCreatedDelegate.doUpdateVisitedHistory!(
        cef_webview.WebView.detached(),
        'https://www.google.com',
        false,
      );

      expect(urlChange.url, 'https://www.google.com');
      expect(urlChange.isReload, isFalse);
    });

    test('onReceivedHttpAuthRequest emits host and realm', () {
      final CefNavigationDelegate cefNavigationDelegate =
          CefNavigationDelegate(_buildCreationParams());

      String? callbackHost;
      String? callbackRealm;
      cefNavigationDelegate.setOnHttpAuthRequest((HttpAuthRequest request) {
        callbackHost = request.host;
        callbackRealm = request.realm;
      });

      const String expectedHost = 'expectedHost';
      const String expectedRealm = 'expectedRealm';

      CapturingWebViewClient.lastCreatedDelegate.onReceivedHttpAuthRequest!(
        cef_webview.WebView.detached(),
        cef_webview.HttpAuthHandler(),
        expectedHost,
        expectedRealm,
      );

      expect(callbackHost, expectedHost);
      expect(callbackRealm, expectedRealm);
    });

    test('onReceivedHttpAuthRequest calls cancel by default', () {
      CefNavigationDelegate(_buildCreationParams());

      final MockHttpAuthHandler mockAuthHandler = MockHttpAuthHandler();

      CapturingWebViewClient.lastCreatedDelegate.onReceivedHttpAuthRequest!(
        cef_webview.WebView.detached(),
        mockAuthHandler,
        'host',
        'realm',
      );

      verify(mockAuthHandler.cancel());
    });
  });
}

CefNavigationDelegateCreationParams _buildCreationParams() {
  return CefNavigationDelegateCreationParams
      .fromPlatformNavigationDelegateCreationParams(
    const PlatformNavigationDelegateCreationParams(),
    cefWebViewProxy: const CefWebViewProxy(
      createCefWebChromeClient: CapturingWebChromeClient.new,
      createCefWebViewClient: CapturingWebViewClient.new,
      createDownloadListener: CapturingDownloadListener.new,
    ),
  );
}

// Records the last created instance of itself.
// ignore: must_be_immutable
class CapturingWebViewClient extends cef_webview.WebViewClient {
  CapturingWebViewClient({
    super.onPageFinished,
    super.onPageStarted,
    super.onReceivedHttpError,
    super.onReceivedError,
    super.onReceivedHttpAuthRequest,
    super.onReceivedRequestError,
    super.requestLoading,
    super.urlLoading,
    super.doUpdateVisitedHistory,
    super.binaryMessenger,
    super.instanceManager,
  }) : super.detached() {
    lastCreatedDelegate = this;
  }

  static CapturingWebViewClient lastCreatedDelegate = CapturingWebViewClient();

  bool synchronousReturnValueForShouldOverrideUrlLoading = false;

  @override
  Future<void> setSynchronousReturnValueForShouldOverrideUrlLoading(
      bool value) async {
    synchronousReturnValueForShouldOverrideUrlLoading = value;
  }
}

// Records the last created instance of itself.
class CapturingWebChromeClient extends cef_webview.WebChromeClient {
  CapturingWebChromeClient({
    super.onProgressChanged,
    super.onShowFileChooser,
    super.onGeolocationPermissionsShowPrompt,
    super.onGeolocationPermissionsHidePrompt,
    super.onShowCustomView,
    super.onHideCustomView,
    super.onPermissionRequest,
    super.onConsoleMessage,
    super.onJsAlert,
    super.onJsConfirm,
    super.onJsPrompt,
    super.binaryMessenger,
    super.instanceManager,
  }) : super.detached() {
    lastCreatedDelegate = this;
  }

  static CapturingWebChromeClient lastCreatedDelegate =
      CapturingWebChromeClient();
}

// Records the last created instance of itself.
class CapturingDownloadListener extends cef_webview.DownloadListener {
  CapturingDownloadListener({
    required super.onDownloadStart,
    super.binaryMessenger,
    super.instanceManager,
  }) : super.detached() {
    lastCreatedListener = this;
  }

  static CapturingDownloadListener lastCreatedListener =
      CapturingDownloadListener(onDownloadStart: (_, __, ___, ____, _____) {});
}
