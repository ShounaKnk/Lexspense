import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LawyerProfile {
  final String lawyerName;
  final String firmName;

  const LawyerProfile({
    this.lawyerName = 'Advocate',
    this.firmName = 'Chambers of Law',
  });

  LawyerProfile copyWith({String? lawyerName, String? firmName}) {
    return LawyerProfile(
      lawyerName: lawyerName ?? this.lawyerName,
      firmName: firmName ?? this.firmName,
    );
  }
}

class SettingsNotifier extends StateNotifier<AsyncValue<LawyerProfile>> {
  SettingsNotifier() : super(const AsyncValue.loading()) {
    _load();
  }

  static const _keyLawyerName = 'lawyer_name';
  static const _keyFirmName = 'firm_name';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString(_keyLawyerName) ?? 'Advocate';
      final firm = prefs.getString(_keyFirmName) ?? 'Chambers of Law';
      state = AsyncValue.data(LawyerProfile(lawyerName: name, firmName: firm));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateProfile({required String lawyerName, required String firmName}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLawyerName, lawyerName);
    await prefs.setString(_keyFirmName, firmName);
    state = AsyncValue.data(LawyerProfile(lawyerName: lawyerName, firmName: firmName));
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AsyncValue<LawyerProfile>>((ref) {
  return SettingsNotifier();
});
