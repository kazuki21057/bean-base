// T5-B22(束3): 公開版共通コンポーネント `BbNumberField`。
//
// 正本は docs/android_monetization/デザイン方針.md §8。
// 中央にnumeralLの値+unitの単位、左右に48dpのステッパー(−/+、長押しで
// 連続増減)。下にプリセットチップ列(オプション)。キーボードは
// numberWithOptions(decimal: true)。範囲外・空は即座に枠をerror色にし、
// 下に理由をbodySmallで1行表示する。
// 評価スコア(1〜10)にはこれを使わない(§8: 10分割セグメントを使う、
// 本タスクのスコープ外)。
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bean_base/theme/public/bb_theme.dart';
import 'package:bean_base/theme/public/bb_tokens.dart';
import 'package:bean_base/widgets/public/bb_chip.dart';

/// 公開版の数値入力欄。
class BbNumberField extends StatefulWidget {
  const BbNumberField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.min,
    required this.max,
    this.unit,
    this.step = 1,
    this.presets,
    this.decimalPlaces = 0,
  });

  /// 項目名(表示はしないが、範囲外・空のエラー文言に使う。例:「豆量」)。
  final String label;

  /// 現在値。nullは未入力を表す。
  final double? value;

  /// 値が変わるたびに呼ばれる。範囲外・未入力の間はnullを渡す。
  final ValueChanged<double?> onChanged;

  final double min;
  final double max;

  /// 単位(g/℃/秒等)。
  final String? unit;

  /// ステッパー1回あたりの増減量。
  final double step;

  /// プリセットチップ列(例: 15/18/20/22)。省略可。
  final List<double>? presets;

  /// 表示・入力の小数桁数。
  final int decimalPlaces;

  @override
  State<BbNumberField> createState() => _BbNumberFieldState();
}

class _BbNumberFieldState extends State<BbNumberField> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  Timer? _repeatTimer;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _format(widget.value));
    _errorText = _validate(_controller.text);
  }

  @override
  void didUpdateWidget(covariant BbNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && oldWidget.value != widget.value) {
      _controller.text = _format(widget.value);
      _errorText = _validate(_controller.text);
    }
  }

  @override
  void dispose() {
    _repeatTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _format(double? v) {
    if (v == null) return '';
    return widget.decimalPlaces == 0
        ? v.round().toString()
        : v.toStringAsFixed(widget.decimalPlaces);
  }

  String? _validate(String text) {
    if (text.trim().isEmpty) return '${widget.label}を入力してください';
    final parsed = double.tryParse(text);
    if (parsed == null || parsed < widget.min || parsed > widget.max) {
      final unitLabel = widget.unit ?? '';
      return '${widget.label}は${_format(widget.min)}〜${_format(widget.max)}'
          '$unitLabelで入力してください';
    }
    return null;
  }

  void _onTextChanged(String text) {
    final error = _validate(text);
    setState(() => _errorText = error);
    widget.onChanged(error == null ? double.parse(text) : null);
  }

  void _applyValue(double next) {
    final clamped = next.clamp(widget.min, widget.max);
    _controller.text = _format(clamped);
    final error = _validate(_controller.text);
    setState(() => _errorText = error);
    widget.onChanged(error == null ? clamped : null);
  }

  void _step(double delta) {
    debugPrint('[Antigravity] BbNumberField: ステップ label=${widget.label} delta=$delta');
    final current = double.tryParse(_controller.text) ?? widget.min;
    _applyValue(current + delta);
  }

  void _startRepeat(double delta) {
    _step(delta);
    _repeatTimer?.cancel();
    _repeatTimer = Timer(const Duration(milliseconds: 500), () {
      _repeatTimer = Timer.periodic(
        const Duration(milliseconds: 120),
        (_) => _step(delta),
      );
    });
  }

  void _stopRepeat() {
    _repeatTimer?.cancel();
    _repeatTimer = null;
  }

  void _applyPreset(double preset) {
    debugPrint(
      '[Antigravity] BbNumberField: プリセット選択 label=${widget.label} value=$preset',
    );
    _applyValue(preset);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bbType = context.bbType;
    final hasError = _errorText != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _BbNumberFieldStepper(
              icon: Icons.remove,
              onPress: () => _startRepeat(-widget.step),
              onRelease: _stopRepeat,
            ),
            const SizedBox(width: BbSpace.sm),
            Expanded(
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(BbRadius.md),
                  border: Border.all(
                    color: hasError ? colorScheme.error : colorScheme.outlineVariant,
                    width: hasError ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      IntrinsicWidth(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                          ],
                          textAlign: TextAlign.center,
                          style: bbType.numeralL,
                          maxLength: widget.decimalPlaces == 0 ? 5 : 7,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            counterText: '',
                          ),
                          onChanged: _onTextChanged,
                        ),
                      ),
                      if (widget.unit != null) ...[
                        const SizedBox(width: BbSpace.xxs),
                        Text(widget.unit!, style: bbType.unit),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: BbSpace.sm),
            _BbNumberFieldStepper(
              icon: Icons.add,
              onPress: () => _startRepeat(widget.step),
              onRelease: _stopRepeat,
            ),
          ],
        ),
        if (hasError) ...[
          const SizedBox(height: BbSpace.xs),
          Text(
            _errorText!,
            style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.error),
          ),
        ],
        if (widget.presets != null && widget.presets!.isNotEmpty) ...[
          const SizedBox(height: BbSpace.sm),
          Wrap(
            spacing: BbSpace.sm,
            runSpacing: BbSpace.sm,
            children: [
              for (final preset in widget.presets!)
                BbChip(
                  label: widget.unit == null
                      ? _format(preset)
                      : '${_format(preset)}${widget.unit}',
                  selected: widget.value == preset,
                  onSelected: (_) => _applyPreset(preset),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// ステッパーボタン(48×48、長押しで[onPress]を連続呼び出しする間隔は
/// 呼び出し側の`Timer`が担う)。
class _BbNumberFieldStepper extends StatelessWidget {
  const _BbNumberFieldStepper({
    required this.icon,
    required this.onPress,
    required this.onRelease,
  });

  final IconData icon;
  final VoidCallback onPress;
  final VoidCallback onRelease;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTapDown: (_) => onPress(),
      onTapUp: (_) => onRelease(),
      onTapCancel: onRelease,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: colorScheme.onSurfaceVariant),
      ),
    );
  }
}
