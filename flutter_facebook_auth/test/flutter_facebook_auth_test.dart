import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'src/data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('authentication', () {
    const MethodChannel channel = MethodChannel(
      'app.meedu/flutter_facebook_auth',
    );
    late FacebookAuth facebookAuth;
    late bool isLogged, isAutoLogAppEventsEnabled;

    setUp(
      () {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        isLogged = false;
        isAutoLogAppEventsEnabled = false;
        facebookAuth = FacebookAuth.getInstance();
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          channel,
          (MethodCall call) async {
            switch (call.method) {
              case "login":
                isLogged = true;
                return mockAccessToken;
              case "expressLogin":
                isLogged = true;
                return mockAccessToken;
              case "getAccessToken":
                return isLogged ? mockAccessToken : null;
              case "logOut":
                isLogged = false;
                return null;

              case "getUserData":
                // final String fields = call.arguments['fields'];
                final data = mockUserData;
                if (defaultTargetPlatform == TargetPlatform.android) {
                  return jsonEncode(data);
                }
                return data;
              case "isAutoLogAppEventsEnabled":
                return isAutoLogAppEventsEnabled;

              case "updateAutoLogAppEventsEnabled":
                final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
                if (isIOS) {
                  isAutoLogAppEventsEnabled = call.arguments['enabled'];
                }
            }
            return null;
          },
        );
      },
    );

    test('login request', () async {
      expect(facebookAuth.isWebSdkInitialized, false);
      expect(await facebookAuth.accessToken, null);
      await facebookAuth.webAndDesktopInitialize(
        appId: "1233443",
        cookie: true,
        xfbml: true,
        version: "v19.0",
      );
      final result = await facebookAuth.login();
      expect(result.status, LoginStatus.success);
      expect(result.accessToken, isNotNull);
      expect(await facebookAuth.accessToken, isA<AccessToken>());
      final Map<String, dynamic> userData = await facebookAuth.getUserData();
      expect(userData.containsKey("email"), true);
      await facebookAuth.logOut();
      expect(await facebookAuth.accessToken, null);
    });

    test('express login', () async {
      expect(await facebookAuth.accessToken, null);
      final result = await facebookAuth.expressLogin();
      expect(result.status, LoginStatus.success);
    });

    test('test singleton', () async {
      expect(await FacebookAuth.i.accessToken, null);
    });

    test('autoLogAppEventsEnabled', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(await facebookAuth.isAutoLogAppEventsEnabled, false);
      await facebookAuth.autoLogAppEventsEnabled(true);
      expect(await facebookAuth.isAutoLogAppEventsEnabled, true);
    });

    test('login: authenticationToken is populated when native layer returns it', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        channel,
        (MethodCall call) async {
          if (call.method == 'login') return mockAccessTokenWithAuthenticationToken;
          return null;
        },
      );

      final result = await facebookAuth.login(
        permissions: ['email', 'openid'],
        loginBehavior: LoginBehavior.webOnly,
      );
      expect(result.status, LoginStatus.success);
      expect(result.accessToken, isA<ClassicToken>());
      final token = result.accessToken as ClassicToken;
      expect(token.authenticationToken, isNotNull);
      expect(
        token.authenticationToken,
        mockAccessTokenWithAuthenticationToken['authenticationToken'],
      );
    });

    test('login: authenticationToken is null when native layer omits it', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        channel,
        (MethodCall call) async {
          if (call.method == 'login') return mockAccessToken;
          return null;
        },
      );

      final result = await facebookAuth.login(
        loginBehavior: LoginBehavior.webOnly,
      );
      expect(result.status, LoginStatus.success);
      expect(result.accessToken, isA<ClassicToken>());
      final token = result.accessToken as ClassicToken;
      expect(token.authenticationToken, isNull);
    });

    test('login: forwards nonce and permissions to the native layer', () async {
      MethodCall? captured;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        channel,
        (MethodCall call) async {
          if (call.method == 'login') {
            captured = call;
            return mockAccessTokenWithAuthenticationToken;
          }
          return null;
        },
      );

      await facebookAuth.login(
        permissions: ['email', 'public_profile', 'openid'],
        loginBehavior: LoginBehavior.nativeWithFallback,
        nonce: 'my-test-nonce',
      );

      expect(captured, isNotNull);
      final args = Map<String, dynamic>.from(captured!.arguments as Map);
      expect(args['nonce'], 'my-test-nonce');
      expect(args['permissions'], containsAll(['email', 'public_profile', 'openid']));
      expect(args['loginBehavior'], 'NATIVE_WITH_FALLBACK');
    });

    test('login: nonce is null in native arguments when not provided', () async {
      MethodCall? captured;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        channel,
        (MethodCall call) async {
          if (call.method == 'login') {
            captured = call;
            return mockAccessToken;
          }
          return null;
        },
      );

      await facebookAuth.login();

      expect(captured, isNotNull);
      final args = Map<String, dynamic>.from(captured!.arguments as Map);
      expect(args['nonce'], isNull);
    });

    test('expressLogin: authenticationToken is populated when native layer returns it', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        channel,
        (MethodCall call) async {
          if (call.method == 'expressLogin') return mockAccessTokenWithAuthenticationToken;
          return null;
        },
      );

      final result = await facebookAuth.expressLogin();
      expect(result.status, LoginStatus.success);
      expect(result.accessToken, isA<ClassicToken>());
      final token = result.accessToken as ClassicToken;
      expect(token.authenticationToken, isNotNull);
      expect(
        token.authenticationToken,
        mockAccessTokenWithAuthenticationToken['authenticationToken'],
      );
    });

    test('getAccessToken: authenticationToken is populated when native layer returns it', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        channel,
        (MethodCall call) async {
          if (call.method == 'getAccessToken') return mockAccessTokenWithAuthenticationToken;
          return null;
        },
      );

      final token = await facebookAuth.accessToken;
      expect(token, isA<ClassicToken>());
      expect((token as ClassicToken).authenticationToken, isNotNull);
      expect(
        token.authenticationToken,
        mockAccessTokenWithAuthenticationToken['authenticationToken'],
      );
    });
  });
}
