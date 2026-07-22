import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

/// YouTube 埋め込みプレーヤー (T3-24)。
///
/// メソッド詳細020の「参考URL」がYouTube動画のときに表示する。
/// [videoId] は [youtubeVideoId] で抽出済みの11文字ID。
/// Web/モバイル共通(内部はyoutube_player_iframe=IFrame Player API)。
///
/// コントローラのライフサイクル(生成/破棄)を持つため StatefulWidget。
/// 自動再生はしない(cue)= ユーザーの操作で再生を開始する。
///
/// Cycle 27 T3-31: 実機モバイルで埋め込みが表示されない不具合を修正。
/// Web版の[YoutubePlayer]はiframeを`HtmlElementView`(プラットフォームビュー)
/// として描画するが、これを`ClipRRect`で角丸クリップすると、CanvasKitレンダラ
/// 環境(特にモバイルSafari/Chrome)でプラットフォームビュー自体が描画されない
/// 既知のFlutter課題がある(flutter/flutter#91191, #91805, #161094)。
/// 以前の実装は角丸のため`ClipRRect`でラップしており、これが原因で実機で
/// 再生領域が表示されなかったと判断し、クリップをやめて直接描画するように
/// 変更した(見た目は角丸が無くなるのみで、デスクトップChromeでの動作には
/// 影響なし)。
class YoutubeEmbed extends StatefulWidget {
  final String videoId;

  const YoutubeEmbed({super.key, required this.videoId});

  @override
  State<YoutubeEmbed> createState() => _YoutubeEmbedState();
}

class _YoutubeEmbedState extends State<YoutubeEmbed> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    debugPrint('[Antigravity] Action: YouTube埋め込みプレーヤー初期化 (videoId=${widget.videoId})');
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: false,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        mute: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // T3-31: ClipRRect で囲わない(プラットフォームビューのクリップが
    // 一部ブラウザ/レンダラで再生領域自体を消してしまうため)。
    return YoutubePlayer(
      controller: _controller,
      aspectRatio: 16 / 9,
    );
  }
}
