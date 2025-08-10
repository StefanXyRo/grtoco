import 'package:flutter/material.dart';
import 'package:grtoco/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final Map<String, String> languages = {
    'en': 'English',
    'ro': 'Română',
    'de': 'Deutsch',
    'fr': 'Français',
    'es': 'Español',
    'it': 'Italiano',
    'zh': '中文',
    'ko': '한국어',
    'ja': '日本語',
    'ar': 'العربية',
    'hi': 'हिन्दी',
  };

  Future<void> _selectLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', languageCode);
    await prefs.setBool('onboardingComplete', true);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Language'),
      ),
      body: ListView(
        children: languages.entries.map((entry) {
          return ListTile(
            title: Text(entry.value),
            onTap: () => _selectLanguage(entry.key),
          );
        }).toList(),
      ),
    );
  }
}
