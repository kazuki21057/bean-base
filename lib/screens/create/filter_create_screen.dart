import 'package:flutter/material.dart';
import '../../routing/app_screen.dart';
import 'create_form_widgets.dart';

/// 018 新規フィルター — UIモック(保存未接続)。項目は FilterMaster に対応。
class FilterCreateScreen extends StatelessWidget {
  const FilterCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CreateFormScaffold(
      screen: AppScreen.filterNew,
      saveLabel: 'フィルターを登録する',
      children: const [
        FormSection(
          icon: Icons.layers_outlined,
          title: '基本情報',
          children: [
            MockTextField(label: '名前', hint: '例: HARIO V60ペーパーフィルター', required: true),
            MockChoiceChips(
              label: '素材',
              options: ['ペーパー(漂白)', 'ペーパー(無漂白)', '金属', '布(ネル)'],
            ),
            MockChoiceChips(
              label: 'サイズ',
              options: ['01', '02', '03', 'その他'],
            ),
          ],
        ),
        FormSection(
          icon: Icons.photo_camera_outlined,
          title: '画像',
          children: [
            MockImagePicker(label: 'フィルターの画像'),
          ],
        ),
      ],
    );
  }
}
