import 'package:flutter/material.dart';
import '../../routing/app_screen.dart';
import 'create_form_widgets.dart';

/// 015 新規ドリッパー — UIモック(保存未接続)。項目は DripperMaster に対応。
class DripperCreateScreen extends StatelessWidget {
  const DripperCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CreateFormScaffold(
      screen: AppScreen.dripperNew,
      saveLabel: 'ドリッパーを登録する',
      children: const [
        FormSection(
          icon: Icons.filter_alt_outlined,
          title: '基本情報',
          children: [
            MockTextField(label: '名前', hint: '例: HARIO V60 02', required: true),
            MockChoiceChips(
              label: '素材',
              options: ['セラミック', 'プラスチック', '金属', 'ガラス'],
            ),
            MockChoiceChips(
              label: '形状',
              options: ['円錐', '台形', '平底(ウェーブ)'],
            ),
          ],
        ),
        FormSection(
          icon: Icons.photo_camera_outlined,
          title: '画像',
          children: [
            MockImagePicker(label: 'ドリッパーの画像'),
          ],
        ),
      ],
    );
  }
}
