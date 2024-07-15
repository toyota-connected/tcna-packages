// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:webview_flutter_linux/src/cef_webview.dart'
    as cef_webview;
import 'package:webview_flutter_linux/src/cef_webview_api_impls.dart';
import 'package:webview_flutter_linux/src/instance_manager.dart';
import 'package:webview_flutter_linux/webview_flutter_linux.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import 'cef_webview_cookie_manager_test.mocks.dart';
import 'test_cef_webview.g.dart';

@GenerateMocks(<Type>[
  cef_webview.CookieManager,
  CefWebViewController,
  TestInstanceManagerHostApi,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mocks the call to clear the native InstanceManager.
  TestInstanceManagerHostApi.setup(MockTestInstanceManagerHostApi());

  test('clearCookies should call cef_webview.clearCookies', () async {
    final cef_webview.CookieManager mockCookieManager = MockCookieManager();

    when(mockCookieManager.removeAllCookies())
        .thenAnswer((_) => Future<bool>.value(true));

    final CefWebViewCookieManagerCreationParams params =
        CefWebViewCookieManagerCreationParams
            .fromPlatformWebViewCookieManagerCreationParams(
                const PlatformWebViewCookieManagerCreationParams());

    final bool hasClearedCookies = await CefWebViewCookieManager(params,
            cookieManager: mockCookieManager)
        .clearCookies();

    expect(hasClearedCookies, true);
    verify(mockCookieManager.removeAllCookies());
  });

  test('setCookie should throw ArgumentError for cookie with invalid path', () {
    final CefWebViewCookieManagerCreationParams params =
        CefWebViewCookieManagerCreationParams
            .fromPlatformWebViewCookieManagerCreationParams(
                const PlatformWebViewCookieManagerCreationParams());

    final CefWebViewCookieManager cefCookieManager =
        CefWebViewCookieManager(params, cookieManager: MockCookieManager());

    expect(
      () => cefCookieManager.setCookie(const WebViewCookie(
        name: 'foo',
        value: 'bar',
        domain: 'flutter.dev',
        path: 'invalid;path',
      )),
      throwsA(const TypeMatcher<ArgumentError>()),
    );
  });

  test(
      'setCookie should call cef_webview.setCookie with properly formatted cookie value',
      () {
    final cef_webview.CookieManager mockCookieManager = MockCookieManager();
    final CefWebViewCookieManagerCreationParams params =
        CefWebViewCookieManagerCreationParams
            .fromPlatformWebViewCookieManagerCreationParams(
                const PlatformWebViewCookieManagerCreationParams());

    CefWebViewCookieManager(params, cookieManager: mockCookieManager)
        .setCookie(const WebViewCookie(
      name: 'foo&',
      value: 'bar@',
      domain: 'flutter.dev',
    ));

    verify(mockCookieManager.setCookie(
      'flutter.dev',
      'foo%26=bar%40; path=/',
    ));
  });

  test('setAcceptThirdPartyCookies', () async {
    final MockCefWebViewController mockController =
        MockCefWebViewController();

    final InstanceManager instanceManager =
        InstanceManager(onWeakReferenceRemoved: (_) {});
    cef_webview.WebView.api = WebViewHostApiImpl(
      instanceManager: instanceManager,
    );
    final cef_webview.WebView webView = cef_webview.WebView.detached(
      instanceManager: instanceManager,
    );

    const int webViewIdentifier = 4;
    instanceManager.addHostCreatedInstance(webView, webViewIdentifier);

    when(mockController.webViewIdentifier).thenReturn(webViewIdentifier);

    final CefWebViewCookieManagerCreationParams params =
        CefWebViewCookieManagerCreationParams
            .fromPlatformWebViewCookieManagerCreationParams(
                const PlatformWebViewCookieManagerCreationParams());

    final cef_webview.CookieManager mockCookieManager = MockCookieManager();

    await CefWebViewCookieManager(
      params,
      cookieManager: mockCookieManager,
    ).setAcceptThirdPartyCookies(mockController, false);

    verify(mockCookieManager.setAcceptThirdPartyCookies(webView, false));

    cef_webview.WebView.api = WebViewHostApiImpl();
  });
}
