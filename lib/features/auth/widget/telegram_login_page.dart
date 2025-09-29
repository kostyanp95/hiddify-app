import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hiddify/features/auth/notifier/telegram_auth_controller.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class TelegramLoginPage extends ConsumerWidget {
  const TelegramLoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(telegramAuthControllerProvider, (previous, next) {
      if (next.hasError) {
        final error = next.error;
        final message =
            error is TelegramAuthException ? error.message : 'Ошибка авторизации через Telegram';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    });

    final authState = ref.watch(telegramAuthControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.telegram, size: 64),
                  const SizedBox(height: 24),
                  Text(
                    'Войдите через Telegram',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Для продолжения откройте Telegram, подтвердите вход и вернитесь в приложение по ссылке.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  if (isLoading)
                    const CircularProgressIndicator()
                  else
                    ElevatedButton(
                      onPressed: () {
                        unawaited(ref.read(telegramAuthControllerProvider.notifier).startLogin());
                      },
                      child: const Text('Войти через Telegram'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
