import 'dart:async';
import 'dart:io';

import 'package:hiddify/features/auth/preferences/auth_preferences.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:protocol_handler/protocol_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'telegram_auth_link_handler.g.dart';

@Riverpod(keepAlive: true)
class TelegramAuthLinkHandler extends _$TelegramAuthLinkHandler
    with ProtocolListener, InfraLogger {
  static const _supportedSchemes = {'hiddify', 'hiddify-auth'};
  static const _authHost = 'auth';

  @override
  Future<void> build() async {
    if (Platform.isLinux) {
      return;
    }

    for (final protocol in _supportedSchemes) {
      try {
        await protocolHandler.register(protocol);
      } catch (error, stackTrace) {
        loggy.warning('Failed to register protocol [$protocol]', error, stackTrace);
      }
    }

    protocolHandler.addListener(this);
    ref.onDispose(() {
      protocolHandler.removeListener(this);
    });

    final initialPayload = await protocolHandler.getInitialUrl();
    if (initialPayload != null) {
      await _handleIncomingUri(initialPayload);
    }
  }

  @override
  void onProtocolUrlReceived(String url) {
    super.onProtocolUrlReceived(url);
    unawaited(_handleIncomingUri(url));
  }

  Future<void> _handleIncomingUri(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) {
      loggy.debug('Received malformed auth deeplink: [$url]');
      return;
    }

    final scheme = uri.scheme.toLowerCase();
    if (!_supportedSchemes.contains(scheme)) {
      return;
    }

    if (uri.host != _authHost && uri.authority != _authHost) {
      return;
    }

    final token = _extractToken(uri);
    if (token == null || token.trim().isEmpty) {
      loggy.debug('Auth deeplink did not contain a token');
      return;
    }

    loggy.debug('Persisting Telegram auth token');
    await ref.read(AuthPreferences.telegramAuthToken.notifier).update(token.trim());
  }

  String? _extractToken(Uri uri) {
    final queryToken = uri.queryParameters['token'] ?? uri.queryParameters['auth'];
    if (queryToken != null && queryToken.isNotEmpty) {
      return queryToken;
    }

    if (uri.pathSegments.isNotEmpty) {
      final lastSegment = uri.pathSegments.last;
      if (lastSegment.isNotEmpty) {
        return lastSegment;
      }
    }

    if (uri.fragment.isNotEmpty) {
      return uri.fragment;
    }

    return null;
  }
}
