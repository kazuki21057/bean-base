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
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: YoutubePlayer(
        controller: _controller,
        aspectRatio: 16 / 9,
      ),
    );
  }
}
