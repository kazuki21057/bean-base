import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/data_providers.dart';
import '../models/method_master.dart';
import '../models/pouring_step.dart';
import '../models/pending_brew_info.dart';
import '../routing/app_screen.dart';
import '../services/data_service.dart';
import '../widgets/method_steps_editor.dart';
import 'create/brew_evaluation_screen.dart';
import 'create/create_form_widgets.dart';
import 'create/method_create_screen.dart';
import 'mock/mock_scaffold.dart';

/// 030 抽出レシピ画面。
///
/// Cycle 20 T1-2a: 旧 CalculatorScreen(記録画面)から評価パート(スコア入力・
/// 記録の保存)を切り離し、抽出パート(メソッド/器具選択・湯量計算・タイマー・
/// Pouring Steps編集)のみを扱う単独画面として分離した。
/// 抽出完了後は 031(評価画面)へ遷移する。
/// Cycle 20 T2-3a: 見た目をPhase2共通ウィジェット(MockScreenScaffold/
/// FormSection/MethodStepsEditor)に統一。メソッド選択→Pouring Steps読込・
/// 重量スケーリング・タイマー・ステップハイライト・031への引き継ぎといった
/// 既存ロジックはそのまま維持した。
/// Cycle 20 T2-4a: 「上書き保存」を実際の DataService 接続に置き換えた
/// (021の MethodCreateScreen._submit と同じ add/update/delete 差分パターン)。
/// Cycle 20 T2-4b: 「新規として保存」は 021(MethodCreateScreen)へ基準値・
/// Pouring Stepsを引き継いで遷移する方式にした。名前の確定・実際の登録は
/// 021の通常の新規登録フロー(_submit)で行う。
/// Cycle 20 T3-5: 豆/グラインダー/ドリッパー/フィルター選択と抽出日時は
/// 031(評価画面)側の入力欄に移動した。030はメソッド選択と豆量のみを扱う。
class BrewRecipeScreen extends ConsumerStatefulWidget {
  final String? initialMethodId;
  final double? initialBeanWeight;

  const BrewRecipeScreen({
    super.key,
    this.initialMethodId,
    this.initialBeanWeight,
  });

  @override
  ConsumerState<BrewRecipeScreen> createState() => _BrewRecipeScreenState();
}

class _BrewRecipeScreenState extends ConsumerState<BrewRecipeScreen> {
  MethodMaster? _selectedMethod;
  final TextEditingController _beanWeightController = TextEditingController();

  List<PouringStep> _workingSteps = [];
  List<PouringStep> _originalSteps = [];
  bool _hasInitializedFromArgs = false;
  bool _isSaving = false;

  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _beanWeightController.text = (widget.initialBeanWeight ?? 15).toStringAsFixed(1);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _beanWeightController.dispose();
    super.dispose();
  }

  void _onMethodChanged(MethodMaster? method, List<PouringStep> allSteps) {
    if (method == null) {
      setState(() {
        _selectedMethod = null;
        _workingSteps = [];
        _originalSteps = [];
      });
      return;
    }

    final methodSteps = allSteps.where((s) => s.methodId == method.id).toList()
      ..sort((a, b) => a.stepOrder.compareTo(b.stepOrder));

    setState(() {
      _selectedMethod = method;
      _beanWeightController.text = method.baseBeanWeight.toStringAsFixed(1);
      _workingSteps = methodSteps.map(_cloneStep).toList();
      _originalSteps = methodSteps.map(_cloneStep).toList();
    });
  }

  PouringStep _cloneStep(PouringStep s) => PouringStep(
        id: s.id,
        methodId: s.methodId,
        stepOrder: s.stepOrder,
        duration: s.duration,
        waterAmount: s.waterAmount,
        waterReference: s.waterReference,
        waterRatio: s.waterRatio,
        description: s.description,
      );

  PouringStep _copyWith(PouringStep s,
      {String? id,
      int? stepOrder,
      double? waterAmount,
      int? duration,
      String? description,
      double? waterRatio}) {
    return PouringStep(
      id: id ?? s.id,
      methodId: s.methodId,
      stepOrder: stepOrder ?? s.stepOrder,
      duration: duration ?? s.duration,
      waterAmount: waterAmount ?? s.waterAmount,
      waterReference: s.waterReference,
      waterRatio: waterRatio ?? s.waterRatio,
      description: description ?? s.description,
    );
  }

  // --- Timer ---
  void _toggleTimer() {
    setState(() {
      if (_stopwatch.isRunning) {
        _stopwatch.stop();
        _timer?.cancel();
      } else {
        _stopwatch.start();
        _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
          if (mounted) setState(() {});
        });
      }
    });
  }

  void _resetTimer() {
    setState(() {
      _stopwatch.reset();
      if (_stopwatch.isRunning) {
        _stopwatch.stop();
        _timer?.cancel();
      }
    });
  }

  /// T2-3c: 経過時間から現在のステップindexを求める(タイマー未動作時はnull)。
  ///
  /// 「加算時間(秒)」が0のステップ(例: 蒸らし開始などの瞬間アクション)は
  /// それ自体の待機区間を持たず、実際の待機時間は直後の非ゼロステップ側に
  /// 記録されている(このアプリのPouring Steps入力慣習)。そのため単純に
  /// 区間 [start, cumulative) だけで判定すると、説明文が付いている0秒ステップ
  /// ではなく1つ後ろの(説明文が空のことが多い)ステップが常にハイライトされて
  /// しまう。0秒ステップが連続する先頭indexをグループとして憶えておき、
  /// そのグループの直後の非ゼロ区間がヒットした場合はグループ先頭を返す。
  int? get _activeStepIndex {
    if (!_stopwatch.isRunning) return null;
    final elapsedSec = _stopwatch.elapsedMilliseconds / 1000;
    int cumulative = 0;
    int? zeroGroupStart;
    for (var i = 0; i < _workingSteps.length; i++) {
      final start = cumulative;
      final duration = _workingSteps[i].duration;
      if (duration == 0) {
        zeroGroupStart ??= i;
        continue;
      }
      cumulative += duration;
      if (elapsedSec >= start && elapsedSec < cumulative) {
        return zeroGroupStart ?? i;
      }
      zeroGroupStart = null;
    }
    return null;
  }

  double get _currentWeight => double.tryParse(_beanWeightController.text) ?? 15.0;

  double get _scaleFactor {
    final base = _selectedMethod?.baseBeanWeight ?? 0;
    return base > 0 ? (_currentWeight / base) : 1.0;
  }

  double _stepAmount(PouringStep s) {
    if (s.waterRatio != null && s.waterRatio! > 0) {
      return s.waterRatio! * _currentWeight;
    }
    return s.waterAmount * _scaleFactor;
  }

  Future<void> _showSaveDialog() async {
    if (_selectedMethod == null) return;
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('メソッドを保存'),
        content: Text('「${_selectedMethod!.name}」を上書きしますか、新規メソッドとして保存しますか?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'overwrite'),
            child: const Text('上書き'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'new'),
            child: const Text('新規として保存'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );

    if (choice == 'new') {
      _goToSaveAsNew();
    } else if (choice == 'overwrite') {
      await _saveOverwrite();
    }
  }

  /// 新規メソッドとして保存(T2-4b)。021(MethodCreateScreen)へ現在の
  /// 基準値・Pouring Stepsを引き継いで遷移し、名前の確定・最終保存は021側で
  /// 行う(030内で完結する簡易実装ではなく、021の通常の新規登録フローに合流)。
  void _goToSaveAsNew() {
    final original = _selectedMethod;
    if (original == null) return;

    final finalSteps = _scaledFinalSteps();
    final prefillMethod = MethodMaster(
      id: '',
      name: '${original.name} (コピー)',
      author: original.author,
      baseBeanWeight: _currentWeight,
      baseWaterAmount: finalSteps.fold<double>(0, (sum, s) => sum + s.waterAmount),
      temperature: original.temperature,
      grindSize: original.grindSize,
      description: original.description,
      recommendedEquipment: original.recommendedEquipment,
      sourceUrl: original.sourceUrl,
    );

    debugPrint('[Antigravity] Action: 030から021へ新規メソッドとして継承遷移 (元id=${original.id})');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MethodCreateScreen(prefillFrom: prefillMethod, prefillSteps: finalSteps),
      ),
    );
  }

  List<PouringStep> _scaledFinalSteps() {
    final currentWeight = _currentWeight;
    return _workingSteps.map((s) {
      final amount = _stepAmount(s);
      final ratio = currentWeight > 0 ? amount / currentWeight : 0.0;
      return _copyWith(s, waterAmount: amount, waterRatio: ratio);
    }).toList();
  }

  /// メソッド上書き保存(T2-4a)。021の MethodCreateScreen._submit と同じ
  /// add/update/delete 差分パターンで PouringStep を反映する。
  ///
  /// 保存成功後、`'new_'`プレフィックスの一時IDを確定IDへ差し替えて
  /// ローカル状態を更新する。差し替えないと、画面を閉じずに連続で保存した
  /// 場合に同じステップが addPouringStep で二重追加されてしまう
  /// (021は保存後に画面を閉じるためこの問題が起きないが、030は保存後も
  /// 画面が開いたままなので対策が必要)。
  Future<void> _saveOverwrite() async {
    final original = _selectedMethod;
    if (original == null) return;

    setState(() => _isSaving = true);
    try {
      final currentWeight = _currentWeight;
      final finalSteps = _scaledFinalSteps();
      final totalWater = finalSteps.fold<double>(0, (sum, s) => sum + s.waterAmount);

      final method = MethodMaster(
        id: original.id,
        name: original.name,
        author: original.author,
        baseBeanWeight: currentWeight,
        baseWaterAmount: totalWater,
        temperature: original.temperature,
        grindSize: original.grindSize,
        description: original.description,
        recommendedEquipment: original.recommendedEquipment,
        sourceUrl: original.sourceUrl,
      );

      final DataService service = ref.read(dataServiceProvider);
      await service.updateMethod(method);
      debugPrint('[Antigravity] Action: 030からメソッド更新 (id=${method.id})');

      final persistedSteps = <PouringStep>[];
      for (var i = 0; i < finalSteps.length; i++) {
        final s = finalSteps[i];
        final isNew = s.id.startsWith('new_');
        final persistedId = isNew ? 'ps_${DateTime.now().microsecondsSinceEpoch}_$i' : s.id;
        final stepToSave = _copyWith(s, id: persistedId, stepOrder: i + 1);
        if (isNew) {
          await service.addPouringStep(stepToSave);
        } else {
          await service.updatePouringStep(stepToSave);
        }
        persistedSteps.add(stepToSave);
      }

      final currentIds = persistedSteps.map((s) => s.id).toSet();
      final removedIds = _originalSteps.map((s) => s.id).where((id) => !currentIds.contains(id));
      for (final removedId in removedIds) {
        await service.deletePouringStep(removedId);
      }

      ref.invalidate(methodMasterProvider);
      ref.invalidate(pouringStepsProvider);

      if (!mounted) return;
      setState(() {
        _selectedMethod = method;
        _workingSteps = persistedSteps.map(_cloneStep).toList();
        _originalSteps = persistedSteps.map(_cloneStep).toList();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('「${method.name}」を更新しました')),
      );
    } catch (e) {
      debugPrint('[Antigravity] Error: 030からのメソッド上書き保存に失敗 $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存に失敗しました: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _finishAndEvaluate() {
    final method = _selectedMethod;
    if (method == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('メソッドを選択してください')));
      return;
    }

    final currentWeight = _currentWeight;
    double totalWater = 0.0;
    int totalTime = 0;
    double bloomingWater = 0.0;
    int bloomingTime = 0;

    for (var i = 0; i < _workingSteps.length; i++) {
      final s = _workingSteps[i];
      final amt = _stepAmount(s);
      totalWater += amt;
      totalTime += s.duration;
      if (i == 0) {
        bloomingWater = amt;
        bloomingTime = s.duration;
      }
    }

    final info = PendingBrewInfo(
      brewedAt: DateTime.now(),
      method: method,
      beanWeight: currentWeight,
      totalWater: totalWater,
      totalTime: totalTime,
      bloomingWater: bloomingWater,
      bloomingTime: bloomingTime,
    );

    debugPrint(
        '[Antigravity] 030→031 遷移: 抽出情報を引き継ぎ (${info.beanWeight}g, ${info.totalWater.toStringAsFixed(1)}ml, ${info.totalTime}s)');
    Navigator.push(context, MaterialPageRoute(builder: (_) => BrewEvaluationScreen(info: info)));
  }

  @override
  Widget build(BuildContext context) {
    final methodsAsync = ref.watch(methodMasterProvider);
    final stepsAsync = ref.watch(pouringStepsProvider);

    return MockScreenScaffold(
      screen: AppScreen.brewRecipe,
      maxWidth: 560,
      children: [
        FormSection(
          icon: Icons.tune,
          title: 'レシピ選択',
          children: [
            methodsAsync.when(
              data: (methods) {
                if (!_hasInitializedFromArgs &&
                    widget.initialMethodId != null &&
                    stepsAsync.hasValue) {
                  final target = methods.where((m) => m.id == widget.initialMethodId);
                  if (target.isNotEmpty) {
                    _hasInitializedFromArgs = true;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) _onMethodChanged(target.first, stepsAsync.value!);
                    });
                  }
                }
                return DropdownButtonFormField<MethodMaster>(
                  decoration: const InputDecoration(labelText: 'メソッド'),
                  value: _selectedMethod,
                  isExpanded: true,
                  items: [
                    for (final m in methods)
                      DropdownMenuItem(value: m, child: Text(m.name, overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (val) {
                    stepsAsync.whenData((allSteps) => _onMethodChanged(val, allSteps));
                  },
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, s) => Text('メソッド読み込みエラー: $e'),
            ),
            const SizedBox(height: 12),
            MockTextField(
              label: '豆量',
              suffix: 'g',
              hint: '20',
              keyboardType: TextInputType.number,
              controller: _beanWeightController,
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
        // タイマー(T2-3b)
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: kEspresso,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                _formatTimerUI(_stopwatch.elapsedMilliseconds),
                style: const TextStyle(
                  color: kCream,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    iconSize: 44,
                    color: kAccent,
                    icon: Icon(_stopwatch.isRunning
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_fill),
                    onPressed: _toggleTimer,
                  ),
                  IconButton(
                    iconSize: 36,
                    color: kLatte,
                    icon: const Icon(Icons.replay),
                    onPressed: _resetTimer,
                  ),
                ],
              ),
            ],
          ),
        ),
        FormSection(
          icon: Icons.water_drop_outlined,
          title: 'Pouring Steps (経過時間で現在のステップを強調)',
          children: [
            if (_selectedMethod == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('メソッドを選択してください', style: TextStyle(color: kMocha)),
              )
            else
              MethodStepsEditor(
                initialSteps: _workingSteps,
                isEditing: true,
                baseBeanWeight: _currentWeight,
                activeStepIndex: _activeStepIndex,
                onStepsChanged: (newSteps) => _workingSteps = newSteps,
              ),
            if (_selectedMethod != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: _isSaving ? null : _showSaveDialog,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined, size: 18),
                  label: const Text('メソッドを保存'),
                ),
              ),
            ],
          ],
        ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _finishAndEvaluate,
            icon: const Icon(Icons.star),
            label: const Text('抽出を終えて評価へ (031)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  String _formatTimerUI(int milliseconds) {
    final minutes = (milliseconds ~/ 60000).toString().padLeft(2, '0');
    final seconds = ((milliseconds % 60000) ~/ 1000).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
