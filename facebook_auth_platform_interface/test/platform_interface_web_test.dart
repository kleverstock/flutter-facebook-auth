@TestOn('browser')

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_facebook_auth_platform_interface/flutter_facebook_auth_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mock_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('authenticated', () {
    const MethodChannel channel = MethodChannel(
      'app.meedu/flutter_facebook_auth',
    );
    late bool isLogged;
    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      isLogged = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        switch (call.method) {
          case "login":
            isLogged = true;
            return MockData.accessToken;
          case "getAccessToken":
            return isLogged ? MockData.accessToken : null;
          case "logOut":
            isLogged = false;
            return null;

          case "getUserData":
            return isLogged ? MockData.userData : {};
        }
        return null;
      });
    });

    test('login ok', () async {
      final instance = FacebookAuthPlatform.getInstance();
      AccessToken? accessToken =
          await FacebookAuthPlatform.instance.accessToken;
      Map<String, dynamic> userData =
          await FacebookAuthPlatform.instance.getUserData();
      expect(accessToken, null);
      expect(userData.length == 0, true);
      final loginResult = await instance.login();
      if (loginResult.status == LoginStatus.success) {
        accessToken = loginResult.accessToken;
        expect(accessToken, isNotNull);
        userData = await instance.getUserData();
        expect(userData.containsKey("email"), true);
        await instance.logOut();
        expect(await instance.accessToken, null);
      }
    });

    test('express login failed', () async {
      final instance = FacebookAuthPlatform.getInstance();
      final loginResult = await instance.expressLogin();
      expect(loginResult.status == LoginStatus.failed, true);
    });
  });
}
