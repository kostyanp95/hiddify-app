import 'dart:async';

import 'package:hiddify/features/auth/preferences/auth_preferences.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'telegram_auth_controller.g.dart';

class TelegramAuthException implements Exception {
  TelegramAuthException(this.message);

  final String message;

  @override
  String toString() => 'TelegramAuthException: $message';
}

@riverpod
class TelegramAuthController extends _$TelegramAuthController with AppLogger {
  static const _botUsername = 'HiddifyBot';
  static const _defaultStartParameter = 'app_login';

  @override
  FutureOr<void> build() {}

  Future<bool> startLogin() async {
    state = const AsyncValue.loading();
    const payload = _defaultStartParameter;
    final deepLink = Uri(
      scheme: 'tg',
      host: 'resolve',
      queryParameters: {
        'domain': _botUsername,
        'start': payload,
      },
    );

    final launched = await UriUtils.tryLaunch(deepLink);
    if (!launched) {
      final webFallback = Uri.https('t.me', _botUsername, {
        'start': payload,
      });
      final fallbackLaunched = await UriUtils.tryLaunch(webFallback);
      if (!fallbackLaunched) {
        const message = 'Не удалось открыть Telegram';
        state = AsyncValue.error(TelegramAuthException(message), StackTrace.current);
        return false;
      }
    }

    state = const AsyncValue.data(null);
    return true;
  }

  Future<void> logout() async {
    loggy.debug('Clearing stored Telegram auth token');
    await ref.read(AuthPreferences.telegramAuthToken.notifier).update('');
    state = const AsyncValue.data(null);
  }
}
