import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The UI language: 'en' or 'th'. The choice is kept on the device.
final AsyncNotifierProvider<LanguageNotifier, String> languageProvider =
    AsyncNotifierProvider<LanguageNotifier, String>(LanguageNotifier.new);

class LanguageNotifier extends AsyncNotifier<String> {
  static const String storeKey = 'sst.language';

  /// The language of the first launch. The Figma frames are in English.
  static const String firstLanguage = 'en';

  @override
  Future<String> build() async => (await SharedPreferences.getInstance()).getString(storeKey) ?? firstLanguage;

  Future<void> change(String language) async {
    state = AsyncData<String>(language);
    await (await SharedPreferences.getInstance()).setString(storeKey, language);
  }
}
