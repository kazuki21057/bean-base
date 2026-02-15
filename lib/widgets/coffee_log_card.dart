import 'package:flutter/material.dart';
import '../models/coffee_record.dart';
import '../screens/log_detail_screen.dart';

class CoffeeLogCard extends StatelessWidget {
  final CoffeeRecord log;
  final String beanName;
  final String methodName;

  const CoffeeLogCard({
    super.key,
    required this.log,
    required this.beanName,
    required this.methodName,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(beanName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text(log.brewedAt.toString().split(' ')[0]),
             Text('Method: $methodName'),
          ],
        ),
        trailing: CircleAvatar(
          backgroundColor: _getScoreColor(log.scoreOverall),
          child: Text(log.scoreOverall.toString()),
        ),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => LogDetailScreen(log: log)));
        },
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 8) return Colors.greenAccent;
    if (score >= 6) return Colors.lightGreen;
    if (score >= 4) return Colors.yellow;
    return Colors.orange;
  }
}
