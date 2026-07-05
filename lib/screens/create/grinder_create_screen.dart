import 'package:flutter/material.dart';
import '../../routing/app_screen.dart';
import 'create_form_widgets.dart';

/// 024 新規グラインダー — UIモック(保存未接続)。項目は GrinderMaster に対応。
class GrinderCreateScreen extends StatelessWidget {
  const GrinderCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CreateFormScaffold(
      screen: AppScreen.grinderNew,
      saveLabel: 'グラインダーを登録する',
      children: const [
        FormSection(
          icon: Icons.settings_input_component_outlined,
          title: '基本情報',
          children: [
            MockTextField(label: '名前', hint: '例: コマンダンテ C40', required: true),
            MockTextField(
              label: '挽き目レンジ',
              hint: '例: 15〜25クリック(ペーパードリップ)',
            ),
            MockTextField(
              label: '説明・メモ',
              hint: '手入れ方法や癖などを記録',
              maxLines: 3,
            ),
          ],
        ),
        FormSection(
          icon: Icons.photo_camera_outlined,
          title: '画像',
          children: [
            MockImagePicker(label: 'グラインダーの画像'),
          ],
        ),
      ],
    );
  }
}
