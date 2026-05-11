import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../config/app_config.dart';
import '../../core/storage/session_storage.dart';
import '../../models/owner.dart';
import '../../models/owner_identity.dart';
import '../../models/pending_google_registration.dart';
import '../../models/shop.dart';
import '../dashboard/owner_repository.dart';

class SessionController extends ChangeNotifier {
  SessionController({
    required SessionStorage storage,
    required OwnerRepository repository,
  })  : _storage = storage,
        _repository = repository;

  final SessionStorage _storage;
  final OwnerRepository _repository;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  Future<void>? _googleInitialization;

  bool restoring = true;
  bool busy = false;
  String? error;
  Owner? owner;
  Shop? shop;
  PendingGoogleRegistration? pendingGoogleRegistration;

  bool get isAuthenticated => owner != null && shop != null;

  Future<void> restoreSession() async {
    restoring = true;
    notifyListeners();

    final token = await _storage.readToken();

    if (token == null || token.isEmpty) {
      restoring = false;
      notifyListeners();
      return;
    }

    _repository.setToken(token);

    try {
      final identity = await _repository.getIdentity();
      replaceIdentity(identity);
      error = null;
    } catch (_) {
      await _storage.clearToken();
      _repository.setToken(null);
      owner = null;
      shop = null;
    } finally {
      restoring = false;
      notifyListeners();
    }
  }

  Future<bool> login({
    required String identifier,
    String password = '',
    String otp = '',
  }) async {
    busy = true;
    error = null;
    notifyListeners();

    try {
      final response = await _repository.login(
        identifier: identifier,
        password: password,
        otp: otp,
      );

      _repository.setToken(response.token);
      await _storage.saveToken(response.token);
      owner = response.owner;
      shop = response.shop;
      return true;
    } catch (exception) {
      error = _messageFrom(exception);
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> refreshVerificationStatus({
    required String identifier,
    required String otp,
  }) async {
    try {
      final response = await _repository.login(
        identifier: identifier,
        otp: otp,
      );

      _repository.setToken(response.token);
      await _storage.saveToken(response.token);
      owner = response.owner;
      shop = response.shop;
      error = null;
      notifyListeners();
      return true;
    } catch (exception) {
      final message = _messageFrom(exception);

      if (message.toLowerCase().contains('under verification')) {
        if (error != null && error!.isNotEmpty) {
          error = null;
          notifyListeners();
        }
        return false;
      }

      if (error != message) {
        error = message;
        notifyListeners();
      }

      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String phone,
    required String email,
    String password = '',
    required String shopName,
    String address = '',
    List<MultipartFilePart> shopPhotos = const [],
    bool authenticate = true,
  }) async {
    busy = true;
    error = null;
    notifyListeners();

    try {
      final response = await _repository.register(
        name: name,
        phone: phone,
        email: email,
        password: password,
        shopName: shopName,
        address: address,
        shopPhotos: shopPhotos,
      );

      if (authenticate && response.shop.isActive) {
        _repository.setToken(response.token);
        await _storage.saveToken(response.token);
        owner = response.owner;
        shop = response.shop;
      } else {
        _repository.setToken(null);
        owner = null;
        shop = null;
        await _storage.clearToken();
      }
      return true;
    } catch (exception) {
      error = _messageFrom(exception);
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> prepareGoogleSignIn() {
    return _googleInitialization ??= _googleSignIn.initialize(
      serverClientId: AppConfig.googleServerClientId,
    );
  }

  Future<bool> signInWithGoogle() async {
    busy = true;
    error = null;
    notifyListeners();

    try {
      await prepareGoogleSignIn();

      if (!_googleSignIn.supportsAuthenticate()) {
        throw const ApiException(
            'Google sign-in is not available on this device');
      }

      final GoogleSignInAccount account = await _googleSignIn.authenticate();
      final String credential = account.authentication.idToken ?? '';

      if (credential.isEmpty) {
        throw const ApiException('Google sign-in did not return an ID token');
      }

      final response = await _repository.googleAuth(credential: credential);

      if (response.needsProfile) {
        final profile = response.profile!;
        pendingGoogleRegistration = PendingGoogleRegistration(
          credential: credential,
          name: profile.name.isEmpty ? account.displayName ?? '' : profile.name,
          email: profile.email.isEmpty ? account.email : profile.email,
        );
        return true;
      }

      final auth = response.auth!;
      pendingGoogleRegistration = null;
      _repository.setToken(auth.token);
      await _storage.saveToken(auth.token);
      owner = auth.owner;
      shop = auth.shop;
      return true;
    } catch (exception) {
      error = _messageFrom(exception);
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> completeGoogleRegistration({
    required String name,
    required String phone,
    required String password,
    required String shopName,
  }) async {
    final pending = pendingGoogleRegistration;

    if (pending == null) {
      error = 'Start with Google first to finish registration';
      notifyListeners();
      return false;
    }

    busy = true;
    error = null;
    notifyListeners();

    try {
      final response = await _repository.googleAuth(
        credential: pending.credential,
        name: name,
        phone: phone,
        password: password,
        shopName: shopName,
      );

      if (response.needsProfile || response.auth == null) {
        throw const ApiException('Unable to finish Google registration');
      }

      final auth = response.auth!;
      pendingGoogleRegistration = null;
      _repository.setToken(auth.token);
      await _storage.saveToken(auth.token);
      owner = auth.owner;
      shop = auth.shop;
      return true;
    } catch (exception) {
      error = _messageFrom(exception);
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> resetGoogleRegistration() async {
    pendingGoogleRegistration = null;
    error = null;
    notifyListeners();

    try {
      await prepareGoogleSignIn();
      await _googleSignIn.signOut();
    } catch (_) {
      // Ignore local Google session cleanup failures.
    }
  }

  Future<void> logout() async {
    owner = null;
    shop = null;
    error = null;
    pendingGoogleRegistration = null;
    _repository.setToken(null);
    await _storage.clearToken();
    unawaited(_safeGoogleSignOut());
    notifyListeners();
  }

  void replaceIdentity(OwnerIdentity identity) {
    owner = identity.owner;
    shop = identity.shop;
    notifyListeners();
  }

  void updateShop(Shop nextShop) {
    shop = nextShop;
    notifyListeners();
  }

  void clearError() {
    if (error == null || error!.isEmpty) {
      return;
    }

    error = null;
    notifyListeners();
  }

  String _messageFrom(Object exception) {
    if (exception is GoogleSignInException) {
      switch (exception.code) {
        case GoogleSignInExceptionCode.canceled:
          return 'Google sign-in was canceled';
        case GoogleSignInExceptionCode.clientConfigurationError:
          return 'Google sign-in is not configured for this app build yet';
        default:
          return exception.description ?? 'Google sign-in failed';
      }
    }

    if (exception is ApiException) {
      return exception.message;
    }

    return exception.toString().replaceFirst('Exception: ', '');
  }

  Future<void> _safeGoogleSignOut() async {
    try {
      await prepareGoogleSignIn();
      await _googleSignIn.signOut();
    } catch (_) {
      // Ignore local Google session cleanup failures.
    }
  }
}
