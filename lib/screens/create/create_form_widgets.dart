import 'package:flutter/material.dart';
import '../../routing/app_screen.dart';
import '../../theme/blackboard_theme.dart';

/// 作成系画面(012/015/018/021/024/031)のUIモック共通部品。
///
/// Cycle 20 時点では見た目のみで、保存処理は未接続(ボタンはダミー)。
/// 本実装時は T1-5a の汎用マスターテンプレート/T2-5a の評価画面実装で
/// DataService に接続する。

// コーヒートーンの配色(Phase 2 のテーマ確定までの暫定パレット)
const kEspresso = Color(0xFF3E2723);
const kMocha = Color(0xFF6D4C41);
const kLatte = Color(0xFFD7CCC8);
const kCream = Color(0xFFF7F3EE);
const kAccent = Color(0xFFB5895A);

/// 作成画面共通の骨格。AppBar(画面コードバッジ付き)+セクション+保存バー。
class CreateFormScaffold extends StatelessWidget {
  final AppScreen screen;
  final List<Widget> children;
  final String saveLabel;
  final String? title;
  final VoidCallback? onSave;
  final bool disabled;

  const CreateFormScaffold({
    super.key,
    required this.screen,
    required this.children,
    this.saveLabel = '保存する',
    this.title,
    this.onSave,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCream,
      appBar: AppBar(
        backgroundColor: kEspresso,
        foregroundColor: kCream,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: kAccent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                screen.code,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(title ?? screen.titleJa, style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: children,
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: kLatte.withValues(alpha: 0.8))),
          ),
          child: Row(
            children: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: kMocha,
                  side: const BorderSide(color: kMocha),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('キャンセル'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kEspresso,
                    foregroundColor: kCream,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.check),
                  label: Text(saveLabel),
                  onPressed: disabled
                      ? null
                      : onSave ??
                          () {
                            debugPrint(
                                '[Antigravity] MockSave: ${screen.code} ${screen.titleJa} — UIモックのため保存処理は未実装');
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('UIモックです。保存処理は後続タスクで実装されます。'),
                              ),
                            );
                          },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// セクション見出し付きのカード。
///
/// `dark: true` で黒板風(Cycle 20 T2-1a)の配色になる。デフォルトは
/// 従来どおりの白カードのため、既存の呼び出し元(001以外)は無変更で動く。
class FormSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;
  final bool dark;

  const FormSection({
    super.key,
    required this.icon,
    required this.title,
    required this.children,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? kBoardBgLight : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dark ? kBoardFrame : kLatte, width: dark ? 2 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: dark ? kChalkAccent : kMocha),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: dark ? kChalkWhite : kEspresso,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

/// モック用テキスト入力(controller未接続)。
class MockTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final String? suffix;
  final bool required;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? initialValue;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  const MockTextField({
    super.key,
    required this.label,
    this.hint,
    this.suffix,
    this.required = false,
    this.maxLines = 1,
    this.keyboardType,
    this.initialValue,
    this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller ??
            (initialValue == null ? null : TextEditingController(text: initialValue)),
        onChanged: onChanged,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          label: required
              ? Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(label),
                  const Text(' *', style: TextStyle(color: Colors.red)),
                ])
              : Text(label),
          hintText: hint,
          suffixText: suffix,
          filled: true,
          fillColor: kCream,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: kLatte),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: kLatte),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: kMocha, width: 2),
          ),
        ),
      ),
    );
  }
}

/// 選択チップ列(ローカル状態のみ)。
class MockChoiceChips extends StatefulWidget {
  final String label;
  final List<String> options;
  final int? initialIndex;
  final String? initialValue;
  final ValueChanged<String?>? onChanged;

  const MockChoiceChips({
    super.key,
    required this.label,
    required this.options,
    this.initialIndex,
    this.initialValue,
    this.onChanged,
  });

  @override
  State<MockChoiceChips> createState() => _MockChoiceChipsState();
}

class _MockChoiceChipsState extends State<MockChoiceChips> {
  int? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialIndex;
    if (_selected == null && widget.initialValue != null) {
      final idx = widget.options.indexOf(widget.initialValue!);
      if (idx >= 0) _selected = idx;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.label,
              style: const TextStyle(fontSize: 13, color: kMocha)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (int i = 0; i < widget.options.length; i++)
                ChoiceChip(
                  label: Text(widget.options[i]),
                  selected: _selected == i,
                  selectedColor: kAccent.withValues(alpha: 0.25),
                  onSelected: (v) {
                    setState(() => _selected = v ? i : null);
                    widget.onChanged?.call(v ? widget.options[i] : null);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 日付選択フィールド。
class MockDateField extends StatefulWidget {
  final String label;
  final DateTime? initialValue;
  final ValueChanged<DateTime?>? onChanged;

  const MockDateField({
    super.key,
    required this.label,
    this.initialValue,
    this.onChanged,
  });

  @override
  State<MockDateField> createState() => _MockDateFieldState();
}

class _MockDateFieldState extends State<MockDateField> {
  late DateTime? _date = widget.initialValue;

  @override
  Widget build(BuildContext context) {
    final text = _date == null
        ? '未選択'
        : '${_date!.year}/${_date!.month.toString().padLeft(2, '0')}/${_date!.day.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: _date ?? DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime(2100),
          );
          if (picked != null) {
            setState(() => _date = picked);
            widget.onChanged?.call(picked);
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: widget.label,
            filled: true,
            fillColor: kCream,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: kLatte),
            ),
            suffixIcon: const Icon(Icons.calendar_today, size: 18),
          ),
          child: Text(text),
        ),
      ),
    );
  }
}

/// 画像アップロード枠のモック(タップでSnackBar)。
class MockImagePicker extends StatelessWidget {
  final String label;

  const MockImagePicker({super.key, this.label = '画像'});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('UIモックです。画像選択は後続タスクで実装されます。')),
          );
        },
        child: Container(
          height: 140,
          width: double.infinity,
          decoration: BoxDecoration(
            color: kCream,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kLatte, width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_a_photo_outlined, size: 36, color: kMocha),
              const SizedBox(height: 8),
              Text('$labelを選択(タップ)',
                  style: const TextStyle(color: kMocha, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

/// トグルスイッチ行(ローカル状態のみ)。
class MockSwitchTile extends StatefulWidget {
  final String label;
  final bool initialValue;
  final ValueChanged<bool>? onChanged;
  final Color? labelColor;

  const MockSwitchTile({
    super.key,
    required this.label,
    this.initialValue = true,
    this.onChanged,
    this.labelColor,
  });

  @override
  State<MockSwitchTile> createState() => _MockSwitchTileState();
}

class _MockSwitchTileState extends State<MockSwitchTile> {
  late bool _value = widget.initialValue;

  @override
  void didUpdateWidget(MockSwitchTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue) {
      _value = widget.initialValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        widget.label,
        style: TextStyle(fontSize: 14, color: widget.labelColor),
      ),
      activeTrackColor: kAccent,
      value: _value,
      onChanged: (v) {
        setState(() => _value = v);
        widget.onChanged?.call(v);
      },
    );
  }
}

/// 評価スコア用スライダー(0〜10、ローカル状態のみ)。
class MockScoreSlider extends StatefulWidget {
  final String label;
  final double initialValue;
  final ValueChanged<double>? onChanged;

  const MockScoreSlider(
      {super.key, required this.label, this.initialValue = 5, this.onChanged});

  @override
  State<MockScoreSlider> createState() => _MockScoreSliderState();
}

class _MockScoreSliderState extends State<MockScoreSlider> {
  late double _value = widget.initialValue;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(widget.label, style: const TextStyle(fontSize: 13)),
        ),
        Expanded(
          child: Slider(
            value: _value,
            min: 0,
            max: 10,
            divisions: 10,
            activeColor: kAccent,
            label: _value.toInt().toString(),
            onChanged: (v) {
              setState(() => _value = v);
              widget.onChanged?.call(v);
            },
          ),
        ),
        SizedBox(
          width: 28,
          child: Text(
            _value.toInt().toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: kEspresso),
          ),
        ),
      ],
    );
  }
}
