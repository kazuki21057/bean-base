import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/data_providers.dart';
import '../services/image_service.dart';
import 'debug/firebase_test_screen.dart';
import 'debug/screen_gallery_screen.dart';

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

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', _apiKeyController.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings Saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text('Gemini API Key', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _apiKeyController,
              obscureText: _obscureText,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: 'Enter your Gemini API Key',
                suffixIcon: IconButton(
                  icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscureText = !_obscureText),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveSettings,
              child: const Text('Save Settings'),
            ),
            const Divider(height: 40),
            const Text('Debug', style: TextStyle(fontWeight: FontWeight.bold)),
            ListTile(
              leading: const Icon(Icons.cloud_upload),
              title: const Text('Firebase Storage Test'),
              subtitle: const Text('Verify image upload functionality'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FirebaseTestScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.grid_view),
              title: const Text('画面一覧 (Cycle 20 T1-1b)'),
              subtitle: const Text('全22画面のプレースホルダへ遷移確認'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ScreenGalleryScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_photo_alternate_outlined),
              title: const Text('画像一括インポート'),
              subtitle: const Text('ファイル名の先頭がマスターIDと一致する画像をまとめて登録'),
              onTap: () => _handleBulkImageImport(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}
