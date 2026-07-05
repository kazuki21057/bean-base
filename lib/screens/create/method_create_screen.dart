import 'package:flutter/material.dart';
import '../../routing/app_screen.dart';
import 'create_form_widgets.dart';

/// 021 新規メソッド — UIモック(保存未接続)。
/// 項目は MethodMaster + PouringStep(注湯ステップ)に対応。
class MethodCreateScreen extends StatelessWidget {
  const MethodCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CreateFormScaffold(
      screen: AppScreen.methodNew,
      saveLabel: 'メソッドを登録する',
      children: const [
        FormSection(
          icon: Icons.menu_book_outlined,
          title: '基本情報',
          children: [
            MockTextField(label: 'メソッド名', hint: '例: 4:6メソッド', required: true),
            MockTextField(label: '発案者', hint: '例: 粕谷 哲'),
            MockTextField(label: '参考URL', hint: 'https://...'),
            MockTextField(label: '説明', hint: 'メソッドの狙い・特徴', maxLines: 3),
          ],
        ),
        FormSection(
          icon: Icons.tune,
          title: '基準レシピ',
          children: [
            MockTextField(
              label: '基準豆量',
              suffix: 'g',
              hint: '20',
              keyboardType: TextInputType.number,
            ),
            MockTextField(
              label: '基準湯量',
              suffix: 'g',
              hint: '300',
              keyboardType: TextInputType.number,
            ),
            MockTextField(
              label: '湯温',
              suffix: '℃',
              hint: '92',
              keyboardType: TextInputType.number,
            ),
            MockTextField(label: '推奨挽き目', hint: '例: 中粗挽き'),
            MockTextField(label: '推奨器具', hint: '例: V60 + ペーパー'),
          ],
        ),
        FormSection(
          icon: Icons.water_drop_outlined,
          title: '注湯ステップ (Pouring Steps)',
          children: [
            _MockPouringStepsEditor(),
          ],
        ),
      ],
    );
  }
}

/// 注湯ステップのモックエディタ。行の追加・削除のみローカルで動く。
class _MockPouringStepsEditor extends StatefulWidget {
  const _MockPouringStepsEditor();

  @override
  State<_MockPouringStepsEditor> createState() =>
      _MockPouringStepsEditorState();
}

class _MockPouringStepsEditorState extends State<_MockPouringStepsEditor> {
  // (開始秒, 湯量g, メモ) のモック行
  final List<(String, String, String)> _steps = [
    ('0:00', '60', '蒸らし'),
    ('0:45', '60', '2投目'),
    ('1:30', '180', '3投目〜'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < _steps.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: kCream,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kLatte),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: kMocha,
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 48,
                  child: Text(_steps[i].$1,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                SizedBox(width: 56, child: Text('${_steps[i].$2} g')),
                Expanded(
                  child: Text(
                    _steps[i].$3,
                    style: const TextStyle(color: kMocha, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: kMocha,
                  onPressed: () => setState(() => _steps.removeAt(i)),
                ),
              ],
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: kMocha),
            icon: const Icon(Icons.add),
            label: const Text('ステップを追加'),
            onPressed: () =>
                setState(() => _steps.add(('--:--', '0', '新しいステップ'))),
          ),
        ),
      ],
    );
  }
}
