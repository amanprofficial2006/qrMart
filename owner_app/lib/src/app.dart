import 'dart:async';

import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'config/app_config.dart';
import 'core/network/api_client.dart';
import 'core/storage/session_storage.dart';
import 'features/auth/auth_screen.dart';
import 'features/auth/session_controller.dart';
import 'features/auth/start_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/dashboard/owner_repository.dart';

enum _PublicEntryScreen { start, login, register }

class QrMartOwnerBootstrap extends StatefulWidget {
  const QrMartOwnerBootstrap({super.key});

  @override
  State<QrMartOwnerBootstrap> createState() => _QrMartOwnerBootstrapState();
}

class _QrMartOwnerBootstrapState extends State<QrMartOwnerBootstrap> {
  late final ApiClient _apiClient;
  late final OwnerRepository _repository;
  late final SessionStorage _storage;
  late final SessionController _sessionController;

  _PublicEntryScreen _publicEntryScreen = _PublicEntryScreen.start;
  bool _hasShownIntroSplash = false;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient(baseUrl: AppConfig.apiBaseUrl);
    _repository = OwnerRepository(_apiClient);
    _storage = SessionStorage();
    _sessionController = SessionController(
      storage: _storage,
      repository: _repository,
    );
    _sessionController.restoreSession();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _sessionController,
      builder: (context, _) {
        return MaterialApp(
          title: AppConfig.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.build(),
          home: _buildHome(),
        );
      },
    );
  }

  Widget _buildHome() {
    if (_sessionController.restoring) {
      return const BrandedSplashScreen();
    }

    if (_sessionController.isAuthenticated) {
      return DashboardScreen(
        repository: _repository,
        sessionController: _sessionController,
        onLogout: _handleLogout,
      );
    }

    switch (_publicEntryScreen) {
      case _PublicEntryScreen.start:
        return StartScreen(
          showIntroSplash: !_hasShownIntroSplash,
          onIntroSplashComplete: () {
            if (_hasShownIntroSplash) {
              return;
            }

            setState(() => _hasShownIntroSplash = true);
          },
          onStart: () => setState(
            () => _publicEntryScreen = _PublicEntryScreen.register,
          ),
          onLogin: () => setState(
            () => _publicEntryScreen = _PublicEntryScreen.login,
          ),
        );
      case _PublicEntryScreen.login:
        return AuthScreen(
          key: const ValueKey('auth-login'),
          sessionController: _sessionController,
          initialMode: AuthScreenMode.login,
          onBack: () => setState(
            () => _publicEntryScreen = _PublicEntryScreen.start,
          ),
        );
      case _PublicEntryScreen.register:
        return AuthScreen(
          key: const ValueKey('auth-register'),
          sessionController: _sessionController,
          initialMode: AuthScreenMode.register,
          onBack: () => setState(
            () => _publicEntryScreen = _PublicEntryScreen.start,
          ),
        );
    }
  }

  void _handleLogout() {
    setState(() => _publicEntryScreen = _PublicEntryScreen.start);
    unawaited(_sessionController.logout());
  }
}
