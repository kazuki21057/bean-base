import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Mock SharedPreferences for standalone script if needed, 
// but easier to just ask user for key or read from a file if environment setup is complex.
// Since this is a standalone script, I'll pass the key as an argument or hardcode a placeholder to be replaced.
// Wait, I can't easily access SharedPreferences in a standalone script without flutter environment.
// I will create a script that expects the API KEY as an argument.

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart tools/check_gemini_models.dart <API_KEY>');
    exit(1);
  }

  final apiKey = args[0];
  final model = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);

  final buffer = StringBuffer();
  buffer.writeln('Checking available models for API Key: ${apiKey.substring(0, 5)}... (Time: ${DateTime.now()})');

  final modelsToTry = [
    'gemini-1.5-flash',
    'gemini-1.5-flash-latest',
    'gemini-pro',
    'gemini-1.0-pro',
    'gemini-1.5-pro',
  ];

  for (var m in modelsToTry) {
    buffer.writeln('\n----------------------------------------');
    buffer.writeln('Testing model: $m');
    try {
      final genModel = GenerativeModel(model: m, apiKey: apiKey);
      final response = await genModel.generateContent([Content.text('Hello')]);
      buffer.writeln('SUCCESS: Model $m is working.');
      buffer.writeln('Response: ${response.text}');
    } catch (e) {
      buffer.writeln('FAILED: Model $m.');
      buffer.writeln('Error: $e');
    }
  }

  // Determine output path relative to this script
  // If running with `dart tools/check_gemini_models.dart`, Platform.script might point to the script file.
  // Let's safe-guard by using the current working directory, but printing it clearly.
  // Better yet, let's put it in the project root if possible, or just current dir and print absolute path.
  
  final file = File('api_check_result.txt');
  await file.writeAsString(buffer.toString());
  print('----------------------------------------------------------------');
  print('Check complete.');
  print('Results written to: ${file.absolute.path}');
  print('----------------------------------------------------------------');
}
