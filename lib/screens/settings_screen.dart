import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/data_providers.dart';
import '../providers/theme_provider.dart';
import '../routing/app_screen.dart';
import '../services/image_service.dart';
import 'create/create_form_widgets.dart';
import 'debug/firebase_test_screen.dart';
import 'debug/screen_gallery_screen.dart';
import 'mock/mock_scaffold.dart';

/// 豆/ミル/ドリッパー/フィルターの画像をファイル名(先頭がマスターIDと一致)で
/// 突き合わせて一括アップロードする。旧`master_list_screen.dart`(Cycle 20 T1-7で
/// 削除)にあった機能をここへ移植。
Future<void> _handleBulkImageImport(BuildContext context, WidgetRef ref) async {
  debugPrint('[Antigravity] Action: 画像一括インポート開始');
  try {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
    );
    if (!context.mounted) return;

    if (result == null || result.files.isEmpty) {
      debugPrint('[Antigravity] Action: 画像一括インポートをキャンセル');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final summary = await ref.read(imageServiceProvider).importMasterImages(result.files);

    if (context.mounted) Navigator.of(context).pop();

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('インポート結果'),
          content: Text(summary),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }

    ref.invalidate(beanMasterProvider);
    ref.invalidate(grinderMasterProvider);
    ref.invalidate(dripperMasterProvider);
    ref.invalidate(filterMasterProvider);
  } catch (e) {
    debugPrint('[Antigravity] Error: 画像一括インポートに失敗 $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('インポートに失敗しました: $e')),
      );
    }
  }
}

/// 090 設定画面。
///
/// Gemini APIキーの保存・画像一括インポート・デバッグ導線(画面一覧等)は
/// 以前から実装済みだった。
/// Cycle 20 T2-7: 見た目をPhase2共通ウィジェット(MockScreenScaffold/
/// FormSection)へ統一し、「メインカラー」(`theme_provider.dart`経由で
/// `MaterialApp`のThemeDataへ反映・SharedPreferencesに保存)と
/// 「データ保存先情報」(静的な構成表示)を追加した。
/// コーヒートーンパレット(黒板風テーマ含む)は固定値のハードコードのため、
/// メインカラーを変更してもそちらの見た目は変化しない(NavigationRail等の
/// 標準Materialウィジェットにのみ反映される)。
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  bool _isLoading = true;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiKeyController.text = prefs.getString('gemini_api_key') ?? '';
      _isLoading = false;
    });
  }

  Future<void> _saveApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', _apiKeyController.text.trim());
    debugPrint('[Antigravity] Action: Gemini APIキーを保存');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('設定を保存しました')),
      );
    }
  }

  Future<void> _selectMainColor(Color color) async {
    ref.read(mainColorProvider.notifier).state = color;
    await saveMainColor(color);
    debugPrint('[Antigravity] Action: メインカラーを保存 (${color.toARGB32().toRadixString(16)})');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentColor = ref.watch(mainColorProvider);

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
                for (final color in mainColorPresets)
                  GestureDetector(
                    onTap: () => _selectMainColor(color),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: color.toARGB32() == currentColor.toARGB32() ? kAccent : kLatte,
                          width: color.toARGB32() == currentColor.toARGB32() ? 3 : 1,
                        ),
                      ),
                      child: color.toARGB32() == currentColor.toARGB32()
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'ナビゲーションバー等の標準UIに反映されます(黒板風テーマなど独自デザイン部分は対象外)',
              style: TextStyle(fontSize: 11, color: kMocha),
            ),
          ],
        ),
        FormSection(
          icon: Icons.key_outlined,
          title: 'Gemini APIキー',
          children: [
            MockTextField(
              label: 'APIキー',
              hint: '端末内にのみ保存されます',
              controller: _apiKeyController,
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => setState(() => _obscureText = !_obscureText),
                icon: Icon(_obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
                label: Text(_obscureText ? '表示する' : '隠す'),
              ),
            ),
          ],
        ),
        FormSection(
          icon: Icons.storage_outlined,
          title: 'データ保存先',
          children: const [
            MockInfoRow(label: 'データ', value: 'Google Sheets (GAS Web App 経由)'),
            MockInfoRow(label: '画像', value: 'Google Drive (GAS 経由アップロード)'),
          ],
        ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _saveApiKey,
            icon: const Icon(Icons.check),
            label: const Text('設定を保存する'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kEspresso,
              foregroundColor: kCream,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 24),
        FormSection(
          icon: Icons.bug_report_outlined,
          title: 'Debug',
          children: [
            MockListRow(
              icon: Icons.cloud_upload_outlined,
              title: 'Firebase Storage Test',
              subtitle: 'Verify image upload functionality',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const FirebaseTestScreen()));
              },
            ),
            MockListRow(
              icon: Icons.grid_view_outlined,
              title: '画面一覧 (Cycle 20 T1-1b)',
              subtitle: '全22画面のプレースホルダへ遷移確認',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ScreenGalleryScreen()));
              },
            ),
            MockListRow(
              icon: Icons.add_photo_alternate_outlined,
              title: '画像一括インポート',
              subtitle: 'ファイル名の先頭がマスターIDと一致する画像をまとめて登録',
              onTap: () => _handleBulkImageImport(context, ref),
            ),
          ],
        ),
      ],
    );
  }
}
