import 'package:flutter/material.dart';
import '../models/pouring_step.dart';

class MethodStepsEditor extends StatefulWidget {
  final List<PouringStep> initialSteps;
  final bool isEditing;
  final double baseBeanWeight;
  final Function(List<PouringStep>) onStepsChanged;

  const MethodStepsEditor({
    super.key,
    required this.initialSteps,
    required this.isEditing,
    this.baseBeanWeight = 15.0,
    required this.onStepsChanged,
  });

  @override
  State<MethodStepsEditor> createState() => _MethodStepsEditorState();
}

class _MethodStepsEditorState extends State<MethodStepsEditor> {
  late List<PouringStep> _steps;

  @override
  void initState() {
    super.initState();
    _steps = List.from(widget.initialSteps);
  }

  @override
  void didUpdateWidget(MethodStepsEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSteps != widget.initialSteps) {
      _steps = List.from(widget.initialSteps);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_steps.isEmpty && !widget.isEditing) {
      return const Text('No steps defined.');
    }

    // Cumulative calc
    int cumulativeTime = 0;
    double cumulativeWater = 0;
    
    final rows = <DataRow>[];
    for (int i = 0; i < _steps.length; i++) {
      final s = _steps[i];
      
      final stepStartTime = cumulativeTime;
      final stepStartWater = cumulativeWater;
      
      final currentDuration = s.duration;
      double currentAmount = 0;
      if (s.waterRatio != null && s.waterRatio! > 0) {
         currentAmount = s.waterRatio! * (widget.baseBeanWeight > 0 ? widget.baseBeanWeight : 15.0);
      } else {
         currentAmount = s.waterAmount;
      }
      
      cumulativeTime += currentDuration;
      cumulativeWater += currentAmount;
      
      final stepEndTime = cumulativeTime;
      final stepEndWater = cumulativeWater;

      rows.add(DataRow(cells: [
         DataCell(Text(s.stepOrder.toString())),
         // Time Column
         DataCell(widget.isEditing 
           ? TextFormField(
               initialValue: _formatTime(stepEndTime),
               keyboardType: TextInputType.datetime,
               onChanged: (v) {
                 final newTotal = _parseTime(v);
                 final newDuration = newTotal - stepStartTime;
                 if (newDuration >= 0) {
                    _updateStep(i, _copyWithStep(s, duration: newDuration));
                 }
               },
             )
           : Text(_formatTime(stepEndTime))), 
         // Water Column
         DataCell(widget.isEditing
            ? TextFormField(
               initialValue: stepEndWater.toStringAsFixed(1),
               keyboardType: TextInputType.number,
               onChanged: (v) {
                  final newTotal = double.tryParse(v);
                  if (newTotal != null) {
                     final newAmount = newTotal - stepStartWater;
                     if (newAmount >= 0) {
                       final ratio = widget.baseBeanWeight > 0 ? newAmount / widget.baseBeanWeight : 0.0;
                       _updateStep(i, _copyWithStep(s, waterAmount: newAmount, waterRatio: ratio));
                     }
                  }
               },
            )
            : Text('${stepEndWater.toStringAsFixed(1)}ml')),
         DataCell(widget.isEditing
            ? TextFormField(
                initialValue: s.description,
                onChanged: (v) => _updateStep(i, _copyWithStep(s, description: v)),
              )
            : Text(s.description)),
         if (widget.isEditing)
           DataCell(Row(
             mainAxisSize: MainAxisSize.min,
             children: [
                IconButton(
                  icon: const Icon(Icons.arrow_upward, size: 20),
                  onPressed: i > 0 ? () => _moveStep(i, -1) : null,
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_downward, size: 20),
                  onPressed: i < _steps.length - 1 ? () => _moveStep(i, 1) : null,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: () => _removeStep(i),
                ),
             ],
           ))
      ]));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: [
              const DataColumn(label: Text('#')),
              DataColumn(label: Text(widget.isEditing ? 'End Time' : 'End Time')),
              DataColumn(label: Text(widget.isEditing ? 'Total Water' : 'Total Water')),
              const DataColumn(label: Text('Description')),
              if (widget.isEditing) const DataColumn(label: Text('Action')),
            ],
            rows: rows,
          ),
        ),
        if (widget.isEditing)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: ElevatedButton.icon(
              onPressed: _addStep,
              icon: const Icon(Icons.add),
              label: const Text('Add Step'),
            ),
          ),
      ],
    );
  }

  void _addStep() {
    final methodId = _steps.isNotEmpty ? _steps.first.methodId : 'temp';
    final newStep = PouringStep(
      id: 'new_${DateTime.now().millisecondsSinceEpoch}',
      methodId: methodId,
      stepOrder: _steps.length + 1,
      duration: 30,
      waterAmount: 30,
      waterReference: widget.baseBeanWeight,
      waterRatio: 0,
      description: '',
    );
    setState(() {
      _steps.add(newStep);
    });
    widget.onStepsChanged(_steps);
  }

  void _removeStep(int index) {
    setState(() {
      _steps.removeAt(index);
      _reindexSteps();
    });
    widget.onStepsChanged(_steps);
  }

  void _moveStep(int index, int direction) {
    final newIndex = index + direction;
    if (newIndex < 0 || newIndex >= _steps.length) return;

    setState(() {
      final temp = _steps[index];
      _steps[index] = _steps[newIndex];
      _steps[newIndex] = temp;
      _reindexSteps();
    });
    widget.onStepsChanged(_steps);
  }
  
  void _updateStep(int index, PouringStep step) {
    setState(() {
      _steps[index] = step;
    });
     widget.onStepsChanged(_steps);
  }

  void _reindexSteps() {
    for(var i=0; i<_steps.length; i++) {
        _steps[i] = _copyWithStep(_steps[i], stepOrder: i + 1);
    }
  }

  PouringStep _copyWithStep(PouringStep s, {int? stepOrder, double? waterAmount, int? duration, String? description, double? waterRatio}) {
    return PouringStep(
      id: s.id, 
      methodId: s.methodId, 
      stepOrder: stepOrder ?? s.stepOrder, 
      duration: duration ?? s.duration, 
      waterAmount: waterAmount ?? s.waterAmount, 
      waterReference: s.waterReference,
      waterRatio: waterRatio ?? s.waterRatio, 
      description: description ?? s.description
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  int _parseTime(String value) {
    if (value.contains(':')) {
      final parts = value.split(':');
      if (parts.length == 2) {
        final m = int.tryParse(parts[0]) ?? 0;
        final s = int.tryParse(parts[1]) ?? 0;
        return m * 60 + s;
      }
    }
    return int.tryParse(value) ?? 0;
  }
}
