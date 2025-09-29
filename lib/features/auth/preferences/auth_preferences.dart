import 'package:hiddify/core/utils/preferences_utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_preferences.g.dart';

abstract class AuthPreferences {
  static final telegramAuthToken = PreferencesNotifier.create<String, String>(
    'telegram_auth_token',
    '',
  );
}

@riverpod
String? telegramAuthToken(TelegramAuthTokenRef ref) {
  final rawToken = ref.watch(AuthPreferences.telegramAuthToken);
  if (rawToken.trim().isEmpty) {
    return null;
  }
  return rawToken;
}

@riverpod
bool isAuthorized(IsAuthorizedRef ref) {
  return ref.watch(telegramAuthTokenProvider) != null;
}
