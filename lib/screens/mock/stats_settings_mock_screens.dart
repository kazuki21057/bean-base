import 'package:flutter/material.dart';
import '../../routing/app_screen.dart';
import '../create/create_form_widgets.dart';
import 'mock_scaffold.dart';

/// 090 設定 — UIモック。メインカラー/APIキー/データ保存先。本実装は T2-7。
class SettingsMockScreen extends StatelessWidget {
  const SettingsMockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MockScreenScaffold(
      screen: AppScreen.settings,
      maxWidth: 560,
      children: [
        FormSection(
          icon: Icons.palette_outlined,
          title: 'メインカラー',
          children: [
            Wrap(
              spacing: 10,
              children: [
                for (final (color, selected) in const [
                  (kEspresso, true),
                  (Color(0xFF2F3E33), false),
                  (Color(0xFF37474F), false),
                  (Color(0xFF4E342E), false),
                  (Color(0xFF6A1B9A), false),
                ])
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? kAccent : kLatte,
                        width: selected ? 3 : 1,
                      ),
                    ),
                    child: selected
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
              ],
            ),
          ],
        ),
        const FormSection(
          icon: Icons.key_outlined,
          title: 'Gemini APIキー',
          children: [
            MockTextField(
              label: 'APIキー',
              hint: '••••••••••••••••(端末内にのみ保存)',
            ),
          ],
        ),
        FormSection(
          icon: Icons.storage_outlined,
          title: 'データ保存先',
          children: const [
            MockInfoRow(label: 'データ', value: 'Google Sheets (GAS Web App 経由)'),
            MockInfoRow(label: '画像', value: 'Google Drive (GAS 経由アップロード)'),
            MockInfoRow(label: '接続状態', value: '接続OK(モック表示)'),
          ],
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: kEspresso,
            foregroundColor: kCream,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          icon: const Icon(Icons.check),
          label: const Text('設定を保存する'),
          onPressed: () {
            debugPrint('[Antigravity] MockSave: 090 設定 — UIモックのため保存処理は未実装');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('UIモックです。保存処理は後続タスクで実装されます。')),
            );
          },
        ),
      ],
    );
  }
}
