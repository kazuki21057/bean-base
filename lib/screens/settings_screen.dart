import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'debug/firebase_test_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  bool _isLoading = true;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiKeyController.text = prefs.getString('gemini_api_key') ?? '';
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', _apiKeyController.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings Saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text('Gemini API Key', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _apiKeyController,
              obscureText: _obscureText,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: 'Enter your Gemini API Key',
                suffixIcon: IconButton(
                  icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscureText = !_obscureText),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveSettings,
              child: const Text('Save Settings'),
            ),
            const Divider(height: 40),
            const Text('Debug', style: TextStyle(fontWeight: FontWeight.bold)),
            ListTile(
              leading: const Icon(Icons.cloud_upload),
              title: const Text('Firebase Storage Test'),
              subtitle: const Text('Verify image upload functionality'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FirebaseTestScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
