import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/method_master.dart';
import '../../models/pouring_step.dart';
import '../../providers/data_providers.dart';
import '../../routing/app_screen.dart';
import '../../services/data_service.dart';
import '../../widgets/method_steps_editor.dart';
import 'create_form_widgets.dart';

/// 021 新規メソッド / 020 詳細からの編集フォーム。
///
/// Cycle 20 T1-5d: UIモック(見た目のみ)から DataService に接続した本実装へ
/// 置き換え。[editData] を渡すと編集モードになり、既存の注湯ステップも
/// MethodStepsEditor で読み込んで編集できる(旧 method_detail_screen.dart の
/// インライン編集をやめ、他マスターと同じ「詳細→編集画面へ遷移」方式に統一)。
/// Cycle 20 T2-4b: [prefillFrom]/[prefillSteps] を渡すと、030(抽出レシピ)の
/// 「新規として保存」から基準値・Pouring Stepsを引き継いだ新規登録フォーム
/// になる。[editData]と異なり常に新規メソッドとして登録される(既存メソッドの
/// 上書きにはならない)。
class MethodCreateScreen extends ConsumerStatefulWidget {
  final MethodMaster? editData;
  final MethodMaster? prefillFrom;
  final List<PouringStep>? prefillSteps;

  const MethodCreateScreen({
    super.key,
    this.editData,
    this.prefillFrom,
    this.prefillSteps,
  });

  @override
  ConsumerState<MethodCreateScreen> createState() => _MethodCreateScreenState();
}

class _MethodCreateScreenState extends ConsumerState<MethodCreateScreen> {
  final _nameController = TextEditingController();
  final _authorController = TextEditingController();
  final _urlController = TextEditingController();
  final _descController = TextEditingController();
  final _beanWeightController = TextEditingController();
  final _waterAmountController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _grindSizeController = TextEditingController();
  final _equipmentController = TextEditingController();

  List<PouringStep> _originalSteps = [];
  List<PouringStep> _steps = [];
  bool _isSaving = false;
  bool _stepsLoaded = false;

  bool get _isEdit => widget.editData != null;

  @override
  void initState() {
    super.initState();
    final edit = widget.editData ?? widget.prefillFrom;
    _nameController.text = edit?.name ?? '';
    _authorController.text = edit?.author ?? '';
    _urlController.text = edit?.sourceUrl ?? '';
    _descController.text = edit?.description ?? '';
    _beanWeightController.text =
        (edit == null || edit.baseBeanWeight == 0) ? '' : edit.baseBeanWeight.toStringAsFixed(1);
    _waterAmountController.text =
        (edit == null || edit.baseWaterAmount == 0) ? '' : edit.baseWaterAmount.toStringAsFixed(1);
    _temperatureController.text =
        (edit?.temperature == null || edit!.temperature == 0) ? '' : edit.temperature!.toStringAsFixed(1);
    _grindSizeController.text = edit?.grindSize ?? '';
    _equipmentController.text = edit?.recommendedEquipment ?? '';
    if (!_isEdit) {
      // prefillSteps は永続化済みの他メソッドのステップを複製したものなので、
      // 元のIDのまま _submit() に渡すと updatePouringStep で元メソッド側の
      // データを書き換えてしまう。必ず 'new_' プレフィックスの未保存IDに
      // 差し替えてから複製する。
      final prefill = widget.prefillSteps;
      if (prefill != null && prefill.isNotEmpty) {
        _steps = [
          for (var i = 0; i < prefill.length; i++)
            PouringStep(
              id: 'new_${DateTime.now().microsecondsSinceEpoch}_$i',
              methodId: 'temp',
              stepOrder: prefill[i].stepOrder,
              duration: prefill[i].duration,
              waterAmount: prefill[i].waterAmount,
              waterReference: prefill[i].waterReference,
              waterRatio: prefill[i].waterRatio,
              description: prefill[i].description,
            ),
        ];
      }
      _stepsLoaded = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _authorController.dispose();
    _urlController.dispose();
    _descController.dispose();
    _beanWeightController.dispose();
    _waterAmountController.dispose();
    _temperatureController.dispose();
    _grindSizeController.dispose();
    _equipmentController.dispose();
    super.dispose();
  }

  void _loadStepsIfNeeded(List<PouringStep> methodSteps) {
    _originalSteps = methodSteps;
    _steps = List.from(methodSteps);
    _stepsLoaded = true;
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('メソッド名を入力してください')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final id = _isEdit ? widget.editData!.id : DateTime.now().millisecondsSinceEpoch.toString();
    final method = MethodMaster(
      id: id,
      name: name,
      author: _authorController.text.trim(),
      baseBeanWeight: double.tryParse(_beanWeightController.text) ?? 0.0,
      baseWaterAmount: double.tryParse(_waterAmountController.text) ?? 0.0,
      temperature: double.tryParse(_temperatureController.text),
      grindSize: _grindSizeController.text.trim().isEmpty ? null : _grindSizeController.text.trim(),
      description: _descController.text.trim(),
      recommendedEquipment: _equipmentController.text.trim(),
      sourceUrl: _urlController.text.trim().isEmpty ? null : _urlController.text.trim(),
    );

    try {
      final service = ref.read(dataServiceProvider);
      if (_isEdit) {
        await service.updateMethod(method);
        debugPrint('[Antigravity] Action: メソッド更新 (id=${method.id})');
      } else {
        await service.addMethod(method);
        debugPrint('[Antigravity] Action: メソッド登録 (id=${method.id})');
      }

      for (final step in _steps) {
        final stepForMethod = PouringStep(
          id: step.id,
          methodId: method.id,
          stepOrder: step.stepOrder,
          duration: step.duration,
          waterAmount: step.waterAmount,
          waterReference: step.waterReference,
          waterRatio: step.waterRatio,
          description: step.description,
        );
        if (step.id.startsWith('new_')) {
          await service.addPouringStep(stepForMethod);
        } else {
          await service.updatePouringStep(stepForMethod);
        }
      }
      final currentIds = _steps.map((s) => s.id).toSet();
      final removedIds = _originalSteps.map((s) => s.id).where((id) => !currentIds.contains(id));
      for (final removedId in removedIds) {
        await service.deletePouringStep(removedId);
      }

      ref.invalidate(methodMasterProvider);
      ref.invalidate(pouringStepsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEdit ? 'メソッドを更新しました' : 'メソッドを登録しました')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('[Antigravity] Error: メソッド保存に失敗 $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存に失敗しました: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isEdit) {
      ref.listen<AsyncValue<List<PouringStep>>>(pouringStepsProvider, (prev, next) {
        if (next.hasValue && !_stepsLoaded) {
          final methodSteps = next.value!.where((s) => s.methodId == widget.editData!.id).toList()
            ..sort((a, b) => a.stepOrder.compareTo(b.stepOrder));
          setState(() => _loadStepsIfNeeded(methodSteps));
        }
      });

      if (!_stepsLoaded) {
        final asyncSteps = ref.watch(pouringStepsProvider);
        if (asyncSteps.hasValue) {
          final methodSteps = asyncSteps.value!.where((s) => s.methodId == widget.editData!.id).toList()
            ..sort((a, b) => a.stepOrder.compareTo(b.stepOrder));
          _loadStepsIfNeeded(methodSteps);
        }
      }
    }

    return CreateFormScaffold(
      screen: AppScreen.methodNew,
      title: _isEdit ? 'メソッド編集' : null,
      saveLabel: _isEdit ? 'メソッドを更新する' : 'メソッドを登録する',
      onSave: _submit,
      disabled: _isSaving,
      children: [
        FormSection(
          icon: Icons.menu_book_outlined,
          title: '基本情報',
          children: [
            MockTextField(
              label: 'メソッド名',
              hint: '例: 4:6メソッド',
              required: true,
              controller: _nameController,
            ),
            MockTextField(label: '発案者', hint: '例: 粕谷 哲', controller: _authorController),
            MockTextField(label: '参考URL', hint: 'https://...', controller: _urlController),
            MockTextField(
              label: '説明',
              hint: 'メソッドの狙い・特徴',
              maxLines: 3,
              controller: _descController,
            ),
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
              controller: _beanWeightController,
            ),
            MockTextField(
              label: '基準湯量',
              suffix: 'g',
              hint: '300',
              keyboardType: TextInputType.number,
              controller: _waterAmountController,
            ),
            MockTextField(
              label: '湯温',
              suffix: '℃',
              hint: '92',
              keyboardType: TextInputType.number,
              controller: _temperatureController,
            ),
            MockTextField(label: '推奨挽き目', hint: '例: 中粗挽き', controller: _grindSizeController),
            MockTextField(label: '推奨器具', hint: '例: V60 + ペーパー', controller: _equipmentController),
          ],
        ),
        FormSection(
          icon: Icons.water_drop_outlined,
          title: '注湯ステップ (Pouring Steps)',
          children: [
            if (_isEdit && !_stepsLoaded)
              const Center(child: CircularProgressIndicator())
            else
              MethodStepsEditor(
                initialSteps: _steps,
                isEditing: true,
                baseBeanWeight: double.tryParse(_beanWeightController.text) ?? 15.0,
                onStepsChanged: (newSteps) => _steps = newSteps,
              ),
          ],
        ),
      ],
    );
  }
}
