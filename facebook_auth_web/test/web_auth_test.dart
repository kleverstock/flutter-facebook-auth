@TestOn('browser')

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter_facebook_auth_platform_interface/flutter_facebook_auth_platform_interface.dart';
import 'package:flutter_facebook_auth_web/flutter_facebook_auth_web.dart';

import 'package:flutter_test/flutter_test.dart';
import 'mock/mock_data.dart';

/// create a new instance of FacebookAuthPlugin with Mock Data
FlutterFacebookAuthPlugin getPlugin() => FlutterFacebookAuthPlugin();

JSObject get _fb => globalContext['FB'] as JSObject;

void main() {
  group('init', () {
    test('not initialized', () async {
      final plugin = getPlugin();
      final initialized = plugin.isWebSdkInitialized;
      expect(initialized, false);
      final result = await plugin.login();
      expect(result.status == LoginStatus.failed, true);
    });

    test('is initialized', () async {
      final plugin = getPlugin();
      await plugin.webAndDesktopInitialize(
        appId: '1234',
        cookie: true,
        xfbml: true,
        version: 'v13',
      );
      final initialized = plugin.isWebSdkInitialized;
      _fb['init'] = ((JSObject options) {}).toJS;

      expect(initialized, true);
    });
  });
  group('web authentication', () {
    late bool isLogged = false;
    setUp(
      () {
        _fb['init'] = ((JSObject options) {}).toJS;
        _fb['login'] = ((JSFunction fn, JSAny? _) {
          isLogged = true;
          fn.callAsFunction(
            null,
            {
              'status': 'connected',
              'authResponse': MockData.accessToken,
            }.jsify(),
          );
        }).toJS;

        _fb['logout'] = ((JSFunction fn) {
          isLogged = false;
          fn.callAsFunction(
            null,
            <String, dynamic>{}.jsify(),
          );
        }).toJS;

        _fb['api'] = ((String request, JSFunction fn) {
          if (request == "/me/permissions") {
            fn.callAsFunction(
              null,
              MockData.permissions.jsify(),
            );
          } else {
            fn.callAsFunction(
              null,
              MockData.userData.jsify(),
            );
          }
        }).toJS;

        _fb['getLoginStatus'] = ((JSFunction fn) {
          if (isLogged) {
            fn.callAsFunction(
              null,
              {
                'status': 'connected',
                'authResponse': MockData.accessToken,
              }.jsify(),
            );
          } else {
            fn.callAsFunction(
              null,
              {
                'status': 'unknown',
              }.jsify(),
            );
          }
        }).toJS;
      },
    );
    test('login request', () async {
      final plugin = getPlugin();
      await plugin.webAndDesktopInitialize(
        appId: '1234',
        cookie: true,
        xfbml: true,
        version: 'v10',
      );
      // check that the user is not logged
      expect(await plugin.accessToken, null);

      // make a login request
      final result = await plugin.login();
      // check the login sucessful
      expect(result.status, LoginStatus.success);
      expect(result.accessToken != null, true);

      // get the user data
      Map<String, dynamic> userData = await plugin.getUserData();
      expect(userData.containsKey('name'), true); // check the key name

      // check the logout
      await plugin.logOut();
      expect(await plugin.accessToken, null);
    });
  });
}
