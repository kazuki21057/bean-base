import 'package:youtube_player_iframe/youtube_player_iframe.dart';

/// YouTube URL 判定・動画ID抽出ユーティリティ (T3-24)。
///
/// メソッド詳細020の「参考URL」がYouTube動画のとき、埋め込みプレーヤーを
/// 表示するために動画IDを取り出す。抽出そのものはパッケージの
/// [YoutubePlayerController.convertUrlToId] に委譲するが、同関数は
/// `^https://` 固定でスキーム無し/`http://` を弾くため、ここで正規化してから渡す。
///
/// YouTube URL でない場合は null を返し、呼び出し側は従来どおりリンク表示に
/// フォールバックする。
String? youtubeVideoId(String? url) {
  if (url == null) return null;
  final trimmed = url.trim();
  if (trimmed.isEmpty) return null;

  final normalized = _normalizeScheme(trimmed);
  return YoutubePlayerController.convertUrlToId(normalized);
}

/// [youtubeVideoId] が非nullを返すか(=このURLをプレーヤーで埋め込めるか)。
bool isYoutubeUrl(String? url) => youtubeVideoId(url) != null;

/// convertUrlToId が要求する `https://` スキームに正規化する。
///
/// - `http://…`       → `https://…`
/// - `youtube.com/…`  → `https://youtube.com/…` (スキーム無しの手入力を救済)
/// - `youtu.be/…`     → `https://youtu.be/…`
/// - 11文字の裸ID等はそのまま(convertUrlToid側が処理する)
String _normalizeScheme(String url) {
  if (url.startsWith('http://')) {
    return 'https://${url.substring('http://'.length)}';
  }
  if (url.startsWith('https://')) return url;

  final lower = url.toLowerCase();
  if (lower.startsWith('www.youtube.com') ||
      lower.startsWith('youtube.com') ||
      lower.startsWith('m.youtube.com') ||
      lower.startsWith('music.youtube.com') ||
      lower.startsWith('youtu.be')) {
    return 'https://$url';
  }
  return url;
}
