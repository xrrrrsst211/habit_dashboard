import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:habit_dashboard/core/localization/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:habit_dashboard/app/app.dart';
import 'package:habit_dashboard/core/widgets/app_scaffold.dart';
import 'package:habit_dashboard/core/widgets/polished_feedback.dart';
import 'package:habit_dashboard/core/widgets/image_crop_editor.dart';
import 'package:habit_dashboard/features/about/about_screen.dart';
import 'package:habit_dashboard/features/auth/data/auth_service.dart';
import 'package:habit_dashboard/features/auth/data/profile_avatar_service.dart';
import 'package:habit_dashboard/features/auth/presentation/auth_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _prefHomeFilterKey = 'pref_home_filter';
  static const String _prefHomeSortKey = 'pref_home_sort';
  static const String _prefShowArchivedKey = 'pref_show_archived';
  static const String _prefExpandArchivedKey = 'pref_expand_archived';
  static const String _seenOnboardingKey = 'seen_onboarding_v1';
  static const String _guestModeKey = 'continue_without_account_v1';

  final AuthService _authService = AuthService();
  final ProfileAvatarService _avatarService = ProfileAvatarService();

  bool _loading = true;
  bool _avatarBusy = false;
  bool _profileBusy = false;
  bool _showArchived = false;
  bool _expandArchived = false;
  int _filterIndex = 0;
  int _sortIndex = 0;
  User? _user;
  Uint8List? _avatarBytes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final user = _authService.currentUser;
    Uint8List? avatarBytes;

    if (user != null) {
      final avatarBase64 = await _avatarService.getAvatarBase64(user.uid);
      avatarBytes = _avatarService.decode(avatarBase64);
    }

    if (!mounted) return;
    setState(() {
      _filterIndex = prefs.getInt(_prefHomeFilterKey) ?? 0;
      _sortIndex = prefs.getInt(_prefHomeSortKey) ?? 0;
      _showArchived = prefs.getBool(_prefShowArchivedKey) ?? false;
      _expandArchived = prefs.getBool(_prefExpandArchivedKey) ?? false;
      _user = user;
      _avatarBytes = avatarBytes;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefHomeFilterKey, _filterIndex);
    await prefs.setInt(_prefHomeSortKey, _sortIndex);
    await prefs.setBool(_prefShowArchivedKey, _showArchived);
    await prefs.setBool(_prefExpandArchivedKey, _expandArchived);
  }

  Future<void> _setShowArchived(bool value) async {
    setState(() {
      _showArchived = value;
      if (!value) _expandArchived = false;
    });
    await _save();
  }

  Future<void> _setExpandArchived(bool value) async {
    setState(() => _expandArchived = value);
    await _save();
  }

  Future<void> _setFilter(int value) async {
    setState(() => _filterIndex = value);
    await _save();
  }

  Future<void> _setSort(int value) async {
    setState(() => _sortIndex = value);
    await _save();
  }


  Future<void> _pickProfileAvatar() async {
    final user = _authService.currentUser;
    if (user == null) return;

    try {
      setState(() => _avatarBusy = true);
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final bytes = result.files.single.bytes;
      if (bytes == null) {
        if (!mounted) return;
        showAppSnackBar(
          context,
          'Could not read this image. Try another one.'.tr,
          icon: Icons.error_outline_rounded,
        );
        return;
      }

      if (bytes.length > ProfileAvatarService.maxAvatarBytes) {
        if (!mounted) return;
        showAppSnackBar(
          context,
          'Pick a smaller image under 2 MB.'.tr,
          icon: Icons.image_not_supported_outlined,
        );
        return;
      }

      if (!mounted) return;
      final cropped = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute(
          builder: (_) => ImageCropEditorScreen(
            imageBytes: bytes,
            circular: true,
            title: 'Adjust avatar'.tr,
            helpText: 'Move and zoom the photo until your profile avatar looks right.'.tr,
          ),
        ),
      );

      if (!mounted || cropped == null) return;
      await _avatarService.saveAvatarBytes(user.uid, cropped);
      if (!mounted) return;
      setState(() => _avatarBytes = cropped);
      showAppSnackBar(
        context,
        'Profile avatar updated.'.tr,
        icon: Icons.check_circle_outline_rounded,
      );
    } catch (_) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        'Could not open image picker.'.tr,
        icon: Icons.error_outline_rounded,
      );
    } finally {
      if (mounted) setState(() => _avatarBusy = false);
    }
  }

  Future<void> _editDisplayName() async {
    final user = _authService.currentUser;
    if (user == null) return;

    final controller = TextEditingController(text: user.displayName ?? '');

    final nickname = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit nickname'.tr),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 20,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: 'Nickname'.tr,
            hintText: 'ShadowRunner',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
          onSubmitted: (value) => Navigator.pop(context, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'.tr),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text('Save'.tr),
          ),
        ],
      ),
    );

    controller.dispose();

    final clean = nickname?.trim() ?? '';
    if (clean.isEmpty) return;
    if (clean.length < 2 || clean.length > 20) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        'Nickname must be 2–20 characters.'.tr,
        icon: Icons.error_outline_rounded,
      );
      return;
    }

    final allowed = RegExp(r"^[a-zA-Z0-9_ .-]+$");
    if (!allowed.hasMatch(clean)) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        'Use letters, numbers, spaces, _, - or .'.tr,
        icon: Icons.error_outline_rounded,
      );
      return;
    }

    try {
      setState(() => _profileBusy = true);
      await _authService.updateDisplayName(clean);
      final updatedUser = _authService.currentUser;
      if (!mounted) return;
      setState(() => _user = updatedUser);
      showAppSnackBar(
        context,
        'Nickname updated.'.tr,
        icon: Icons.check_circle_outline_rounded,
      );
    } catch (_) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        'Could not update nickname. Try again.'.tr,
        icon: Icons.error_outline_rounded,
      );
    } finally {
      if (mounted) setState(() => _profileBusy = false);
    }
  }

  Future<void> _removeProfileAvatar() async {
    final user = _authService.currentUser;
    if (user == null) return;

    await _avatarService.removeAvatar(user.uid);
    if (!mounted) return;
    setState(() => _avatarBytes = null);
    showAppSnackBar(
      context,
      'Profile avatar removed.'.tr,
      icon: Icons.delete_outline_rounded,
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_guestModeKey, false);
    await _authService.logout();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _openAccountAuth() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AuthScreen(
          onSignedIn: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool(_guestModeKey, false);
            if (!mounted) return;
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ),
    );
    await _load();
  }

  Future<void> _resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenOnboardingKey, false);
    if (!mounted) return;
    showAppSnackBar(
      context,
      'Onboarding will appear again next launch.'.tr,
      icon: Icons.flag_outlined,
    );
  }

  Future<void> _openAbout(AboutSection section) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AboutScreen(initialSection: section),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final app = MyApp.of(context);
    final isDark =
        app?.isDarkMode ?? Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return AppScaffold(
      title: 'Settings & preferences'.tr,
      subtitle:
          'Tune startup behavior, appearance, and launch-ready info without touching your habit data.'.tr,
      body: ListView(
        children: [
          _HeroSettingsCard(
            title: 'Your experience, your defaults'.tr,
            subtitle:
                'Pick how the app opens, how the dashboard behaves, and what’s ready for demos or Play Market presentation.'.tr,
            icon: Icons.tune_rounded,
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Appearance'.tr,
            icon: Icons.palette_outlined,
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  value: isDark,
                  contentPadding: EdgeInsets.zero,
                  title: Text('Dark mode'.tr),
                  subtitle: Text(
                    isDark
                        ? 'Use the darker look across the app.'.tr
                        : 'Use the lighter look across the app.'.tr,
                  ),
                  onChanged: (_) async {
                    await app?.toggleDarkMode();
                    if (!mounted) return;
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Language'.tr,
            icon: Icons.language_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Switch between English, Russian, and Mongolian.'.tr,
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.72),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: app?.languageCode ?? AppLocalizations.languageCode,
                  decoration: InputDecoration(
                    labelText: 'App language'.tr,
                    prefixIcon: const Icon(Icons.translate_rounded),
                  ),
                  items: AppLocalizations.supportedLanguages
                      .map(
                        (language) => DropdownMenuItem<String>(
                          value: language.code,
                          child: Text(language.nativeName),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (code) async {
                    if (code == null) return;
                    await app?.setLanguageCode(code);
                    if (!mounted) return;
                    setState(() {});
                    showAppSnackBar(
                      context,
                      'Language updated.'.tr,
                      icon: Icons.translate_rounded,
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Home screen defaults'.tr,
            icon: Icons.home_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose how the dashboard should look when you open the app.'.tr,
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.72),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Default filter'.tr,
                  style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: _filterIndex,
                  items: [
                    DropdownMenuItem(value: 0, child: Text('All habits'.tr)),
                    DropdownMenuItem(value: 1, child: Text('Active only'.tr)),
                    DropdownMenuItem(
                      value: 2,
                      child: Text('Completed today'.tr),
                    ),
                    DropdownMenuItem(value: 3, child: Text('Build habits'.tr)),
                    DropdownMenuItem(value: 4, child: Text('Quit habits'.tr)),
                  ],
                  onChanged: (value) {
                    if (value != null) _setFilter(value);
                  },
                ),
                const SizedBox(height: 14),
                Text(
                  'Default sort'.tr,
                  style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: _sortIndex,
                  items: [
                    DropdownMenuItem(value: 0, child: Text('Manual order'.tr)),
                    DropdownMenuItem(value: 1, child: Text('Highest streak'.tr)),
                    DropdownMenuItem(value: 2, child: Text('Name'.tr)),
                    DropdownMenuItem(value: 3, child: Text('Today status'.tr)),
                  ],
                  onChanged: (value) {
                    if (value != null) _setSort(value);
                  },
                ),
                const SizedBox(height: 10),
                SwitchListTile.adaptive(
                  value: _showArchived,
                  contentPadding: EdgeInsets.zero,
                  title: Text('Show archived section on startup'.tr),
                  subtitle: Text(
                    'Keep archived habits visible when the dashboard opens.'.tr,
                  ),
                  onChanged: _setShowArchived,
                ),
                SwitchListTile.adaptive(
                  value: _expandArchived,
                  contentPadding: EdgeInsets.zero,
                  title: Text('Expand archived section on startup'.tr),
                  subtitle: Text(
                    'Useful if you often restore or review older habits.'.tr,
                  ),
                  onChanged: _showArchived ? _setExpandArchived : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Account'.tr,
            icon: Icons.person_outline_rounded,
            child: _AccountSettingsPanel(
              user: _user,
              avatarBytes: _avatarBytes,
              avatarBusy: _avatarBusy,
              profileBusy: _profileBusy,
              onPickAvatar: _pickProfileAvatar,
              onRemoveAvatar: _removeProfileAvatar,
              onEditDisplayName: _editDisplayName,
              onLogout: _logout,
              onOpenAccountAuth: _openAccountAuth,
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Launch & support'.tr,
            icon: Icons.rocket_launch_outlined,
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.flag_circle_outlined),
                  title: Text('Show onboarding again'.tr),
                  subtitle: Text(
                    'Useful before demos or if you want to review the intro flow.'.tr,
                  ),
                  trailing: TextButton(
                    onPressed: _resetOnboarding,
                    child: Text('Reset'.tr),
                  ),
                ),
                const Divider(height: 20),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.info_outline_rounded),
                  title: Text('About'.tr),
                  subtitle: Text(
                    'App version, product summary, and support basics.'.tr,
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _openAbout(AboutSection.about),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: Text('Privacy policy'.tr),
                  subtitle: Text(
                    'Check the local privacy policy included with the app.'.tr,
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _openAbout(AboutSection.privacy),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.support_agent_rounded),
                  title: Text('Support'.tr),
                  subtitle: Text(
                    'Find the contact address and basic help info.'.tr,
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _openAbout(AboutSection.support),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: cs.primary.withValues(alpha: 0.14)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle_outline_rounded, color: cs.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'These preferences change only the app experience and startup defaults. Your habits, streaks, backups, and analytics stay untouched.'.tr,
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.84),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}


class _AccountSettingsPanel extends StatelessWidget {
  final User? user;
  final Uint8List? avatarBytes;
  final bool avatarBusy;
  final bool profileBusy;
  final VoidCallback onPickAvatar;
  final VoidCallback onRemoveAvatar;
  final VoidCallback onEditDisplayName;
  final VoidCallback onLogout;
  final VoidCallback onOpenAccountAuth;

  const _AccountSettingsPanel({
    required this.user,
    required this.avatarBytes,
    required this.avatarBusy,
    required this.profileBusy,
    required this.onPickAvatar,
    required this.onRemoveAvatar,
    required this.onEditDisplayName,
    required this.onLogout,
    required this.onOpenAccountAuth,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    if (user == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cs.primary.withValues(alpha: 0.12),
                  border: Border.all(color: cs.primary.withValues(alpha: 0.20)),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.person_outline_rounded, size: 36, color: cs.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Guest mode',
                      style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'No account required. Your habits, XP, ranks, and settings stay on this device.'.tr,
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.68),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onOpenAccountAuth,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: Text('Create account / login'.tr),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Account is optional, but it lets you personalize your profile with an avatar and makes the reward profile feel more yours.'.tr,
            style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.62)),
          ),
          const Divider(height: 24),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.login_rounded),
            title: Text('Show login screen on next launch'.tr),
            subtitle: Text('Turn off guest auto-entry and return to the account screen.'.tr),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: onLogout,
          ),
        ],
      );
    }

    final nickname = user?.displayName?.trim() ?? '';
    final email = user?.email ?? 'Signed in account';
    final title = nickname.isEmpty ? email : nickname;
    final subtitle = nickname.isEmpty
        ? 'Firebase account is active. Add a nickname to make your profile cleaner.'.tr
        : email;
    final avatar = avatarBytes == null
        ? Icon(Icons.person_rounded, size: 34, color: cs.primary)
        : Image.memory(
            avatarBytes!,
            fit: BoxFit.cover,
            gaplessPlayback: true,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 72,
              height: 72,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.primary.withValues(alpha: 0.12),
                border: Border.all(color: cs.primary.withValues(alpha: 0.20)),
              ),
              child: avatar,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        tooltip: 'Edit nickname',
                        visualDensity: VisualDensity.compact,
                        onPressed: profileBusy ? null : onEditDisplayName,
                        icon: profileBusy
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.edit_outlined, size: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.68),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: avatarBusy ? null : onPickAvatar,
                icon: avatarBusy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_a_photo_outlined),
                label: Text(avatarBytes == null ? 'Add avatar' : 'Change avatar'),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.outlined(
              tooltip: 'Remove avatar',
              onPressed: avatarBytes == null || avatarBusy ? null : onRemoveAvatar,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Avatar supports normal image files. Nickname and avatar are used as your cleaner in-app profile identity.'.tr,
          style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.62)),
        ),
        const Divider(height: 24),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.logout_rounded),
          title: Text('Log out'.tr),
          subtitle: Text('Return to the login / registration screen.'.tr),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onLogout,
        ),
      ],
    );
  }
}

class _HeroSettingsCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _HeroSettingsCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary.withValues(alpha: 0.12),
            cs.secondary.withValues(alpha: 0.06),
            cs.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: cs.primary, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.78),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}