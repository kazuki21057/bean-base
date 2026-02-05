import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/data_providers.dart';
import '../models/method_master.dart';
import '../models/pouring_step.dart';
import '../models/coffee_record.dart'; // Add
import '../models/bean_master.dart'; // Add
import '../models/equipment_masters.dart'; // Add
import '../services/sheets_service.dart'; // Add

class CalculatorScreen extends ConsumerStatefulWidget {
  final String? initialMethodId;
  final double? initialBeanWeight;

  const CalculatorScreen({
    super.key, 
    this.initialMethodId, 
    this.initialBeanWeight,
  });

  @override
  ConsumerState<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends ConsumerState<CalculatorScreen> {
  MethodMaster? _selectedMethod;
  final TextEditingController _beanWeightController = TextEditingController();
  
  // Equipment
  BeanMaster? _selectedBean; // Add
  GrinderMaster? _selectedGrinder;
  DripperMaster? _selectedDripper;
  FilterMaster? _selectedFilter;

  // Brew Date
  DateTime _brewedAt = DateTime.now();

  // Evaluation
  final Map<String, int> _scores = {
    'Fragrance': 5,
    'Acidity': 5,
    'Bitterness': 5,
    'Sweetness': 5,
    'Complexity': 5,
    'Flavor': 5,
    'Overall': 5,
  };
  final TextEditingController _notesController = TextEditingController();

  // Working copy of steps for editing
  List<PouringStep> _workingSteps = [];
  bool _isEditing = false;
  bool _hasInitializedFromArgs = false;

  // Timer
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _beanWeightController.text = (widget.initialBeanWeight ?? 15).toString();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _beanWeightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onMethodChanged(MethodMaster? method, List<PouringStep> allSteps) {
    if (method == null) {
      setState(() {
        _selectedMethod = null;
        _workingSteps = [];
      });
      return;
    }

    final methodSteps = allSteps.where((s) => s.methodId == method.id).toList();
    methodSteps.sort((a, b) => a.stepOrder.compareTo(b.stepOrder));

    setState(() {
      _selectedMethod = method;
      _beanWeightController.text = method.baseBeanWeight.toString();
      // Clone steps to isolate from provider
      _workingSteps = methodSteps.map((s) => PouringStep(
        id: s.id,
        methodId: s.methodId,
        stepOrder: s.stepOrder,
        duration: s.duration,
        waterAmount: s.waterAmount,
        waterReference: s.waterReference,
        waterRatio: s.waterRatio,
        description: s.description,
      )).toList();
    });
  }

  void _addStep() {
    setState(() {
      _workingSteps.add(PouringStep(
        id: 'new_${DateTime.now().millisecondsSinceEpoch}',
        methodId: _selectedMethod?.id ?? 'temp',
        stepOrder: _workingSteps.length + 1,
        duration: 0,
        waterAmount: 0,
        waterReference: _selectedMethod?.baseBeanWeight ?? 15.0,
        description: '',
      ));
    });
  }

  void _removeStep(int index) {
    setState(() {
      _workingSteps.removeAt(index);
      _reindexSteps();
    });
  }

  void _moveStep(int index, int direction) {
    final newIndex = index + direction;
    if (newIndex < 0 || newIndex >= _workingSteps.length) return;

    setState(() {
      final temp = _workingSteps[index];
      _workingSteps[index] = _workingSteps[newIndex];
      _workingSteps[newIndex] = temp;
      _reindexSteps();
    });
  }

  void _reindexSteps() {
    for(var i=0; i<_workingSteps.length; i++) {
        _workingSteps[i] = _copyWith(_workingSteps[i], stepOrder: i + 1);
    }
  }
  
  PouringStep _copyWith(PouringStep s, {int? stepOrder, double? waterAmount, int? duration, String? description, double? waterRatio}) {
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

  // Timer Methods
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

  Future<void> _showSaveDialog() async {
    // Check if we have a method selected
    if (_selectedMethod == null && _workingSteps.isNotEmpty) {
    }

    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Method'),
        content: const Text('Do you want to overwrite the current method or save as a new one?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'Overwrite'),
            child: const Text('Overwrite'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'New'),
            child: const Text('Save as New'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'Cancel'),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (choice == 'New') {
      if (!mounted) return;
      final newName = await _promptNewName();
      if (newName != null && newName.isNotEmpty) {
        _save(overwrite: false, newName: newName);
      }
    } else if (choice == 'Overwrite') {
      _save(overwrite: true);
    }
  }

  Future<String?> _promptNewName() async {
    String name = '';
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Method Name'),
        content: TextField(
          onChanged: (v) => name = v,
          decoration: const InputDecoration(hintText: 'Enter name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, name), child: const Text('OK')),
        ],
      ),
    );
  }

  void _save({required bool overwrite, String? newName}) {
    // Determine new Method Details
    final currentWeight = double.tryParse(_beanWeightController.text) ?? 15.0;
    
    final methodId = overwrite ? _selectedMethod?.id : 'NEW_${DateTime.now().millisecondsSinceEpoch}';
    final methodName = overwrite ? _selectedMethod?.name : newName;
    
    // Normalize steps to the Current Weight (which becomes the new Base Weight)
    final oldBase = _selectedMethod?.baseBeanWeight ?? 15.0;
    final factor = oldBase > 0 ? (currentWeight / oldBase) : 1.0;

    final finalSteps = _workingSteps.map((s) {
       double actualAmount = 0.0;
       if (s.waterRatio != null && s.waterRatio! > 0) {
          actualAmount = s.waterRatio! * currentWeight;
       } else {
          // If no ratio, it was scaling by factor
          actualAmount = s.waterAmount * factor;
       }
       
       // Calculate new Ratio (User requester: Register Ratio)
       final newRatio = currentWeight > 0 ? (actualAmount / currentWeight) : 0.0;
       
       return _copyWith(s, 
          waterAmount: actualAmount, 
          waterRatio: newRatio
       );
    }).toList();
    
    print('SAVING METHOD: $methodName ($methodId)');
    print('NEW BASE WEIGHT: $currentWeight');
    print('STEPS (Normalized):');
    for(var s in finalSteps) {
      print('- Order ${s.stepOrder}: ${s.duration}s, ${s.waterAmount.toStringAsFixed(1)}ml (Ratio: ${s.waterRatio?.toStringAsFixed(2)}), "${s.description}"');
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Method "$methodName" saved (Simulated) with Base $currentWeight. Check logs.'))
    );
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _brewedAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      if (!mounted) return;
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
    final methodsAsync = ref.watch(methodMasterProvider);
    final stepsAsync = ref.watch(pouringStepsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Brewing Calculator')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Method Selector
            methodsAsync.when(
              data: (methods) {
                // Initial load from args
                if (!_hasInitializedFromArgs && widget.initialMethodId != null && stepsAsync.hasValue) {
                   final target = methods.firstWhere(
                     (m) => m.id == widget.initialMethodId, 
                     orElse: () => methods.first 
                   );
                   if (target.id == widget.initialMethodId) { 
                      _hasInitializedFromArgs = true;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                         _onMethodChanged(target, stepsAsync.value!);
                      });
                   }
                }

                return DropdownButton<MethodMaster>(
                hint: const Text('Select Method'),
                value: _selectedMethod,
                isExpanded: true,
                items: methods.map((m) {
                  return DropdownMenuItem(
                    value: m,
                    child: Text(m.name),
                  );
                }).toList(),
                onChanged: (val) {
                  stepsAsync.whenData((allSteps) {
                     _onMethodChanged(val, allSteps);
                  });
                },
              );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, s) => Text('Error loading methods: $e'),
            ),
            const SizedBox(height: 16),
            
            // Bean Weight Input
            TextField(
              controller: _beanWeightController,
              decoration: const InputDecoration(
                labelText: 'Bean Weight (g)',
                border: OutlineInputBorder(),
                suffixText: 'g',
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Timer (Inline)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.brown.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.brown.shade200),
              ),
              child: Column(
                children: [
                  Text(
                    _formatTimerUI(_stopwatch.elapsedMilliseconds),
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.brown),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _toggleTimer,
                        style: ElevatedButton.styleFrom(backgroundColor: _stopwatch.isRunning ? Colors.orange : Colors.green),
                        child: Text(_stopwatch.isRunning ? 'Stop' : 'Start'),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton(
                        onPressed: _resetTimer,
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Collapsible Table
            ExpansionTile(
              title: const Text('Pouring Steps', style: TextStyle(fontWeight: FontWeight.bold)),
              initiallyExpanded: true, // Auto expand relevant
              children: [
                SingleChildScrollView( // Horizontal scroll
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('#')),
                      DataColumn(label: Text('Time (Start)')),
                      DataColumn(label: Text('Total Weight (g)')), 
                      DataColumn(label: Text('Description')),
                      DataColumn(label: Text('Action')),
                    ],
                    rows: _buildRows(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _addStep,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Step'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _workingSteps.isEmpty ? null : _showSaveDialog,
                        icon: const Icon(Icons.save),
                        label: const Text('Save'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32, thickness: 2),

            // Log Preparation Section
            Text('Log Details', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
             // Date Picker
            InkWell(
              onTap: _pickDateTime,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Brewed At',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  '${_brewedAt.year}/${_brewedAt.month}/${_brewedAt.day} ${_brewedAt.hour}:${_brewedAt.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildEquipmentSection(ref),
            const Divider(),
            _buildEvaluationSection(),
            const Divider(),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _logThisBrew,
                icon: const Icon(Icons.check),
                label: const Text('Log this Brew (Preview)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<DataRow> _buildRows() {
    final currentWeight = double.tryParse(_beanWeightController.text) ?? 15.0;
    final baseWeight = _selectedMethod?.baseBeanWeight ?? 15.0;
    final factor = baseWeight > 0 ? (currentWeight / baseWeight) : 1.0;

    int cumulativeTime = 0;
    double cumulativeTotal = 0.0;
    final elapsedSec = _stopwatch.elapsedMilliseconds / 1000;
    
    return _workingSteps.asMap().entries.map((entry) {
      final index = entry.key;
      final step = entry.value;

      // Start Time (Prior cumulative)
      final startTime = cumulativeTime;
      
      // Calculate
      double stepAmount = 0.0;
      if (step.waterRatio != null && step.waterRatio! > 0) {
        stepAmount = step.waterRatio! * currentWeight;
      } else {
        stepAmount = step.waterAmount * factor;
      }
      cumulativeTotal += stepAmount;
      final currentTotal = cumulativeTotal; 

      cumulativeTime += step.duration;
      final endTime = cumulativeTime;

      // Highlighting Logic: Current time is between startTime and endTime
      final isActive = _stopwatch.isRunning && elapsedSec >= startTime && elapsedSec < endTime;

      return DataRow(
        color: MaterialStateProperty.resolveWith((states) {
            return isActive ? Colors.yellow.shade100 : null;
        }),
        cells: [
        DataCell(Text(step.stepOrder.toString())),
        // Time (Start Time)
        DataCell(TextFormField(
          initialValue: _formatTime(startTime),
          keyboardType: TextInputType.datetime,
          onFieldSubmitted: (v) {
            // Edit Start Time logic
            if (index == 0) return; 

            final val = _parseTime(v);
            if (val != null) {
              // Get previous step's start time
              int prevStepStartTime = 0;
              for(int i=0; i<index-1; i++) {
                prevStepStartTime += _workingSteps[i].duration;
              }
              
              // New duration for Step N-1 = New Start Time of N - Start Time of N-1
              final newDurationPrevStep = val - prevStepStartTime;
              
              if (newDurationPrevStep >= 0) {
                 setState(() {
                    _workingSteps[index-1] = _copyWith(_workingSteps[index-1], duration: newDurationPrevStep);
                 });
              }
            }
          },
        )),
        // Total Weight Cell
        DataCell(TextFormField(
          key: ValueKey('weight_${index}_${currentTotal}'), // Force rebuild on value change
          initialValue: currentTotal.toStringAsFixed(1),
          keyboardType: TextInputType.number,
          onFieldSubmitted: (v) { 
             final val = double.tryParse(v);
             if (val != null) {
               double prevTotal = 0.0;
                for(int i=0; i<index; i++) {
                   final s = _workingSteps[i];
                   double amt = 0.0;
                   if (s.waterRatio != null && s.waterRatio! > 0) {
                     amt = s.waterRatio! * currentWeight;
                   } else {
                     amt = s.waterAmount * factor;
                   }
                   prevTotal += amt;
                }
                final newStepAmount = val - prevTotal;
                if (newStepAmount >= 0) {
                   final newBaseAmount = newStepAmount / factor;
                   setState(() {
                      _workingSteps[index] = _copyWith(step, waterAmount: newBaseAmount, waterRatio: 0.0); 
                   });
                }
             }
          },
        )),
        DataCell(TextFormField(
          initialValue: step.description,
          onChanged: (v) {
             _workingSteps[index] = _copyWith(step, description: v);
          },
        )),
        DataCell(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
             IconButton(
               icon: const Icon(Icons.arrow_upward, size: 20),
               onPressed: index > 0 ? () => _moveStep(index, -1) : null,
             ),
             IconButton(
               icon: const Icon(Icons.arrow_downward, size: 20),
               onPressed: index < _workingSteps.length - 1 ? () => _moveStep(index, 1) : null,
             ),
             IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              onPressed: () => _removeStep(index),
            ),
          ],
        )),
      ]);
    }).toList();
  }
  
  Widget _buildEquipmentSection(WidgetRef ref) {
    final grinders = ref.watch(grinderMasterProvider).valueOrNull ?? [];
    final drippers = ref.watch(dripperMasterProvider).valueOrNull ?? [];
    final filters = ref.watch(filterMasterProvider).valueOrNull ?? [];

    final beans = ref.watch(beanMasterProvider).valueOrNull ?? []; // Fetch beans

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<BeanMaster>( // Add Bean Selector
          decoration: const InputDecoration(labelText: 'Bean'),
          value: _selectedBean,
          isExpanded: true,
          items: beans.where((b) => b.isInStock).map((e) => DropdownMenuItem( // Filter in-stock? Or all? Let's say in-stock or previously selected
            value: e, 
            child: Text(e.name, overflow: TextOverflow.ellipsis)
          )).toList(),
          onChanged: (v) => setState(() => _selectedBean = v),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<GrinderMaster>(
          decoration: const InputDecoration(labelText: 'Grinder'),
          value: _selectedGrinder,
          items: grinders.map((e) => DropdownMenuItem(
            value: e, 
            child: Row(children: [
               if(e.imageUrl != null && e.imageUrl!.isNotEmpty)
                 Padding(padding: const EdgeInsets.only(right: 8), child: Image.network(e.imageUrl!, width: 24, height: 24, fit: BoxFit.cover, errorBuilder: (c,err,s) => const Icon(Icons.broken_image, size: 24))),
               Text(e.name)
            ])
          )).toList(),
          onChanged: (v) => setState(() => _selectedGrinder = v),
        ),
        DropdownButtonFormField<DripperMaster>(
          decoration: const InputDecoration(labelText: 'Dripper'),
          value: _selectedDripper,
           items: drippers.map((e) => DropdownMenuItem(
            value: e, 
            child: Row(children: [
               if(e.imageUrl != null && e.imageUrl!.isNotEmpty)
                 Padding(padding: const EdgeInsets.only(right: 8), child: Image.network(e.imageUrl!, width: 24, height: 24, fit: BoxFit.cover, errorBuilder: (c,err,s) => const Icon(Icons.broken_image, size: 24))),
               Text(e.name)
            ])
          )).toList(),
          onChanged: (v) => setState(() => _selectedDripper = v),
        ),
        DropdownButtonFormField<FilterMaster>(
          decoration: const InputDecoration(labelText: 'Filter'),
          value: _selectedFilter,
           items: filters.map((e) => DropdownMenuItem(
            value: e, 
            child: Row(children: [
               if(e.imageUrl != null && e.imageUrl!.isNotEmpty)
                 Padding(padding: const EdgeInsets.only(right: 8), child: Image.network(e.imageUrl!, width: 24, height: 24, fit: BoxFit.cover, errorBuilder: (c,err,s) => const Icon(Icons.broken_image, size: 24))),
               Text(e.name)
            ])
          )).toList(),
          onChanged: (v) => setState(() => _selectedFilter = v),
        ),
      ],
    );
  }

  Widget _buildEvaluationSection() {
    return Column(
      children: _scores.keys.map((key) {
        return Row(
          children: [
            SizedBox(width: 100, child: Text(key)),
            Expanded(
              child: Slider(
                value: _scores[key]!.toDouble(),
                min: 0,
                max: 10,
                divisions: 10,
                label: _scores[key].toString(),
                onChanged: (v) => setState(() => _scores[key] = v.toInt()),
              ),
            ),
            Text(_scores[key].toString()),
          ],
        );
      }).toList(),
    );
  }

  Future<void> _logThisBrew() async {
    if (_selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a method.')));
      return;
    }
    
    // Calculate final totals
    final currentWeight = double.tryParse(_beanWeightController.text) ?? 15.0;
    final baseWeight = _selectedMethod?.baseBeanWeight ?? 15.0;
    final factor = baseWeight > 0 ? (currentWeight / baseWeight) : 1.0;
    
    double totalWater = 0.0;
    int totalTime = 0;
    double bloomingWater = 0.0;
    int bloomingTime = 0;

    for (var i = 0; i < _workingSteps.length; i++) {
       final s = _workingSteps[i];
       double amt = 0.0;
       if (s.waterRatio != null && s.waterRatio! > 0) {
         amt = s.waterRatio! * currentWeight;
       } else {
         amt = s.waterAmount * factor;
       }
       totalWater += amt;
       totalTime += s.duration;
       
       // Heuristic: First step is blooming
       if (i == 0) {
         bloomingWater = amt;
         bloomingTime = s.duration;
       }
    }

    final record = CoffeeRecord(
      id: 'REC-${DateTime.now().millisecondsSinceEpoch}',
      brewedAt: _brewedAt,
      methodId: _selectedMethod!.id,
      beanId: _selectedBean?.id ?? 'UNKNOWN', 
      beanWeight: currentWeight,
      grinderId: _selectedGrinder?.id ?? '',
      dripperId: _selectedDripper?.id ?? '',
      filterId: _selectedFilter?.id ?? '',
      roastLevel: _selectedBean?.roastLevel ?? '',
      origin: _selectedBean?.origin ?? '',
      grindSize: _selectedMethod!.grindSize ?? '',
      temperature: _selectedMethod!.temperature ?? 0.0,
      taste: '', // Placeholder or add UI input
      concentration: '', // Placeholder or add UI input
      bloomingWater: bloomingWater,
      bloomingTime: bloomingTime,
      totalWater: totalWater,
      totalTime: totalTime,
      scoreFragrance: _scores['Fragrance'] ?? 0,
      scoreAcidity: _scores['Acidity'] ?? 0,
      scoreBitterness: _scores['Bitterness'] ?? 0,
      scoreSweetness: _scores['Sweetness'] ?? 0,
      scoreComplexity: _scores['Complexity'] ?? 0,
      scoreFlavor: _scores['Flavor'] ?? 0,
      scoreOverall: _scores['Overall'] ?? 0,
      comment: _notesController.text,
      // Images not set here (uploaded separately or linked manually? For now optional)
    );

    try {
      // Use sheetsServiceProvider directly
      await ref.read(sheetsServiceProvider).addCoffeeRecord(record);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Brew logged successfully!')));
        Navigator.pop(context); 
      }
      ref.refresh(coffeeRecordsProvider);
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error logging: $e'), backgroundColor: Colors.red));
      }
    }
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
  
  String _formatTimerUI(int milliseconds) {
    final minutes = (milliseconds ~/ 60000).toString().padLeft(2, '0');
    final seconds = ((milliseconds % 60000) ~/ 1000).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  int? _parseTime(String value) {
    if (value.contains(':')) {
      final parts = value.split(':');
      if (parts.length == 2) {
        final m = int.tryParse(parts[0]);
        final s = int.tryParse(parts[1]);
        if (m != null && s != null) return m * 60 + s;
      }
    }
    return int.tryParse(value);
  }
}
