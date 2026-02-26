// Facade with platform-specific implementations.
// - Web: no-op (so the app can run in browsers)
// - IO platforms (Android/iOS/Windows/macOS/Linux): real notifications

import 'notification_service_web.dart'
    if (dart.library.io) 'notification_service_mobile.dart';

export 'notification_service_web.dart'
    if (dart.library.io) 'notification_service_mobile.dart';