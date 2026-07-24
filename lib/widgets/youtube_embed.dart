import 'dart:async';

import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../utils/youtube_web_platform_fix.dart';

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
///
/// Cycle 27 T3-37: T3-31後も「灰色の背景のみで埋め込みが何も表示されない」報告が
/// あり、`flutter build web`(release/dart2js)のビルドだけで再現することを確認した
/// (`flutter run`のdebug/DDCでは再現しない)。原因は
/// `youtube_player_iframe`のコントローラ構築時に呼ばれる
/// `webview_flutter`の`NavigationDelegate()`が内部で`WebViewPlatform.instance!`を
/// 参照するが、release ビルドではこの時点で Flutter Web の自動プラグイン登録
/// (`WebYoutubePlayerIframePlatform.registerWith`)の反映が間に合わずnullのままで、
/// null check operator の例外がコンソールに出て初期化が止まっていたため
/// (`ensureYoutubeWebViewPlatformRegistered`参照)。
class YoutubeEmbed extends StatefulWidget {
  final String videoId;

  const YoutubeEmbed({super.key, required this.videoId});

  @override
  State<YoutubeEmbed> createState() => _YoutubeEmbedState();
}

class _YoutubeEmbedState extends State<YoutubeEmbed> {
  late final YoutubePlayerController _controller;
  StreamSubscription<YoutubePlayerValue>? _valueSub;

  @override
  void initState() {
    super.initState();
    debugPrint('[Antigravity] Action: YouTube埋め込みプレーヤー初期化 (videoId=${widget.videoId})');
    ensureYoutubeWebViewPlatformRegistered();
    _controller = YoutubePlayerController(
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        mute: false,
      ),
      onWebResourceError: (error) {
        debugPrint(
          '[Antigravity] Error: YouTube埋め込みプレーヤーのWebViewエラー '
          '(videoId=${widget.videoId}, type=${error.errorType}, code=${error.errorCode}): '
          '${error.description}',
        );
      },
    )..cueVideoById(videoId: widget.videoId);
    // T3-37: 実機で「灰色の背景のみで何も表示されない」報告があり、原因切り分け用に
    // プレーヤー状態の遷移を逐次ログする(state が unknown/unStarted のまま変化しない
    // 場合はブリッジ未初期化、cued 以降に進まない場合は別要因と切り分けられる)。
    _valueSub = _controller.stream.listen((value) {
      debugPrint(
        '[Antigravity] Action: YouTube埋め込みプレーヤー状態変化 '
        '(videoId=${widget.videoId}, state=${value.playerState}, error=${value.error})',
      );
    });
  }

  @override
  void dispose() {
    _valueSub?.cancel();
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
