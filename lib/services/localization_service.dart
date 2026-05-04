import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================================
// LOCALIZATION SERVICE
// ============================================================================

/// Service untuk mengelola localization/multi-language
class LocalizationService {
  static const String _languageKey = 'selected_language';
  static const String _defaultLanguage = 'id';

  static Map<String, String> _localizedStrings = {};
  static String _currentLanguage = _defaultLanguage;

  /// Load translations untuk bahasa tertentu
  static Future<void> loadLanguage(String languageCode) async {
    _currentLanguage = languageCode;

    String jsonString = await rootBundle.loadString('assets/translations/$languageCode.json');
    Map<String, dynamic> jsonMap = json.decode(jsonString);

    _localizedStrings = jsonMap.map((key, value) {
      return MapEntry(key, value.toString());
    });

    // Save selected language
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
  }

  /// Get localized string
  static String translate(String key, {List<String>? args}) {
    String translation = _localizedStrings[key] ?? key;

    if (args != null && args.isNotEmpty) {
      for (int i = 0; i < args.length; i++) {
        translation = translation.replaceAll('{$i}', args[i]);
      }
    }

    return translation;
  }

  /// Get current language
  static String get currentLanguage => _currentLanguage;

  /// Get available languages
  static List<Map<String, String>> get availableLanguages => [
    {'code': 'id', 'name': 'Bahasa Indonesia', 'flag': '🇮🇩'},
    {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
  ];

  /// Initialize localization
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString(_languageKey) ?? _defaultLanguage;
    await loadLanguage(savedLanguage);
  }

  /// Change language
  static Future<void> changeLanguage(String languageCode) async {
    await loadLanguage(languageCode);
  }

  /// Get language info by code
  static Map<String, String>? getLanguageInfo(String code) {
    return availableLanguages.firstWhere(
      (lang) => lang['code'] == code,
      orElse: () => {'code': 'id', 'name': 'Bahasa Indonesia', 'flag': '🇮🇩'},
    );
  }
}

// ============================================================================
// LOCALIZATION EXTENSIONS
// ============================================================================

/// Extension untuk BuildContext untuk akses localization
extension LocalizationExtension on BuildContext {
  String tr(String key, {List<String>? args}) {
    return LocalizationService.translate(key, args: args);
  }
}

/// Extension untuk String untuk akses localization
extension StringLocalizationExtension on String {
  String tr(BuildContext context, {List<String>? args}) {
    return LocalizationService.translate(this, args: args);
  }
}

// ============================================================================
// LOCALIZED APP
// ============================================================================

/// Wrapper widget untuk localization
class LocalizedApp extends StatefulWidget {
  final Widget child;

  const LocalizedApp({super.key, required this.child});

  @override
  State<LocalizedApp> createState() => _LocalizedAppState();
}

class _LocalizedAppState extends State<LocalizedApp> {
  @override
  void initState() {
    super.initState();
    LocalizationService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

// ============================================================================
// LANGUAGE DROPDOWN WIDGET
// ============================================================================

/// Widget dropdown untuk memilih bahasa
class LanguageDropdown extends StatefulWidget {
  final Function(String)? onLanguageChanged;

  const LanguageDropdown({super.key, this.onLanguageChanged});

  @override
  State<LanguageDropdown> createState() => _LanguageDropdownState();
}

class _LanguageDropdownState extends State<LanguageDropdown> {
  String _selectedLanguage = LocalizationService.currentLanguage;

  @override
  Widget build(BuildContext context) {
    final languages = LocalizationService.availableLanguages;

    return DropdownButtonFormField<String>(
      initialValue: _selectedLanguage,
      decoration: InputDecoration(
        labelText: context.tr('language'),
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.language),
      ),
      items: languages.map((language) {
        return DropdownMenuItem<String>(
          value: language['code'],
          child: Row(
            children: [
              Text(language['flag']!),
              const SizedBox(width: 8),
              Text(language['name']!),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) async {
        if (value != null && value != _selectedLanguage) {
          setState(() {
            _selectedLanguage = value;
          });

          await LocalizationService.changeLanguage(value);

          widget.onLanguageChanged?.call(value);

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('success')),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
    );
  }
}