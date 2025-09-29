import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/core/router/routes.dart';
import 'package:hiddify/features/auth/preferences/auth_preferences.dart';
import 'package:hiddify/features/deep_link/notifier/deep_link_notifier.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

part 'app_router.g.dart';

bool _debugMobileRouter = false;

final useMobileRouter =
    !PlatformUtils.isDesktop || (kDebugMode && _debugMobileRouter);
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

// TODO: test and improve handling of deep link
@riverpod
GoRouter router(RouterRef ref) {
  final notifier = ref.watch(routerListenableProvider.notifier);
  final deepLink = ref.listen(
    deepLinkNotifierProvider,
    (_, next) async {
      if (next case AsyncData(value: final link?)) {
        await ref.state.push(AddProfileRoute(url: link.url).location);
      }
    },
  );
  final initialLink = deepLink.read();
  final isAuthorized = ref.read(isAuthorizedProvider);
  String initialLocation =
      isAuthorized ? const HomeRoute().location : const TelegramLoginRoute().location;
  if (initialLink case AsyncData(value: final link?)) {
    initialLocation = isAuthorized
        ? AddProfileRoute(url: link.url).location
        : const TelegramLoginRoute().location;
  }

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initialLocation,
    debugLogDiagnostics: true,
    routes: [
      if (useMobileRouter) $mobileWrapperRoute else $desktopWrapperRoute,
      $introRoute,
      $telegramLoginRoute,
    ],
    refreshListenable: notifier,
    redirect: notifier.redirect,
    observers: [
      SentryNavigatorObserver(),
    ],
  );
}

final tabLocations = [
  const HomeRoute().location,
  const ProxiesRoute().location,
  const ConfigOptionsRoute().location,
  const SettingsRoute().location,
  const LogsOverviewRoute().location,
  const AboutRoute().location,
];

int getCurrentIndex(BuildContext context) {
  final String location = GoRouterState.of(context).uri.path;
  if (location == const HomeRoute().location) return 0;
  var index = 0;
  for (final tab in tabLocations.sublist(1)) {
    index++;
    if (location.startsWith(tab)) return index;
  }
  return 0;
}

void switchTab(int index, BuildContext context) {
  assert(index >= 0 && index < tabLocations.length);
  final location = tabLocations[index];
  return context.go(location);
}

@riverpod
class RouterListenable extends _$RouterListenable
    with AppLogger
    implements Listenable {
  VoidCallback? _routerListener;
  bool _introCompleted = false;
  bool _isAuthenticated = false;

  @override
  Future<void> build() async {
    _introCompleted = ref.watch(Preferences.introCompleted);
    _isAuthenticated = ref.watch(isAuthorizedProvider);

    ref.listen<bool>(Preferences.introCompleted, (_, next) {
      _introCompleted = next;
      _routerListener?.call();
    });

    ref.listen<bool>(isAuthorizedProvider, (_, next) {
      _isAuthenticated = next;
      _routerListener?.call();
    });

    ref.listenSelf((_, __) {
      if (state.isLoading) return;
      loggy.debug("triggering listener");
      _routerListener?.call();
    });
  }

// ignore: avoid_build_context_in_providers
  String? redirect(BuildContext context, GoRouterState state) {
    // if (this.state.isLoading || this.state.hasError) return null;

    final isIntro = state.uri.path == const IntroRoute().location;
    final isLogin = state.uri.path == const TelegramLoginRoute().location;

    if (!_introCompleted) {
      return const IntroRoute().location;
    } else if (isIntro) {
      return const HomeRoute().location;
    }

    if (!_isAuthenticated) {
      if (!isLogin) {
        return const TelegramLoginRoute().location;
      }
      return null;
    } else if (isLogin) {
      return const HomeRoute().location;
    }

    return null;
  }

  @override
  void addListener(VoidCallback listener) {
    _routerListener = listener;
  }

  @override
  void removeListener(VoidCallback listener) {
    _routerListener = null;
  }
}
