import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:habit_dashboard/app/theme.dart';
import 'package:habit_dashboard/core/localization/app_localizations.dart';
import 'package:habit_dashboard/features/auth/data/auth_service.dart';
import 'package:habit_dashboard/features/auth/presentation/auth_screen.dart';
import 'package:habit_dashboard/features/habits/presentation/home/home_screen.dart';
import 'package:habit_dashboard/features/onboarding/presentation/onboarding_screen.dart';

class MyApp extends StatefulWidget {
  final bool initialDarkMode;
  final String initialLanguageCode;

  const MyApp({
    super.key,
    required this.initialDarkMode,
    required this.initialLanguageCode,
  });

  static MyAppState? of(BuildContext context) {
    return context.findAncestorStateOfType<MyAppState>();
  }

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late bool _isDarkMode;
  late String _languageCode;

  static const String _lastOpenedDayPrefKey = 'last_opened_day';
  String _lastKnownDayKey = _dayKeyFrom(DateTime.now());

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.initialDarkMode;
    _languageCode = AppLocalizations.isSupported(widget.initialLanguageCode)
        ? widget.initialLanguageCode
        : AppLocalizations.fallbackCode;
    AppLocalizations.setLanguage(_languageCode);

    WidgetsBinding.instance.addObserver(this);
    _ensureDayIsFresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _ensureDayIsFresh();
    }
  }

  static String _dayKeyFrom(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  Future<void> _ensureDayIsFresh() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _dayKeyFrom(DateTime.now());
    final last = prefs.getString(_lastOpenedDayPrefKey);

    if (last != today) {
      await prefs.setString(_lastOpenedDayPrefKey, today);
    }

    if (_lastKnownDayKey != today) {
      _lastKnownDayKey = today;
      if (!mounted) return;
      setState(() {});
    }
  }

  bool get isDarkMode => _isDarkMode;

  String get languageCode => _languageCode;

  Future<void> setLanguageCode(String code) async {
    if (!AppLocalizations.isSupported(code) || _languageCode == code) return;
    final prefs = await SharedPreferences.getInstance();
    _languageCode = code;
    AppLocalizations.setLanguage(code);
    await prefs.setString(AppLocalizations.prefKey, code);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> toggleDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = !_isDarkMode;
    await prefs.setBool('is_dark_mode', _isDarkMode);
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      darkTheme: buildDarkAppTheme(),
      locale: AppLocalizations.locale,
      supportedLocales: AppLocalizations.supportedLanguages
          .map((language) => Locale(language.code))
          .toList(growable: false),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const _AppEntry(),
    );
  }
}

class _AppEntry extends StatefulWidget {
  const _AppEntry();

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  static const _seenOnboardingKey = 'seen_onboarding_v1';
  static const _guestModeKey = 'continue_without_account_v1';

  final AuthService _authService = AuthService();

  bool _showSplash = true;
  bool _hasSeenOnboarding = false;
  bool _guestMode = false;
  bool _prefsLoaded = false;

  @override
  void initState() {
    super.initState();
    _load();
    _holdSplash();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _hasSeenOnboarding = prefs.getBool(_seenOnboardingKey) ?? false;
    _guestMode = prefs.getBool(_guestModeKey) ?? false;
    if (!mounted) return;
    setState(() => _prefsLoaded = true);
  }

  Future<void> _holdSplash() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _showSplash = false);
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenOnboardingKey, true);
    if (!mounted) return;
    setState(() => _hasSeenOnboarding = true);
  }

  Future<void> _continueWithoutAccount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_guestModeKey, true);
    if (!mounted) return;
    setState(() => _guestMode = true);
  }

  Widget _buildReleaseReadyFlow() {
    return StreamBuilder(
      stream: _authService.authState,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _BrandSplashScreen();
        }

        final user = snapshot.data;
        final canUseApp = user != null || _guestMode;

        // First real screen after splash: account choice / auth.
        // Onboarding is shown only after the user signs in or chooses guest mode.
        if (!canUseApp) {
          return AuthScreen(onContinueAsGuest: _continueWithoutAccount);
        }

        if (!_hasSeenOnboarding) {
          return OnboardingScreen(onFinished: _completeOnboarding);
        }

        return const HomeScreen();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget child;
    if (_showSplash || !_prefsLoaded) {
      child = const _BrandSplashScreen();
    } else {
      child = _buildReleaseReadyFlow();
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: KeyedSubtree(
        key: ValueKey(
          '${_showSplash}_${_prefsLoaded}_${_hasSeenOnboarding}_${_guestMode}',
        ),
        child: child,
      ),
    );
  }
}

class _BrandSplashScreen extends StatelessWidget {
  const _BrandSplashScreen();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cs.primary.withOpacity(0.16),
              cs.secondary.withOpacity(0.08),
              cs.surface,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.asset(
                  'assets/branding/app_mark.png',
                  width: 104,
                  height: 104,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      size: 52,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Habit Dashboard'.tr,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Build better routines. Quit bad ones.'.tr,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface.withOpacity(0.72),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}