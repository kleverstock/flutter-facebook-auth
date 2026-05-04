# web configuration

> Check a web demo [here](https://flutter-facebook-auth.web.app/)

🚫 _IMPORTANT:_ this package is not compatible with WASM due to CORS policy conflicts as WASM requires `Cross-Origin-Opener-Policy: same-origin`, while Facebook JS SDK requires `Cross-Origin-Opener-Policy: same-origin-allow-popups`. These cannot be used simultaneously.

🚫 _IMPORTANT:_ the facebook javascript SDK is only allowed to use with `https` but you can test the plugin in your localhost with an error message in your web console.

👉 The `accessToken` method only works in live mode using `https` and you must add your **OAuth redirect URL** in your _facebook developer console_.

::: INFO
Since `flutter_facebook_auth:^4.2.0` you don't need to add a script code in your `index.html`.
:::


Go to your `main.dart` file and in your `main` function initialize the facebook SDK.
```dart 
import 'package:flutter/foundation.dart' show kIsWeb; 
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart'; 
.
.
.
Future<void> main() async {
  // check if is running on Web
  if (kIsWeb) {
    // initialize the facebook javascript SDK
   await FacebookAuth.i.webAndDesktopInitialize(
      appId: "YOUR_FACEBOOK_APP_ID",
      cookie: true,
      xfbml: true,
      version: "v19.0",
    );
  }
  runApp(MyApp());
}
```


> On Web if the facebook SDK was not initialized by missing configuration or  content blockers all methods of this plugin will return null or a fail status depending of the method. You can check if the SDK was initialized using ` FacebookAuth.i.isWebSdkInitialized`.
