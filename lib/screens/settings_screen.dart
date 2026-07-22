import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/origin_master.dart';
import '../providers/data_providers.dart';
import '../providers/theme_provider.dart';
import '../routing/app_screen.dart';
import '../services/data_service.dart';
import '../services/image_service.dart';
import '../services/migration_service.dart';
import 'create/create_form_widgets.dart';
import 'debug/firebase_test_screen.dart';
import 'debug/screen_gallery_screen.dart';
import 'mock/mock_scaffold.dart';
import 'stats_theory_screen.dart';

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

  // T4-1f(設計書§3.3): データ移行(産地の名寄せ)。
  final _migrationService = MigrationService();
  bool _isMigrating = false;
  MigrationResult? _migrationResult;
  final Map<String, OriginMaster?> _manualSelections = {};

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

  Future<void> _runMigration() async {
    setState(() => _isMigrating = true);
    try {
      final service = ref.read(dataServiceProvider);
      final result = await _migrationService.runAutoMigration(service);
      debugPrint(
        '[Antigravity] Action: 産地データ移行実行 '
        '(total=${result.totalBeans}, alreadyMapped=${result.alreadyMapped}, '
        'matched=${result.matched}, unmatched=${result.unmatchedOrigins.length})',
      );
      ref.invalidate(beanMasterProvider);
      setState(() {
        _migrationResult = result;
        _manualSelections
          ..clear()
          ..addEntries(result.unmatchedOrigins.map((o) => MapEntry(o, null)));
      });
    } catch (e) {
      debugPrint('[Antigravity] Error: 産地データ移行に失敗 $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('データ移行に失敗しました: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isMigrating = false);
    }
  }

  Future<void> _confirmManualMapping(String originText) async {
    final selected = _manualSelections[originText];
    if (selected == null) return;
    try {
      final service = ref.read(dataServiceProvider);
      final count = await _migrationService.confirmManualMapping(service, originText, selected);
      debugPrint('[Antigravity] Action: 産地手動確定 ($originText -> ${selected.id}, $count件)');
      ref.invalidate(beanMasterProvider);
      setState(() {
        final current = _migrationResult;
        if (current != null) {
          _migrationResult = MigrationResult(
            totalBeans: current.totalBeans,
            alreadyMapped: current.alreadyMapped + count,
            matched: current.matched,
            unmatchedOrigins:
                current.unmatchedOrigins.where((o) => o != originText).toList(),
          );
        }
        _manualSelections.remove(originText);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('「$originText」を${selected.nameJa}に確定しました($count件)')),
        );
      }
    } catch (e) {
      debugPrint('[Antigravity] Error: 産地手動確定に失敗 $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('確定に失敗しました: $e'), backgroundColor: Colors.red),
        );
      }
    }
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
      showSettingsAction: false,
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
              'ナビゲーションバー等の標準UI・各画面上部のAppBar・保存ボタン・'
              '黒板風背景(色相のみ)に反映されます。カードの罫線やチップ、'
              'グラフの配色など細かいコーヒートーンのアクセント部分は今回は対象外です(T3-9)。',
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
        FormSection(
          icon: Icons.sync_alt_outlined,
          title: 'データ移行(産地の名寄せ)',
          children: [
            const Text(
              '豆に登録済みの産地(自由入力)を、産地マスタと突き合わせます。'
              '何度実行しても、既に設定済みの豆はスキップされます(冪等)。',
              style: TextStyle(fontSize: 12, color: kMocha),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isMigrating ? null : _runMigration,
                icon: _isMigrating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync_alt_outlined),
                label: const Text('産地データ移行を実行'),
              ),
            ),
            if (_migrationResult case final result?) ...[
              const SizedBox(height: 12),
              MockInfoRow(label: '対象の豆', value: '${result.totalBeans}件'),
              MockInfoRow(label: '設定済み(スキップ)', value: '${result.alreadyMapped}件'),
              MockInfoRow(label: '自動突合成功', value: '${result.matched}件'),
              MockInfoRow(label: '未突合', value: '${result.unmatchedOrigins.length}件'),
              if (result.unmatchedOrigins.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  '以下は自動突合できませんでした。手動で産地マスタを選んで確定してください:',
                  style: TextStyle(fontSize: 12, color: kMocha),
                ),
                for (final originText in result.unmatchedOrigins)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Expanded(flex: 2, child: Text(originText)),
                        Expanded(
                          flex: 3,
                          child: ref.watch(originMasterProvider).when(
                                data: (origins) => DropdownButtonFormField<OriginMaster>(
                                  decoration: const InputDecoration(labelText: '産地マスタを選択'),
                                  value: _manualSelections[originText],
                                  isExpanded: true,
                                  items: [
                                    for (final o in origins)
                                      DropdownMenuItem(value: o, child: Text(o.nameJa)),
                                  ],
                                  onChanged: (v) => setState(() => _manualSelections[originText] = v),
                                ),
                                loading: () => const LinearProgressIndicator(),
                                error: (e, s) => Text('読み込みエラー: $e'),
                              ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.check_circle_outline),
                          tooltip: '確定',
                          onPressed: _manualSelections[originText] == null
                              ? null
                              : () => _confirmManualMapping(originText),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ],
        ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _saveApiKey,
            icon: const Icon(Icons.check),
            label: const Text('設定を保存する'),
            style: ElevatedButton.styleFrom(
              backgroundColor: currentColor,
              foregroundColor: kCream,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 24),
        FormSection(
          icon: Icons.menu_book_outlined,
          title: 'ヘルプ',
          children: [
            MockListRow(
              icon: Icons.menu_book_outlined,
              title: '統計の理論と読み方',
              subtitle: '回帰・PCA・好み検定・GP/EIなど統計処理の考え方を解説(T3-33)',
              onTap: () {
                debugPrint('[Antigravity] Action: 設定→統計の理論と読み方(041)へ遷移');
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StatsTheoryScreen()),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
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
