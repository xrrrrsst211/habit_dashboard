import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:habit_dashboard/core/widgets/image_crop_editor.dart';

import '../data/auth_service.dart';
import '../data/profile_avatar_service.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback? onContinueAsGuest;
  final VoidCallback? onSignedIn;

  const AuthScreen({
    super.key,
    this.onContinueAsGuest,
    this.onSignedIn,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _nickname = TextEditingController();

  final AuthService auth = AuthService();
  final ProfileAvatarService _avatarService = ProfileAvatarService();

  bool login = true;
  bool loading = false;
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;
  Uint8List? _selectedAvatarBytes;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _nickname.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Enter your email';

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) return 'Enter a valid email';
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Enter your password';
    if (password.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (login) return null;
    if ((value ?? '').isEmpty) return 'Repeat your password';
    if (value != _password.text) return 'Passwords do not match';
    return null;
  }

  String? _validateNickname(String? value) {
    if (login) return null;

    final nickname = value?.trim() ?? '';
    if (nickname.isEmpty) return 'Choose a nickname';
    if (nickname.length < 2) return 'Nickname must be at least 2 characters';
    if (nickname.length > 20) return 'Nickname must be 20 characters or less';

    final allowed = RegExp(r"^[a-zA-Z0-9_ .-]+$");
    if (!allowed.hasMatch(nickname)) {
      return 'Use letters, numbers, spaces, _, - or .';
    }

    return null;
  }

  String _friendlyError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'That email address is invalid.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'user-not-found':
          return 'No account found with that email.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Wrong email or password.';
        case 'email-already-in-use':
          return 'An account with this email already exists.';
        case 'weak-password':
          return 'Password is too weak. Use at least 6 characters.';
        case 'network-request-failed':
          return 'Network error. Check your internet and try again.';
        case 'too-many-requests':
          return 'Too many attempts. Try again a bit later.';
      }
    }
    return 'Something went wrong. Please try again.';
  }

  Future<void> _pickAvatar() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final bytes = result.files.single.bytes;
      if (bytes == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read this image. Try another one.')),
        );
        return;
      }

      if (bytes.length > ProfileAvatarService.maxAvatarBytes) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pick a smaller image under 2 MB.')),
        );
        return;
      }

      if (!mounted) return;
      final cropped = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute(
          builder: (_) => ImageCropEditorScreen(
            imageBytes: bytes,
            circular: true,
            title: 'Adjust avatar',
            helpText: 'Move and zoom the photo until your avatar looks right.',
          ),
        ),
      );

      if (!mounted || cropped == null) return;
      setState(() => _selectedAvatarBytes = cropped);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open image picker.')),
      );
    }
  }

  Future<void> submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      final email = _email.text.trim();
      final password = _password.text.trim();

      if (login) {
        await auth.signIn(email, password);
      } else {
        final nickname = _nickname.text.trim();
        final credential = await auth.register(
          email,
          password,
          displayName: nickname,
        );
        final uid = credential.user?.uid;
        if (uid != null && _selectedAvatarBytes != null) {
          await _avatarService.saveAvatarBytes(uid, _selectedAvatarBytes!);
        }
      }

      widget.onSignedIn?.call();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyError(e))),
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void _toggleMode() {
    setState(() {
      login = !login;
      _confirmPassword.clear();
      if (login) {
        _nickname.clear();
        _selectedAvatarBytes = null;
      }
    });
  }

  Widget _buildAvatarPicker(ColorScheme cs, TextTheme tt) {
    if (login) return const SizedBox.shrink();

    final avatar = _selectedAvatarBytes == null
        ? Icon(Icons.person_rounded, size: 38, color: cs.primary)
        : Image.memory(
            _selectedAvatarBytes!,
            fit: BoxFit.cover,
            gaplessPlayback: true,
          );

    return Column(
      children: [
        Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 86,
                height: 86,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cs.primary.withOpacity(0.12),
                  border: Border.all(color: cs.primary.withOpacity(0.22)),
                ),
                child: avatar,
              ),
              Positioned(
                right: -8,
                bottom: -8,
                child: Material(
                  color: cs.primary,
                  shape: const CircleBorder(),
                  child: IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Choose avatar',
                    onPressed: loading ? null : _pickAvatar,
                    icon: Icon(Icons.add_a_photo_rounded, color: cs.onPrimary, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: TextButton.icon(
            onPressed: loading ? null : _pickAvatar,
            icon: const Icon(Icons.image_outlined),
            label: Text(_selectedAvatarBytes == null ? 'Add profile avatar' : 'Change avatar'),
          ),
        ),
        Text(
          'Optional. You can drag and zoom before saving the avatar.',
          textAlign: TextAlign.center,
          style: tt.bodySmall?.copyWith(color: cs.onSurface.withOpacity(0.62)),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 44),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: cs.outline.withOpacity(0.12)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: cs.primary.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: cs.primary.withOpacity(0.14)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Text('🏆', style: TextStyle(fontSize: 28)),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Earn XP, levels, and ranks by finishing habits. Account is optional, but your profile avatar makes it feel like your own reward journey.',
                                          style: tt.bodySmall?.copyWith(height: 1.32),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  login ? 'Welcome back' : 'Create account',
                                  style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  login
                                      ? 'Login is optional. Continue as guest now, or sign in to keep your profile identity clean.'
                                      : 'Pick a nickname, add an optional avatar, and make the reward profile feel like yours.',
                                  style: tt.bodyMedium?.copyWith(
                                    color: cs.onSurface.withOpacity(0.72),
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _buildAvatarPicker(cs, tt),
                                if (!login) ...[
                                  TextFormField(
                                    controller: _nickname,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [AutofillHints.nickname],
                                    validator: _validateNickname,
                                    decoration: const InputDecoration(
                                      labelText: 'Nickname',
                                      hintText: 'ShadowRunner',
                                      prefixIcon: Icon(Icons.badge_outlined),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                ],
                                TextFormField(
                                  controller: _email,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.email],
                                  validator: _validateEmail,
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                    hintText: 'you@example.com',
                                    prefixIcon: Icon(Icons.alternate_email_rounded),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _password,
                                  textInputAction: login ? TextInputAction.done : TextInputAction.next,
                                  autofillHints: login
                                      ? const [AutofillHints.password]
                                      : const [AutofillHints.newPassword],
                                  validator: _validatePassword,
                                  obscureText: _hidePassword,
                                  onFieldSubmitted: (_) {
                                    if (login && !loading) submit();
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                                    suffixIcon: IconButton(
                                      onPressed: () => setState(() => _hidePassword = !_hidePassword),
                                      icon: Icon(
                                        _hidePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                      ),
                                    ),
                                  ),
                                ),
                                if (!login) ...[
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _confirmPassword,
                                    textInputAction: TextInputAction.done,
                                    autofillHints: const [AutofillHints.newPassword],
                                    validator: _validateConfirmPassword,
                                    obscureText: _hideConfirmPassword,
                                    onFieldSubmitted: (_) {
                                      if (!loading) submit();
                                    },
                                    decoration: InputDecoration(
                                      labelText: 'Confirm password',
                                      prefixIcon: const Icon(Icons.lock_reset_rounded),
                                      suffixIcon: IconButton(
                                        onPressed: () => setState(
                                          () => _hideConfirmPassword = !_hideConfirmPassword,
                                        ),
                                        icon: Icon(
                                          _hideConfirmPassword
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    onPressed: loading ? null : submit,
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 15),
                                    ),
                                    child: loading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text(login ? 'Login' : 'Create profile'),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: TextButton(
                                    onPressed: loading ? null : _toggleMode,
                                    child: Text(
                                      login
                                          ? 'Create profile instead'
                                          : 'Already have an account? Login',
                                    ),
                                  ),
                                ),
                                if (widget.onContinueAsGuest != null) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(child: Divider(color: cs.outline.withOpacity(0.20))),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        child: Text(
                                          'or',
                                          style: tt.bodySmall?.copyWith(color: cs.onSurface.withOpacity(0.58)),
                                        ),
                                      ),
                                      Expanded(child: Divider(color: cs.outline.withOpacity(0.20))),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: loading ? null : widget.onContinueAsGuest,
                                      icon: const Icon(Icons.person_outline_rounded),
                                      label: const Text('Continue without account'),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Guest mode keeps all current habit features on this device. You can create an account later from Settings.',
                                    textAlign: TextAlign.center,
                                    style: tt.bodySmall?.copyWith(color: cs.onSurface.withOpacity(0.62), height: 1.3),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
