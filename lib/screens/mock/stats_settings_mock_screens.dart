import 'package:flutter/material.dart';
import '../../routing/app_screen.dart';
import '../create/create_form_widgets.dart';
import 'mock_scaffold.dart';

/// 040 統計情報 — UIモック。KPIカード+PCA/レーダーのプレースホルダ。本実装は T2-6。
class StatisticsMockScreen extends StatelessWidget {
  const StatisticsMockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MockScreenScaffold(
      screen: AppScreen.statistics,
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          tooltip: '設定(090)へ',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsMockScreen()),
          ),
        ),
      ],
      children: [
        Row(
          children: const [
            Expanded(child: _KpiCard(label: '総抽出数', value: '128')),
            SizedBox(width: 12),
            Expanded(child: _KpiCard(label: '平均スコア', value: '7.2')),
            SizedBox(width: 12),
            Expanded(child: _KpiCard(label: '今月', value: '12杯')),
          ],
        ),
        const SizedBox(height: 16),
        FormSection(
          icon: Icons.scatter_plot_outlined,
          title: 'PCA 散布図 (味の傾向マップ)',
          children: [
            _chartPlaceholder(Icons.scatter_plot, 'PC1 × PC2 散布図(モック)'),
            const SizedBox(height: 8),
            const Text(
              'AI解釈: 「第1主成分は酸味と香りの明るさ、第2主成分はボディの重さを表しています…」(Gemini・モック文)',
              style: TextStyle(fontSize: 12, color: kMocha, height: 1.5),
            ),
          ],
        ),
        FormSection(
          icon: Icons.radar_outlined,
          title: '直近の味プロファイル',
          children: [
            _chartPlaceholder(Icons.radar, 'レーダーチャート(モック)'),
          ],
        ),
      ],
    );
  }

  Widget _chartPlaceholder(IconData icon, String label) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: kCream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kLatte, width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: kMocha),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: kMocha, fontSize: 13)),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;

  const _KpiCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kLatte),
      ),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: kEspresso)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: kMocha)),
        ],
      ),
    );
  }
}

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
