import 'package:flutter/widgets.dart';

class AppLanguage {
  final String code;
  final String name;
  final String nativeName;

  const AppLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
  });
}

class AppLocalizations {
  static const String prefKey = 'app_language_code';
  static const String fallbackCode = 'en';

  static const List<AppLanguage> supportedLanguages = <AppLanguage>[
    AppLanguage(code: 'en', name: 'English', nativeName: 'English'),
    AppLanguage(code: 'ru', name: 'Russian', nativeName: 'Русский'),
    AppLanguage(code: 'mn', name: 'Mongolian', nativeName: 'Монгол'),
  ];

  static String _languageCode = fallbackCode;

  static String get languageCode => _languageCode;

  static Locale get locale => Locale(_languageCode);

  static void setLanguage(String code) {
    _languageCode = isSupported(code) ? code : fallbackCode;
  }

  static bool isSupported(String code) {
    return supportedLanguages.any((language) => language.code == code);
  }

  static AppLanguage languageFor(String code) {
    return supportedLanguages.firstWhere(
      (language) => language.code == code,
      orElse: () => supportedLanguages.first,
    );
  }

  static String text(String english) {
    if (_languageCode == fallbackCode) return english;
    return _localizedValues[_languageCode]?[english] ?? english;
  }

  static String format(String english, Map<String, Object> values) {
    var result = text(english);
    for (final entry in values.entries) {
      result = result.replaceAll('{${entry.key}}', entry.value.toString());
    }
    return result;
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'ru': {
      'Habit Dashboard': 'Habit Dashboard',
      'Daily Habit Dashboard': 'Daily Habit Dashboard',
      'Build better routines. Quit bad ones.': 'Создавай полезные привычки. Убирай вредные.',
      'Today': 'Сегодня',
      'Daily progress': 'Прогресс за день',
      '{done} / {total} habits completed': '{done} / {total} привычек выполнено',
      'No habits yet': 'Привычек пока нет',
      'Tap + to add your first habit.': 'Нажми +, чтобы добавить первую привычку.',
      'Perfect day': 'Идеальный день',
      'Strong momentum': 'Хороший темп',
      'Keep it going': 'Продолжай',
      'Fresh start': 'Новый старт',
      'Mon': 'Пн',
      'Tue': 'Вт',
      'Wed': 'Ср',
      'Thu': 'Чт',
      'Fri': 'Пт',
      'Sat': 'Сб',
      'Sun': 'Вс',
      'Settings & preferences': 'Настройки',
      'Tune startup behavior, appearance, and launch-ready info without touching your habit data.': 'Настрой запуск, внешний вид и информацию для релиза, не трогая данные привычек.',
      'Your experience, your defaults': 'Твой опыт, твои настройки',
      'Pick how the app opens, how the dashboard behaves, and what’s ready for demos or Play Market presentation.': 'Выбери, как открывается приложение, как ведёт себя дашборд и что готово для демо или Play Market.',
      'Appearance': 'Внешний вид',
      'Dark mode': 'Тёмная тема',
      'Use the darker look across the app.': 'Использовать тёмный вид во всём приложении.',
      'Use the lighter look across the app.': 'Использовать светлый вид во всём приложении.',
      'Language': 'Язык',
      'App language': 'Язык приложения',
      'Switch between English, Russian, and Mongolian.': 'Переключайся между английским, русским и монгольским.',
      'Language updated.': 'Язык обновлён.',
      'Home screen defaults': 'Настройки главного экрана',
      'Choose how the dashboard should look when you open the app.': 'Выбери, как должен выглядеть дашборд при запуске.',
      'Default filter': 'Фильтр по умолчанию',
      'All habits': 'Все привычки',
      'Active only': 'Только активные',
      'Completed today': 'Выполнены сегодня',
      'Build habits': 'Полезные привычки',
      'Quit habits': 'Отказ от вредных',
      'Default sort': 'Сортировка по умолчанию',
      'Manual order': 'Ручной порядок',
      'Highest streak': 'Самая длинная серия',
      'Name': 'Название',
      'Today status': 'Статус сегодня',
      'Show archived section on startup': 'Показывать архив при запуске',
      'Keep archived habits visible when the dashboard opens.': 'Архивные привычки будут видны при открытии дашборда.',
      'Expand archived section on startup': 'Раскрывать архив при запуске',
      'Useful if you often restore or review older habits.': 'Удобно, если часто восстанавливаешь или смотришь старые привычки.',
      'Account': 'Аккаунт',
      'Guest mode': 'Гостевой режим',
      'No account required. Your habits, XP, ranks, and settings stay on this device.': 'Аккаунт не нужен. Привычки, XP, ранги и настройки хранятся на этом устройстве.',
      'Create account / login': 'Создать аккаунт / войти',
      'Account is optional, but it lets you personalize your profile with an avatar and makes the reward profile feel more yours.': 'Аккаунт необязателен, но с ним можно добавить аватар и сделать профиль наград более личным.',
      'Show login screen on next launch': 'Показать экран входа при следующем запуске',
      'Turn off guest auto-entry and return to the account screen.': 'Отключить авто-вход гостем и вернуться к экрану аккаунта.',
      'Signed in account': 'Аккаунт активен',
      'Firebase account is active. Add a nickname to make your profile cleaner.': 'Firebase-аккаунт активен. Добавь ник, чтобы профиль выглядел аккуратнее.',
      'Edit nickname': 'Изменить ник',
      'Add avatar': 'Добавить аватар',
      'Change avatar': 'Сменить аватар',
      'Remove avatar': 'Удалить аватар',
      'Avatar supports normal image files. Nickname and avatar are used as your cleaner in-app profile identity.': 'Аватар поддерживает обычные изображения. Ник и аватар используются для профиля внутри приложения.',
      'Log out': 'Выйти',
      'Return to the login / registration screen.': 'Вернуться к экрану входа / регистрации.',
      'Launch & support': 'Релиз и поддержка',
      'Show onboarding again': 'Показать onboarding снова',
      'Useful before demos or if you want to review the intro flow.': 'Полезно перед демо или если хочешь снова посмотреть вступление.',
      'Reset': 'Сбросить',
      'About': 'О приложении',
      'App version, product summary, and support basics.': 'Версия приложения, описание продукта и базовая поддержка.',
      'Privacy policy': 'Политика конфиденциальности',
      'Check the local privacy policy included with the app.': 'Открыть локальную политику конфиденциальности внутри приложения.',
      'Support': 'Поддержка',
      'Find the contact address and basic help info.': 'Контакты и базовая справочная информация.',
      'These preferences change only the app experience and startup defaults. Your habits, streaks, backups, and analytics stay untouched.': 'Эти настройки меняют только интерфейс и запуск. Привычки, серии, бэкапы и аналитика не трогаются.',
      'Search habits...': 'Поиск привычек...',
      'Clear': 'Очистить',
      'Stats': 'Статистика',
      'Menu': 'Меню',
      'Mark all done (today)': 'Отметить всё выполненным сегодня',
      'Reset today': 'Сбросить сегодня',
      'Collapse archived habits': 'Скрыть архивные привычки',
      'Expand archived habits': 'Показать архивные привычки',
      'Switch to Light Mode': 'Переключить на светлую тему',
      'Switch to Dark Mode': 'Переключить на тёмную тему',
      'Copy backup text': 'Скопировать текст бэкапа',
      'Restore from pasted text': 'Восстановить из текста',
      'Save backup file': 'Сохранить файл бэкапа',
      'Import backup file': 'Импортировать файл бэкапа',
      'Restore points': 'Точки восстановления',
      'Settings': 'Настройки',
      'Done': 'Готово',
      'Restore from clipboard': 'Восстановить из буфера',
      'Paste your backup text below (auto-filled from clipboard if available).': 'Вставь текст бэкапа ниже (если возможно, он подставится из буфера).',
      'Close': 'Закрыть',
      'Restore': 'Восстановить',
      'Auto-created before imports and destructive actions.': 'Автоматически создаётся перед импортом и опасными действиями.',
      'No restore points yet.': 'Точек восстановления пока нет.',
      'Weekly review': 'Недельный обзор',
      'Welcome to Habit Dashboard': 'Добро пожаловать в Habit Dashboard',
      'A cleaner start for building good habits, quitting bad ones, and tracking streaks without clutter.': 'Удобный старт для полезных привычек, отказа от вредных и отслеживания серий без лишнего мусора.',
      'Track routines like water, workouts, reading, sleep, coding, or study goals.': 'Отслеживай воду, тренировки, чтение, сон, кодинг или учебные цели.',
      'Use clean streaks for smoking, alcohol, vaping, sugar, junk food, and more.': 'Используй серии для отказа от курения, алкоголя, вейпа, сахара, фастфуда и другого.',
      'Stay motivated': 'Держи мотивацию',
      'History, milestones, reminders, notes, archive, and backup are already built in.': 'История, достижения, напоминания, заметки, архив и бэкапы уже встроены.',
      'Start clean with your own first habit, or load a few example habits to explore the app faster.': 'Начни со своей первой привычки или загрузи примеры, чтобы быстрее изучить приложение.',
      'Create first habit': 'Создать первую привычку',
      'Start with examples': 'Начать с примеров',
      'Nickname': 'Ник',
      'Cancel': 'Отмена',
      'Save': 'Сохранить',
      'Profile avatar updated.': 'Аватар обновлён.',
      'Profile avatar removed.': 'Аватар удалён.',
      'Could not read this image. Try another one.': 'Не удалось прочитать изображение. Попробуй другое.',
      'Pick a smaller image under 2 MB.': 'Выбери изображение меньше 2 МБ.',
      'Adjust avatar': 'Настроить аватар',
      'Move and zoom the photo until your profile avatar looks right.': 'Двигай и увеличивай фото, пока аватар не будет выглядеть нормально.',
      'Could not open image picker.': 'Не удалось открыть выбор изображения.',
      'Nickname updated.': 'Ник обновлён.',
      'Nickname must be 2–20 characters.': 'Ник должен быть 2–20 символов.',
      'Use letters, numbers, spaces, _, - or .': 'Используй буквы, цифры, пробелы, _, - или .',
      'Could not update nickname. Try again.': 'Не удалось обновить ник. Попробуй снова.',
      'Onboarding will appear again next launch.': 'Onboarding появится при следующем запуске.',
    },
    'mn': {
      'Habit Dashboard': 'Habit Dashboard',
      'Daily Habit Dashboard': 'Daily Habit Dashboard',
      'Build better routines. Quit bad ones.': 'Сайн дадал үүсгэ. Муу дадлаа орхи.',
      'Today': 'Өнөөдөр',
      'Daily progress': 'Өдрийн явц',
      '{done} / {total} habits completed': '{done} / {total} дадал биелсэн',
      'No habits yet': 'Одоогоор дадал алга',
      'Tap + to add your first habit.': '+ дээр дарж эхний дадлаа нэм.',
      'Perfect day': 'Төгс өдөр',
      'Strong momentum': 'Сайн хэмнэл',
      'Keep it going': 'Үргэлжлүүлээрэй',
      'Fresh start': 'Шинэ эхлэл',
      'Mon': 'Да',
      'Tue': 'Мя',
      'Wed': 'Лх',
      'Thu': 'Пү',
      'Fri': 'Ба',
      'Sat': 'Бя',
      'Sun': 'Ня',
      'Settings & preferences': 'Тохиргоо',
      'Tune startup behavior, appearance, and launch-ready info without touching your habit data.': 'Дадлын өгөгдөлд хүрэлгүйгээр эхлэх байдал, харагдац, релизийн мэдээллээ тохируул.',
      'Your experience, your defaults': 'Чиний хэрэглээ, чиний тохиргоо',
      'Pick how the app opens, how the dashboard behaves, and what’s ready for demos or Play Market presentation.': 'Апп хэрхэн нээгдэх, самбар хэрхэн ажиллах, демо болон Play Market-д юу бэлэн байхыг сонго.',
      'Appearance': 'Харагдац',
      'Dark mode': 'Харанхуй горим',
      'Use the darker look across the app.': 'Апп даяар харанхуй загвар ашиглах.',
      'Use the lighter look across the app.': 'Апп даяар цайвар загвар ашиглах.',
      'Language': 'Хэл',
      'App language': 'Аппын хэл',
      'Switch between English, Russian, and Mongolian.': 'Англи, орос, монгол хэлний хооронд солино.',
      'Language updated.': 'Хэл шинэчлэгдлээ.',
      'Home screen defaults': 'Нүүр дэлгэцийн үндсэн тохиргоо',
      'Choose how the dashboard should look when you open the app.': 'Апп нээхэд самбар хэрхэн харагдахыг сонго.',
      'Default filter': 'Үндсэн шүүлтүүр',
      'All habits': 'Бүх дадал',
      'Active only': 'Зөвхөн идэвхтэй',
      'Completed today': 'Өнөөдөр биелсэн',
      'Build habits': 'Сайн дадал',
      'Quit habits': 'Муу дадал орхих',
      'Default sort': 'Үндсэн эрэмбэ',
      'Manual order': 'Гараар эрэмбэлэх',
      'Highest streak': 'Хамгийн урт цуврал',
      'Name': 'Нэр',
      'Today status': 'Өнөөдрийн төлөв',
      'Show archived section on startup': 'Эхлэхэд архив харуулах',
      'Keep archived habits visible when the dashboard opens.': 'Самбар нээгдэхэд архивласан дадлууд харагдана.',
      'Expand archived section on startup': 'Эхлэхэд архивыг дэлгэх',
      'Useful if you often restore or review older habits.': 'Хуучин дадал сэргээх эсвэл шалгах үед хэрэгтэй.',
      'Account': 'Аккаунт',
      'Guest mode': 'Зочин горим',
      'No account required. Your habits, XP, ranks, and settings stay on this device.': 'Аккаунт шаардлагагүй. Дадал, XP, зэрэглэл, тохиргоо энэ төхөөрөмж дээр хадгалагдана.',
      'Create account / login': 'Аккаунт үүсгэх / нэвтрэх',
      'Account is optional, but it lets you personalize your profile with an avatar and makes the reward profile feel more yours.': 'Аккаунт заавал биш, гэхдээ аватар нэмэх болон шагналын профайлыг хувийн болгоход тусална.',
      'Show login screen on next launch': 'Дараагийн нээлтэд нэвтрэх дэлгэц харуулах',
      'Turn off guest auto-entry and return to the account screen.': 'Зочин auto-entry-г унтрааж аккаунтын дэлгэц рүү буцна.',
      'Signed in account': 'Нэвтэрсэн аккаунт',
      'Firebase account is active. Add a nickname to make your profile cleaner.': 'Firebase аккаунт идэвхтэй. Профайлаа цэвэрхэн болгохын тулд хоч нэм.',
      'Edit nickname': 'Хоч засах',
      'Add avatar': 'Аватар нэмэх',
      'Change avatar': 'Аватар солих',
      'Remove avatar': 'Аватар устгах',
      'Avatar supports normal image files. Nickname and avatar are used as your cleaner in-app profile identity.': 'Аватар энгийн зураг дэмжинэ. Хоч ба аватар нь апп доторх профайлд ашиглагдана.',
      'Log out': 'Гарах',
      'Return to the login / registration screen.': 'Нэвтрэх / бүртгүүлэх дэлгэц рүү буцах.',
      'Launch & support': 'Релиз ба тусламж',
      'Show onboarding again': 'Onboarding дахин харуулах',
      'Useful before demos or if you want to review the intro flow.': 'Демо өмнө эсвэл танилцуулгыг дахин харахад хэрэгтэй.',
      'Reset': 'Сброс',
      'About': 'Тухай',
      'App version, product summary, and support basics.': 'Аппын хувилбар, бүтээгдэхүүний товч, тусламжийн үндэс.',
      'Privacy policy': 'Нууцлалын бодлого',
      'Check the local privacy policy included with the app.': 'Апптай хамт байгаа локал нууцлалын бодлогыг харах.',
      'Support': 'Тусламж',
      'Find the contact address and basic help info.': 'Холбоо барих хаяг болон үндсэн тусламжийн мэдээлэл.',
      'These preferences change only the app experience and startup defaults. Your habits, streaks, backups, and analytics stay untouched.': 'Эдгээр тохиргоо зөвхөн аппын хэрэглээ ба эхлэх тохиргоог өөрчилнө. Дадал, streak, backup, analytics өөрчлөгдөхгүй.',
      'Search habits...': 'Дадал хайх...',
      'Clear': 'Цэвэрлэх',
      'Stats': 'Статистик',
      'Menu': 'Цэс',
      'Mark all done (today)': 'Өнөөдөр бүгдийг биелсэн болгох',
      'Reset today': 'Өнөөдрийг цэвэрлэх',
      'Collapse archived habits': 'Архивласан дадлыг хураах',
      'Expand archived habits': 'Архивласан дадлыг дэлгэх',
      'Switch to Light Mode': 'Цайвар горим руу солих',
      'Switch to Dark Mode': 'Харанхуй горим руу солих',
      'Copy backup text': 'Backup текст хуулах',
      'Restore from pasted text': 'Текстээс сэргээх',
      'Save backup file': 'Backup файл хадгалах',
      'Import backup file': 'Backup файл импортлох',
      'Restore points': 'Сэргээх цэгүүд',
      'Settings': 'Тохиргоо',
      'Done': 'Дууссан',
      'Restore from clipboard': 'Clipboard-оос сэргээх',
      'Paste your backup text below (auto-filled from clipboard if available).': 'Backup текстээ доор оруул. Боломжтой бол clipboard-оос автоматаар бөглөгдөнө.',
      'Close': 'Хаах',
      'Restore': 'Сэргээх',
      'Auto-created before imports and destructive actions.': 'Импорт болон устгах үйлдлийн өмнө автоматаар үүснэ.',
      'No restore points yet.': 'Одоогоор сэргээх цэг алга.',
      'Weekly review': 'Долоо хоногийн тойм',
      'Welcome to Habit Dashboard': 'Habit Dashboard-д тавтай морил',
      'A cleaner start for building good habits, quitting bad ones, and tracking streaks without clutter.': 'Сайн дадал үүсгэх, мууг орхих, streak хөтлөх цэвэрхэн эхлэл.',
      'Track routines like water, workouts, reading, sleep, coding, or study goals.': 'Ус, дасгал, унших, нойр, coding, хичээлийн зорилго гэх мэт routine хяна.',
      'Use clean streaks for smoking, alcohol, vaping, sugar, junk food, and more.': 'Тамхи, архи, vape, сахар, junk food болон бусдыг орхих streak ашигла.',
      'Stay motivated': 'Урамтай бай',
      'History, milestones, reminders, notes, archive, and backup are already built in.': 'Түүх, milestone, reminder, тэмдэглэл, архив, backup бүгд бэлэн.',
      'Start clean with your own first habit, or load a few example habits to explore the app faster.': 'Өөрийн эхний дадлаар эхэл эсвэл аппыг хурдан үзэхийн тулд жишээ дадлууд ачаал.',
      'Create first habit': 'Эхний дадал үүсгэх',
      'Start with examples': 'Жишээгээр эхлэх',
      'Nickname': 'Хоч',
      'Cancel': 'Болих',
      'Save': 'Хадгалах',
      'Profile avatar updated.': 'Аватар шинэчлэгдлээ.',
      'Profile avatar removed.': 'Аватар устгагдлаа.',
      'Could not read this image. Try another one.': 'Энэ зургийг уншиж чадсангүй. Өөр зураг сонго.',
      'Pick a smaller image under 2 MB.': '2 MB-аас бага зураг сонго.',
      'Adjust avatar': 'Аватар тохируулах',
      'Move and zoom the photo until your profile avatar looks right.': 'Профайл аватар зөв харагдтал зургийг хөдөлгөж томруул.',
      'Could not open image picker.': 'Зураг сонгогч нээгдсэнгүй.',
      'Nickname updated.': 'Хоч шинэчлэгдлээ.',
      'Nickname must be 2–20 characters.': 'Хоч 2–20 тэмдэгт байх ёстой.',
      'Use letters, numbers, spaces, _, - or .': 'Үсэг, тоо, зай, _, - эсвэл . ашигла.',
      'Could not update nickname. Try again.': 'Хоч шинэчилж чадсангүй. Дахин оролд.',
      'Onboarding will appear again next launch.': 'Onboarding дараагийн нээлтэд дахин гарна.',
    },
  };
}

extension LocalizedStringExtension on String {
  String get tr => AppLocalizations.text(this);

  String trFormat(Map<String, Object> values) {
    return AppLocalizations.format(this, values);
  }
}
