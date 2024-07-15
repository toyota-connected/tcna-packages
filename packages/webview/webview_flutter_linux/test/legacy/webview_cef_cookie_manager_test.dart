// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:webview_flutter_linux/src/cef_webview.dart'
    as cef_webview;
import 'package:webview_flutter_linux/src/legacy/webview_cef_cookie_manager.dart';
import 'package:webview_flutter_platform_interface/src/webview_flutter_platform_interface_legacy.dart';

import 'webview_cef_cookie_manager_test.mocks.dart';

@GenerateMocks(<Type>[cef_webview.CookieManager])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('clearCookies should call cef_webview.clearCookies', () {
    final MockCookieManager mockCookieManager = MockCookieManager();
    when(mockCookieManager.removeAllCookies())
        .thenAnswer((_) => Future<bool>.value(true));
    WebViewCefCookieManager(
      cookieManager: mockCookieManager,
    ).clearCookies();
    verify(mockCookieManager.removeAllCookies());
  });

  test('setCookie should throw ArgumentError for cookie with invalid path', () {
    expect(
      () => WebViewCefCookieManager(cookieManager: MockCookieManager())
          .setCookie(const WebViewCookie(
        name: 'foo',
        value: 'bar',
        domain: 'flutter.dev',
        path: 'invalid;path',
      )),
      throwsA(const TypeMatcher<ArgumentError>()),
    );
  });

  test(
      'setCookie should call cef_webview.csetCookie with properly formatted cookie value',
      () {
    final MockCookieManager mockCookieManager = MockCookieManager();
    WebViewCefCookieManager(cookieManager: mockCookieManager)
        .setCookie(const WebViewCookie(
      name: 'foo&',
      value: 'bar@',
      domain: 'flutter.dev',
    ));
    verify(mockCookieManager.setCookie('flutter.dev', 'foo%26=bar%40; path=/'));
  });
}
