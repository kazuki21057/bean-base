import 'package:flutter/material.dart';
import '../../routing/app_screen.dart';
import 'create_form_widgets.dart';

/// 012 新規豆追加 — UIモック(保存未接続)。項目は BeanMaster に対応。
class BeanCreateScreen extends StatelessWidget {
  const BeanCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CreateFormScaffold(
      screen: AppScreen.beanNew,
      saveLabel: '豆を登録する',
      children: const [
        FormSection(
          icon: Icons.coffee,
          title: '基本情報',
          children: [
            MockTextField(label: '豆の名前', hint: '例: エチオピア イルガチェフェ', required: true),
            MockTextField(label: '焙煎所 / 購入店', hint: '例: 〇〇コーヒーロースターズ'),
            MockTextField(label: '産地', hint: '例: エチオピア'),
            MockTextField(label: '品種・精製', hint: '例: ウォッシュド'),
            MockChoiceChips(
              label: '煎り度',
              options: ['浅煎り', '中煎り', '中深煎り', '深煎り'],
              initialIndex: 1,
            ),
          ],
        ),
        FormSection(
          icon: Icons.inventory_2_outlined,
          title: '在庫・購入情報',
          children: [
            MockDateField(label: '購入日'),
            MockSwitchTile(label: '在庫あり(瓶に表示する)'),
          ],
        ),
        FormSection(
          icon: Icons.photo_camera_outlined,
          title: '画像',
          children: [
            MockImagePicker(label: '豆の画像'),
          ],
        ),
      ],
    );
  }
}
