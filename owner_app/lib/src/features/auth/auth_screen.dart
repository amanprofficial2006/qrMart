import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/network/api_client.dart';
import '../../core/widgets/qrmart_branding.dart';
import 'session_controller.dart';

enum AuthScreenMode { login, register }

enum _AuthStage { form, otp, verificationSuccess, underVerification }

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.sessionController,
    this.initialMode = AuthScreenMode.login,
    this.onBack,
  });

  final SessionController sessionController;
  final AuthScreenMode initialMode;
  final VoidCallback? onBack;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  static const _staticOtp = '142006';

  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final _loginPhoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _registerPhoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _otpController = TextEditingController();
  final List<_SelectedShopPhoto?> _shopPhotos =
      List<_SelectedShopPhoto?>.filled(3, null);
  Timer? _verificationStatusTimer;
  bool _verificationCheckInFlight = false;

  late AuthScreenMode _mode;
  _AuthStage _stage = _AuthStage.form;
  String? _otpError;
  String? _photoError;

  bool get _isRegister => _mode == AuthScreenMode.register;

  int get _selectedShopPhotoCount =>
      _shopPhotos.whereType<_SelectedShopPhoto>().length;

  List<MultipartFilePart> get _selectedShopPhotos => _shopPhotos
      .whereType<_SelectedShopPhoto>()
      .map(
        (photo) => MultipartFilePart(
          field: 'shopPhotos',
          path: photo.path,
          filename: photo.filename,
        ),
      )
      .toList(growable: false);

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
  }

  @override
  void didUpdateWidget(covariant AuthScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialMode != widget.initialMode) {
      _resetFlow(mode: widget.initialMode);
    }
  }

  @override
  void dispose() {
    _stopVerificationStatusPolling();
    _loginPhoneController.dispose();
    _nameController.dispose();
    _registerPhoneController.dispose();
    _emailController.dispose();
    _shopNameController.dispose();
    _addressController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isRegister && _selectedShopPhotoCount < 3) {
      setState(() => _photoError = 'Upload at least 3 shop photos before OTP.');
      return;
    }

    FocusScope.of(context).unfocus();
    widget.sessionController.clearError();

    setState(() {
      _stage = _AuthStage.otp;
      _otpController.clear();
      _otpError = null;
      _photoError = null;
    });
  }

  Future<void> _submitOtp() async {
    FocusScope.of(context).unfocus();
    widget.sessionController.clearError();

    if (_otpController.text.trim() != _staticOtp) {
      setState(() => _otpError = 'Invalid OTP. Use $_staticOtp to continue.');
      return;
    }

    setState(() => _otpError = null);

    if (_isRegister) {
      final registered = await widget.sessionController.register(
        name: _nameController.text,
        phone: _registerPhoneController.text,
        email: _emailController.text,
        shopName: _shopNameController.text,
        address: _addressController.text,
        shopPhotos: _selectedShopPhotos,
        authenticate: true,
      );

      if (!registered || !mounted) {
        return;
      }

      if (widget.sessionController.isAuthenticated) {
        _stopVerificationStatusPolling();
        return;
      }

      setState(() => _stage = _AuthStage.verificationSuccess);
      return;
    }

    final loggedIn = await widget.sessionController.login(
      identifier: _loginPhoneController.text,
      otp: _otpController.text,
    );

    if (!loggedIn &&
        mounted &&
        (widget.sessionController.error ?? '')
            .toLowerCase()
            .contains('under verification')) {
      _enterUnderVerificationStage();
    }
  }

  Future<void> _switchMode(AuthScreenMode mode) async {
    if (_mode == mode && _stage == _AuthStage.form) {
      return;
    }

    widget.sessionController.clearError();
    _resetFlow(mode: mode);
  }

  void _resetFlow({AuthScreenMode? mode}) {
    _stopVerificationStatusPolling();
    setState(() {
      _mode = mode ?? _mode;
      _stage = _AuthStage.form;
      _otpController.clear();
      _otpError = null;
      _photoError = null;
    });
  }

  void _showUnderVerification() {
    _enterUnderVerificationStage();
  }

  void _returnToWelcome() {
    if (widget.onBack != null) {
      widget.onBack!.call();
      return;
    }

    _resetFlow(mode: AuthScreenMode.login);
  }

  void _handleBack() {
    widget.sessionController.clearError();

    if (_stage == _AuthStage.otp) {
      setState(() {
        _stage = _AuthStage.form;
        _otpController.clear();
        _otpError = null;
      });
      return;
    }

    _stopVerificationStatusPolling();
    widget.onBack?.call();
  }

  void _enterUnderVerificationStage() {
    setState(() => _stage = _AuthStage.underVerification);
    _startVerificationStatusPolling();
  }

  void _startVerificationStatusPolling() {
    _stopVerificationStatusPolling();
    unawaited(_checkVerificationStatus());
    _verificationStatusTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => unawaited(_checkVerificationStatus()),
    );
  }

  void _stopVerificationStatusPolling() {
    _verificationStatusTimer?.cancel();
    _verificationStatusTimer = null;
    _verificationCheckInFlight = false;
  }

  Future<void> _checkVerificationStatus() async {
    if (!mounted || _verificationCheckInFlight) {
      return;
    }

    final identifier = _isRegister
        ? _registerPhoneController.text.trim()
        : _loginPhoneController.text.trim();

    if (identifier.isEmpty) {
      return;
    }

    _verificationCheckInFlight = true;

    try {
      final activated =
          await widget.sessionController.refreshVerificationStatus(
        identifier: identifier,
        otp: _staticOtp,
      );

      if (activated) {
        _stopVerificationStatusPolling();
      }
    } finally {
      _verificationCheckInFlight = false;
    }
  }

  Future<void> _pickShopPhoto(int index) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take photo'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Upload from gallery'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) {
      return;
    }

    final file = await _picker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (file == null) {
      return;
    }

    final bytes = await file.readAsBytes();

    setState(() {
      _shopPhotos[index] = _SelectedShopPhoto(
        path: file.path,
        filename: file.name,
        bytes: bytes,
      );
      if (_selectedShopPhotoCount >= 3) {
        _photoError = null;
      }
    });
  }

  void _removeShopPhoto(int index) {
    setState(() {
      _shopPhotos[index] = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final logoSize = screenWidth < 380
        ? 74.0
        : screenWidth < 480
            ? 86.0
            : 96.0;

    return AnimatedBuilder(
      animation: widget.sessionController,
      builder: (context, _) {
        final busy = widget.sessionController.busy;
        final error = widget.sessionController.error;
        final showBackButton = _stage == _AuthStage.otp ||
            (_stage == _AuthStage.form && widget.onBack != null);

        return Scaffold(
          body: QrMartBackground(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showBackButton)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton.filledTonal(
                              onPressed: busy ? null : _handleBack,
                              icon: Icon(
                                _stage == _AuthStage.otp
                                    ? Icons.arrow_back_rounded
                                    : Icons.close_rounded,
                              ),
                              tooltip:
                                  _stage == _AuthStage.otp ? 'Back' : 'Close',
                            ),
                          ),
                        const SizedBox(height: 12),
                        Center(
                          child: QrMartLogo(
                            iconSize: logoSize,
                            showWordmark: true,
                            center: true,
                          ),
                        ),
                        const SizedBox(height: 20),
                        QrMartSurfaceCard(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            child: _buildStage(
                              key: ValueKey(_stage),
                              theme: theme,
                              busy: busy,
                              error: error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStage({
    required Key key,
    required ThemeData theme,
    required bool busy,
    required String? error,
  }) {
    switch (_stage) {
      case _AuthStage.form:
        return _buildFormStage(
            key: key, theme: theme, busy: busy, error: error);
      case _AuthStage.otp:
        return _buildOtpStage(key: key, theme: theme, busy: busy, error: error);
      case _AuthStage.verificationSuccess:
        return _buildVerificationSuccessStage(key: key, theme: theme);
      case _AuthStage.underVerification:
        return _buildUnderVerificationStage(key: key, theme: theme);
    }
  }

  Widget _buildFormStage({
    required Key key,
    required ThemeData theme,
    required bool busy,
    required String? error,
  }) {
    final title = _isRegister ? 'Create Shop Account' : 'Login with Mobile OTP';
    final subtitle = _isRegister
        ? 'Add your shop details, address, and at least 3 shop photos before OTP verification.'
        : 'Enter your mobile number and continue to the OTP verification step.';

    return Form(
      key: _formKey,
      child: Column(
        key: key,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ModeSwitch(
            mode: _mode,
            busy: busy,
            onSelect: _switchMode,
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: QrMartSectionEyebrow(
              label: _isRegister ? 'Registration form' : 'OTP login',
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: QrMartPalette.mutedInk,
            ),
          ),
          if (error != null && error.isNotEmpty) ...[
            const SizedBox(height: 18),
            _InlineBanner(
              message: error,
              backgroundColor: theme.colorScheme.errorContainer,
              textColor: theme.colorScheme.onErrorContainer,
            ),
          ],
          const SizedBox(height: 22),
          if (_isRegister) ...[
            _buildOwnerNameField(),
            const SizedBox(height: 14),
            _buildShopNameField(),
            const SizedBox(height: 14),
            _buildRegisterPhoneField(),
            const SizedBox(height: 14),
            _buildAddressField(),
            const SizedBox(height: 14),
            _buildEmailField(),
            const SizedBox(height: 18),
            _buildShopPhotosSection(theme),
          ] else ...[
            _buildLoginPhoneField(),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: busy ? null : _submitForm,
            child: Text(
              _isRegister ? 'Continue to OTP' : 'Send OTP',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _isRegister
                ? 'After OTP verification, your registration and shop photos will move to the shop verification queue.'
                : 'Your login access is now handled through OTP only.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: QrMartPalette.mutedInk,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Center(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              children: [
                Text(
                  _isRegister
                      ? 'Already registered?'
                      : 'Need a new shop account?',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: QrMartPalette.mutedInk,
                  ),
                ),
                TextButton(
                  onPressed: busy
                      ? null
                      : () => _switchMode(
                            _isRegister
                                ? AuthScreenMode.login
                                : AuthScreenMode.register,
                          ),
                  child: Text(_isRegister ? 'Login' : 'Register'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpStage({
    required Key key,
    required ThemeData theme,
    required bool busy,
    required String? error,
  }) {
    final destination = _isRegister
        ? _registerPhoneController.text.trim()
        : _loginPhoneController.text.trim();
    final title = _isRegister ? 'Verify Registration OTP' : 'Verify Login OTP';
    final subtitle = _isRegister
        ? 'Enter the static OTP to confirm your registration for $destination.'
        : 'Enter the static OTP to login with mobile number $destination.';

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: QrMartSectionEyebrow(
            label: 'OTP verification',
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: QrMartPalette.mutedInk,
          ),
        ),
        const SizedBox(height: 18),
        _InlineBanner(
          message: 'Static OTP for this build: $_staticOtp',
          backgroundColor: theme.colorScheme.primaryContainer,
          textColor: theme.colorScheme.onPrimaryContainer,
        ),
        if (_otpError != null) ...[
          const SizedBox(height: 14),
          _InlineBanner(
            message: _otpError!,
            backgroundColor: theme.colorScheme.errorContainer,
            textColor: theme.colorScheme.onErrorContainer,
          ),
        ],
        if (error != null && error.isNotEmpty) ...[
          const SizedBox(height: 14),
          _InlineBanner(
            message: error,
            backgroundColor: theme.colorScheme.errorContainer,
            textColor: theme.colorScheme.onErrorContainer,
          ),
        ],
        const SizedBox(height: 22),
        _buildOtpField(),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: busy ? null : _submitOtp,
          child: Text(
            busy
                ? 'Please wait...'
                : _isRegister
                    ? 'Verify & Register'
                    : 'Verify & Login',
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: busy ? null : _handleBack,
          child: const Text('Edit details'),
        ),
      ],
    );
  }

  Widget _buildVerificationSuccessStage({
    required Key key,
    required ThemeData theme,
  }) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _StatusBadge(
          icon: Icons.verified_rounded,
          accentColor: QrMartPalette.leaf,
        ),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerLeft,
          child: QrMartSectionEyebrow(
            label: 'Verification success',
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Verification Success',
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: 10),
        Text(
          'Your mobile OTP matched successfully. We have received the registration for ${_shopNameController.text.trim()}.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: QrMartPalette.mutedInk,
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _showUnderVerification,
          child: const Text('Continue'),
        ),
      ],
    );
  }

  Widget _buildUnderVerificationStage({
    required Key key,
    required ThemeData theme,
  }) {
    final isRegisterFlow = _isRegister;
    final title = 'Your Shop Is Under Verification';
    final description = isRegisterFlow
        ? 'We have placed ${_shopNameController.text.trim()} in the verification queue. Our team will review the details and activate the owner journey after approval.'
        : 'Your mobile number is linked to a shop that is still being reviewed. Login access will start after approval.';

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _StatusBadge(
          icon: Icons.hourglass_top_rounded,
          accentColor: QrMartPalette.accentGold,
        ),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerLeft,
          child: QrMartSectionEyebrow(
            label: 'Under verification',
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: 10),
        Text(
          description,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: QrMartPalette.mutedInk,
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: QrMartPalette.softSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: QrMartPalette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Submitted details',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              if (isRegisterFlow) ...[
                Text('Owner: ${_nameController.text.trim()}'),
                const SizedBox(height: 6),
                Text('Mobile: ${_registerPhoneController.text.trim()}'),
                const SizedBox(height: 6),
                Text('Address: ${_addressController.text.trim()}'),
              ] else ...[
                Text('Mobile: ${_loginPhoneController.text.trim()}'),
                const SizedBox(height: 6),
                const Text('Status: Waiting for admin approval'),
              ],
              if (isRegisterFlow &&
                  _emailController.text.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('Email: ${_emailController.text.trim()}'),
              ],
              if (isRegisterFlow) ...[
                const SizedBox(height: 6),
                Text('Shop photos: ${_selectedShopPhotoCount}/3 uploaded'),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _returnToWelcome,
          child: const Text('Back to Welcome'),
        ),
      ],
    );
  }

  Widget _buildOwnerNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Owner Name',
        hintText: 'Enter owner name',
        prefixIcon: Icon(Icons.person_outline_rounded),
      ),
      textCapitalization: TextCapitalization.words,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Owner name is required';
        }
        return null;
      },
    );
  }

  Widget _buildShopNameField() {
    return TextFormField(
      controller: _shopNameController,
      decoration: const InputDecoration(
        labelText: 'Shop Name',
        hintText: 'Enter shop name',
        prefixIcon: Icon(Icons.storefront_outlined),
      ),
      textCapitalization: TextCapitalization.words,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Shop name is required';
        }
        return null;
      },
    );
  }

  Widget _buildRegisterPhoneField() {
    return TextFormField(
      controller: _registerPhoneController,
      decoration: const InputDecoration(
        labelText: 'Mobile Number',
        hintText: 'Enter mobile number',
        prefixIcon: Icon(Icons.call_outlined),
      ),
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(15),
      ],
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Mobile number is required';
        }
        if (value.trim().length < 10) {
          return 'Enter a valid mobile number';
        }
        return null;
      },
    );
  }

  Widget _buildAddressField() {
    return TextFormField(
      controller: _addressController,
      decoration: const InputDecoration(
        labelText: 'Shop Address',
        hintText: 'Enter full shop address',
        prefixIcon: Icon(Icons.location_on_outlined),
      ),
      textCapitalization: TextCapitalization.sentences,
      maxLines: 2,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Shop address is required';
        }
        if (value.trim().length < 10) {
          return 'Enter a more complete shop address';
        }
        return null;
      },
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      decoration: const InputDecoration(
        labelText: 'Email (Optional)',
        hintText: 'Enter email address',
        prefixIcon: Icon(Icons.alternate_email_rounded),
      ),
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        final text = value?.trim() ?? '';
        if (text.isEmpty) {
          return null;
        }
        if (!text.contains('@') || text.startsWith('@') || text.endsWith('@')) {
          return 'Enter a valid email or leave it empty';
        }
        return null;
      },
    );
  }

  Widget _buildLoginPhoneField() {
    return TextFormField(
      controller: _loginPhoneController,
      decoration: const InputDecoration(
        labelText: 'Mobile Number',
        hintText: 'Enter mobile number',
        prefixIcon: Icon(Icons.call_outlined),
      ),
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(15),
      ],
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Mobile number is required';
        }
        if (value.trim().length < 10) {
          return 'Enter a valid mobile number';
        }
        return null;
      },
    );
  }

  Widget _buildOtpField() {
    return TextField(
      controller: _otpController,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      decoration: const InputDecoration(
        labelText: 'OTP',
        hintText: 'Enter 6-digit OTP',
        prefixIcon: Icon(Icons.password_rounded),
      ),
    );
  }

  Widget _buildShopPhotosSection(ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final compact = availableWidth < 360;
        final double tileWidth = compact
            ? availableWidth
            : ((availableWidth - 12) / 2).clamp(132.0, 154.0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Shop Photos',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Upload or click at least 3 clear photos of your shop before OTP verification.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: QrMartPalette.mutedInk,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (var index = 0; index < _shopPhotos.length; index++)
                  _ShopPhotoPickerTile(
                    index: index,
                    width: tileWidth,
                    photo: _shopPhotos[index],
                    onPick: () => _pickShopPhoto(index),
                    onRemove: _shopPhotos[index] == null
                        ? null
                        : () => _removeShopPhoto(index),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '$_selectedShopPhotoCount/3 photos selected',
              style: theme.textTheme.labelLarge?.copyWith(
                color: _selectedShopPhotoCount >= 3
                    ? QrMartPalette.leaf
                    : QrMartPalette.primaryDark,
              ),
            ),
            if (_photoError != null) ...[
              const SizedBox(height: 12),
              _InlineBanner(
                message: _photoError!,
                backgroundColor: theme.colorScheme.errorContainer,
                textColor: theme.colorScheme.onErrorContainer,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({
    required this.mode,
    required this.busy,
    required this.onSelect,
  });

  final AuthScreenMode mode;
  final bool busy;
  final Future<void> Function(AuthScreenMode mode) onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: QrMartPalette.softSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: QrMartPalette.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeButton(
              label: 'Login',
              selected: mode == AuthScreenMode.login,
              onTap: busy ? null : () => onSelect(AuthScreenMode.login),
            ),
          ),
          Expanded(
            child: _ModeButton(
              label: 'Register',
              selected: mode == AuthScreenMode.register,
              onTap: busy ? null : () => onSelect(AuthScreenMode.register),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: QrMartPalette.shadow.withOpacity(0.45),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ]
            : const [],
      ),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor:
              selected ? QrMartPalette.primary : QrMartPalette.mutedInk,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Text(label),
      ),
    );
  }
}

class _InlineBanner extends StatelessWidget {
  const _InlineBanner({
    required this.message,
    required this.backgroundColor,
    required this.textColor,
  });

  final String message;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.icon,
    required this.accentColor,
  });

  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 92,
        height: 92,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accentColor.withOpacity(0.22),
              accentColor.withOpacity(0.08),
            ],
          ),
        ),
        child: Icon(
          icon,
          size: 42,
          color: accentColor,
        ),
      ),
    );
  }
}

class _ShopPhotoPickerTile extends StatelessWidget {
  const _ShopPhotoPickerTile({
    required this.index,
    required this.width,
    required this.photo,
    required this.onPick,
    this.onRemove,
  });

  final int index;
  final double width;
  final _SelectedShopPhoto? photo;
  final VoidCallback onPick;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final hasImage = photo != null;

    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.74),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: QrMartPalette.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Photo ${index + 1}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                height: 116,
                child: hasImage
                    ? Image.memory(
                        photo!.bytes,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      )
                    : Container(
                        color: QrMartPalette.softSurface,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.add_a_photo_outlined,
                          size: 30,
                          color: QrMartPalette.mutedInk,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onPick,
              icon: Icon(
                hasImage ? Icons.refresh_rounded : Icons.upload_file_rounded,
              ),
              label: Text(hasImage ? 'Change' : 'Add photo'),
            ),
            if (onRemove != null) ...[
              const SizedBox(height: 6),
              TextButton(
                onPressed: onRemove,
                child: const Text('Remove'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SelectedShopPhoto {
  const _SelectedShopPhoto({
    required this.path,
    required this.filename,
    required this.bytes,
  });

  final String path;
  final String filename;
  final Uint8List bytes;
}
