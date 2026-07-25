import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../routing/app_screen.dart';
import '../services/ai_analysis_service.dart';
import 'create/create_form_widgets.dart';
import 'mock/mock_scaffold.dart';

/// 043 Geminiモデル設定 (T3-39)。
///
/// 090の「Gemini APIキー」欄下から遷移する専用ページ。AI解釈・画像抽出で
/// 使うGeminiモデルを選択でき、選択値は`shared_preferences`(キー`gemini_model`)
/// に保存する。選択したモデルは`AiAnalysisService`の各メソッドで最初に試行され、
/// 失敗時は既定のフォールバック順(`gemini-2.5-flash`等)に続けて試行される
/// (`AiAnalysisService._modelOrder`)。
///
/// モデル一覧(`kSelectableGeminiModels`)は`https://ai.google.dev/gemini-api/docs/pricing?hl=ja`
/// を参照し実装時点(2026-07-25)の現行モデルから、テキスト/画像入力に対応する
/// 汎用モデルのみを厳選した(画像/動画/音声生成・embedding・preview限定版は除外)。
class GeminiModelScreen extends StatefulWidget {
  const GeminiModelScreen({super.key});

  @override
  State<GeminiModelScreen> createState() => _GeminiModelScreenState();
}

class _GeminiModelScreenState extends State<GeminiModelScreen> {
  String? _selected;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('gemini_model');
    setState(() {
      _selected = (saved != null && saved.isNotEmpty) ? saved : null;
      _loading = false;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final prefs = await SharedPreferences.getInstance();
    if (_selected == null) {
      await prefs.remove('gemini_model');
    } else {
      await prefs.setString('gemini_model', _selected!);
    }
    debugPrint('[Antigravity] Action: Geminiモデル設定を保存 (model=${_selected ?? "自動"})');
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_selected == null ? '自動(既定の優先順)に設定しました' : '$_selectedを優先するように設定しました')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MockScreenScaffold(
      screen: AppScreen.geminiModel,
      children: [
        FormSection(
          icon: Icons.tune_outlined,
          title: '使用するモデル',
          children: [
            const Text(
              'AI解釈(回帰・PCA)や画像からの豆情報抽出で優先的に使うGeminiモデルを選べます。'
              '選んだモデルの呼び出しに失敗した場合は、既定の優先順(gemini-2.5-flashなど)に'
              '自動的にフォールバックします。',
              style: TextStyle(fontSize: 13, color: kMocha),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              RadioGroup<String?>(
                groupValue: _selected,
                onChanged: (v) => setState(() => _selected = v),
                child: Column(
                  children: [
                    const RadioListTile<String?>(
                      contentPadding: EdgeInsets.zero,
                      title: Text('自動(既定の優先順で試行)'),
                      subtitle: Text('gemini-2.5-flash → gemini-2.0-flash-lite → gemini-2.0-flash'),
                      value: null,
                    ),
                    const Divider(height: 8),
                    for (final model in kSelectableGeminiModels)
                      RadioListTile<String?>(
                        contentPadding: EdgeInsets.zero,
                        title: Text(model),
                        value: model,
                      ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _loading || _saving ? null : _save,
            icon: const Icon(Icons.check),
            label: Text(_saving ? '保存中...' : 'この設定を保存する'),
          ),
        ),
      ],
    );
  }
}
