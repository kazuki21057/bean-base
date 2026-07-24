import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
// ignore: implementation_imports
import 'package:youtube_player_iframe_web/src/web_youtube_player_iframe_platform.dart';

void ensureYoutubeWebViewPlatformRegistered() {
  WebViewPlatform.instance ??= WebYoutubePlayerIframePlatform();
}
