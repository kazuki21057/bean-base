library;

/// T3-37: `flutter build web`(release/dart2js)でのみ、Flutter Web の自動プラグイン
/// 登録(`web_plugin_registrant.dart`が呼ぶ`WebYoutubePlayerIframePlatform.registerWith`)
/// が`YoutubePlayerController`構築時点までに`WebViewPlatform.instance`へ反映されておらず、
/// `webview_flutter_platform_interface`内の`WebViewPlatform.instance!`がnull check失敗で
/// クラッシュし、埋め込み領域が灰色のまま何も表示されない不具合があった
/// (`flutter run`のdebugモード/DDCでは発生しない。dart2js側の既知の類似事例あり)。
/// 自動登録が効いていれば no-op、効いていなければここで確実にセットする防御的な保険。
export 'youtube_web_platform_fix_web.dart'
    if (dart.library.io) 'youtube_web_platform_fix_io.dart';
