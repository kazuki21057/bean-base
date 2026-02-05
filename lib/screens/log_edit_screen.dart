import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/coffee_record.dart';
import '../providers/data_providers.dart';
import '../services/sheets_service.dart';

class LogEditScreen extends ConsumerStatefulWidget {
  final CoffeeRecord log;

  const LogEditScreen({super.key, required this.log});

  @override
  ConsumerState<LogEditScreen> createState() => _LogEditScreenState();
}

class _LogEditScreenState extends ConsumerState<LogEditScreen> {
  late DateTime _brewedAt;
  late TextEditingController _beanWeightController;
  late TextEditingController _waterAmountController;
  late TextEditingController _tempController;
  late TextEditingController _timeController;
  late TextEditingController _grindSizeController;
  late TextEditingController _commentController;
  
  // Scores
  late int _scoreFragrance;
  late int _scoreAcidity;
  late int _scoreBitterness;
  late int _scoreSweetness;
  late int _scoreComplexity;
  late int _scoreFlavor;
  late int _scoreOverall;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final log = widget.log;
    _brewedAt = log.brewedAt;
    _beanWeightController = TextEditingController(text: log.beanWeight.toString());
    _waterAmountController = TextEditingController(text: log.totalWater.toString());
    _tempController = TextEditingController(text: log.temperature.toString());
    _timeController = TextEditingController(text: log.totalTime.toString());
    _grindSizeController = TextEditingController(text: log.grindSize);
    _commentController = TextEditingController(text: log.comment);

    _scoreFragrance = log.scoreFragrance;
    _scoreAcidity = log.scoreAcidity;
    _scoreBitterness = log.scoreBitterness;
    _scoreSweetness = log.scoreSweetness;
    _scoreComplexity = log.scoreComplexity;
    _scoreFlavor = log.scoreFlavor;
    _scoreOverall = log.scoreOverall;
  }

  @override
  void dispose() {
    _beanWeightController.dispose();
    _waterAmountController.dispose();
    _tempController.dispose();
    _timeController.dispose();
    _grindSizeController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final updatedLog = widget.log.copyWith(
        brewedAt: _brewedAt,
        beanWeight: double.tryParse(_beanWeightController.text) ?? widget.log.beanWeight,
        totalWater: double.tryParse(_waterAmountController.text) ?? widget.log.totalWater,
        temperature: double.tryParse(_tempController.text) ?? widget.log.temperature,
        totalTime: int.tryParse(_timeController.text) ?? widget.log.totalTime,
        grindSize: _grindSizeController.text,
        comment: _commentController.text,
        scoreFragrance: _scoreFragrance,
        scoreAcidity: _scoreAcidity,
        scoreBitterness: _scoreBitterness,
        scoreSweetness: _scoreSweetness,
        scoreComplexity: _scoreComplexity,
        scoreFlavor: _scoreFlavor,
        scoreOverall: _scoreOverall,
      );

      await ref.read(sheetsServiceProvider).updateCoffeeRecord(updatedLog);
      
      // Refresh logs
      ref.invalidate(coffeeRecordsProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Log updated')));
        Navigator.pop(context); // Close Edit
        Navigator.pop(context); // Close Detail (optional, or rely on nav stack)
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _brewedAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_brewedAt),
      );
      if (time != null) {
        setState(() {
          _brewedAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Log'),
        actions: [
          IconButton(
            icon: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.save),
            onPressed: _save,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              title: const Text('Date & Time'),
              subtitle: Text('${_brewedAt.year}/${_brewedAt.month}/${_brewedAt.day} ${_brewedAt.hour}:${_brewedAt.minute.toString().padLeft(2,'0')}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDateTime,
            ),
            const Divider(),
            _buildSection('Parameters', [
              _buildNumField(_beanWeightController, 'Bean Weight (g)'),
              _buildNumField(_waterAmountController, 'Water Amount (ml)'),
              _buildNumField(_tempController, 'Temperature (°C)'),
              _buildNumField(_timeController, 'Time (sec)'),
              _buildTextField(_grindSizeController, 'Grind Size'),
              _buildTextField(_commentController, 'Comment', maxLines: 3),
            ]),
            const SizedBox(height: 16),
            _buildSection('Scores', [
              _buildScoreSlider('Fragrance', _scoreFragrance, (v) => setState(() => _scoreFragrance = v)),
              _buildScoreSlider('Acidity', _scoreAcidity, (v) => setState(() => _scoreAcidity = v)),
              _buildScoreSlider('Bitterness', _scoreBitterness, (v) => setState(() => _scoreBitterness = v)),
              _buildScoreSlider('Sweetness', _scoreSweetness, (v) => setState(() => _scoreSweetness = v)),
              _buildScoreSlider('Complexity', _scoreComplexity, (v) => setState(() => _scoreComplexity = v)),
              _buildScoreSlider('Flavor', _scoreFlavor, (v) => setState(() => _scoreFlavor = v)),
              _buildScoreSlider('Overall', _scoreOverall, (v) => setState(() => _scoreOverall = v)),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildNumField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
    );
  }
  
  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        maxLines: maxLines,
      ),
    );
  }

  Widget _buildScoreSlider(String label, int value, Function(int) onChanged) {
    return Row(
      children: [
        SizedBox(width: 80, child: Text(label)),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: 0,
            max: 10,
            divisions: 10,
            label: value.toString(),
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
        Text(value.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
