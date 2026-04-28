# Habit Tracker Pro 📱

Aplikasi Flutter untuk tracking kebiasaan harian dengan fitur lengkap termasuk streak, statistik, dan reminder notifikasi.

## ✨ Fitur Utama

### 🔥 **STREAK SYSTEM**
- Hitung rentetan hari berturut-turut habit diselesaikan
- Reset otomatis jika hari terlewat
- Badge achievement (7 hari, 30 hari, 100 hari)
- Visual streak counter di setiap habit

### 📊 **STATISTIK & PROGRESS**
- Grafik mingguan (Line Chart) dan bulanan (Bar Chart)
- Progress completion rate harian
- Total habit selesai per periode
- Achievement badges berdasarkan streak

### 🔔 **REMINDER NOTIFIKASI**
- Notifikasi harian customizable
- Set waktu reminder sesuai keinginan
- Pesan motivasi otomatis
- Permission handling untuk Android & iOS

### 🎯 **HABIT TRACKING**
- Checklist harian dengan animasi
- Progress bar real-time
- Dark mode support
- Persistent storage dengan Hive

## 🚀 Quick Start

### 1. Install Dependencies

```bash
flutter pub get
flutter pub run build_runner build
```

### 2. Setup Permissions (Android)

Tambahkan ke `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
```

### 3. Setup Permissions (iOS)

Tambahkan ke `ios/Runner/Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

### 4. Run App

```bash
flutter run
```

## 📁 Struktur Project

```
lib/
├── main.dart                    # Main app dengan navigation
├── models/
│   └── daily_habit_model.dart   # Model & services lengkap
├── screens/
│   ├── daily_habit_tracker_screen.dart  # Screen utama
│   ├── add_edit_habit_screen.dart       # Add/Edit habit
│   └── statistics_screen.dart           # Stats & grafik
└── providers/                   # State management (legacy)
```

## 🔧 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management & Storage
  flutter_riverpod: ^2.4.0
  hive: ^2.2.3
  hive_flutter: ^1.1.0

  # Notifications & Charts
  flutter_local_notifications: ^17.0.0
  fl_chart: ^0.66.1

  # Permissions
  permission_handler: ^11.0.1

  # Utils
  intl: ^0.19.0
```

## 🎮 Cara Penggunaan

### 1. **Tambah Habit Baru**
- Tap tombol `+` floating action button
- Isi nama, deskripsi, kategori, dan target
- Habit akan muncul di checklist harian

### 2. **Checklist Harian**
- Tap checkbox untuk menandai habit selesai
- Lihat streak counter bertambah
- Progress bar update real-time

### 3. **Lihat Statistik**
- Buka tab "Stats" di bottom navigation
- Lihat grafik mingguan/bulanan
- Cek achievement badges

### 4. **Setup Reminder**
- Buka tab "Reminder" di bottom navigation
- Aktifkan notifikasi dan set waktu
- Pilih pesan motivasi

## 🔥 Streak Logic

```dart
// Contoh perhitungan streak
List<String> history = ['2024-01-01', '2024-01-02', '2024-01-03'];
int streak = calculateStreak(history); // Returns: 3

// Jika hari ini belum dicentang
DateTime today = DateTime.now(); // 2024-01-04
// Streak tetap 3, bisa dicentang hari ini

// Jika kemarin tidak dicentang
// Streak reset ke 0
```

## 📊 Statistics Features

### Weekly Chart
- Line chart dengan 7 hari terakhir
- Menampilkan jumlah habit selesai per hari
- Hover untuk detail nilai

### Monthly Chart
- Bar chart untuk seluruh bulan
- Progress completion rate
- Color coding berdasarkan performance

### Achievement System
- 🌟 **Getting Started**: 3 hari streak
- ⚡ **Weekly Warrior**: 7 hari streak
- 🎯 **Monthly Master**: 30 hari streak
- ⭐ **Golden Streak**: 50 hari streak
- 🏆 **Century Champion**: 100 hari streak

## 🔔 Notification System

### Setup Reminder
```dart
// Schedule daily reminder
await NotificationService.scheduleDailyReminder(
  time: TimeOfDay(hour: 9, minute: 0),
  title: 'Habit Reminder',
  body: 'Jangan lupa selesaikan kebiasaan harian Anda!',
);
```

### Custom Messages
- "Jangan biarkan hari ini berlalu tanpa progress!"
- "Konsistensi adalah kunci kesuksesan."
- "Setiap hari adalah kesempatan baru."

## 🎨 UI/UX Features

- **Material Design 3** dengan rounded corners
- **Dark Mode** otomatis berdasarkan system
- **Smooth Animations** pada checkbox dan progress
- **Responsive Layout** untuk semua screen size
- **Intuitive Navigation** dengan bottom tabs

## 🔒 Data Persistence

- **Hive Database** untuk local storage
- **Automatic Backup** streak dan history
- **Data Migration** untuk app updates
- **Offline First** - works without internet

## 🚀 Performance

- **Efficient Rendering** dengan ListView.builder
- **Minimal Rebuilds** dengan Riverpod
- **Lazy Loading** untuk large datasets
- **Memory Optimized** dengan proper disposal

## 🐛 Troubleshooting

### Notification tidak muncul
1. Cek permission di device settings
2. Restart app setelah grant permission
3. Pastikan "Don't kill my app" disabled

### Streak tidak update
1. Cek tanggal device sudah benar
2. Restart app untuk recalculate
3. Clear app data jika corrupt

### Chart tidak loading
1. Pastikan fl_chart dependency terinstall
2. Check console untuk error messages
3. Restart app

## 📝 Development Notes

### Adding New Habit Categories
```dart
// Tambah di daily_habit_model.dart
final Map<String, IconData> _categoryIcons = {
  'Olahraga': Icons.sports_soccer,
  'Belajar': Icons.school,
  'Kesehatan': Icons.favorite,
  'Produktivitas': Icons.trending_up,
  'Sosial': Icons.people,
  'Spiritual': Icons.spa,
  'NewCategory': Icons.new_icon, // Tambah disini
};
```

### Custom Achievement Badges
```dart
// Tambah logic di getAchievementBadge()
if (streak >= 365) return '🌟 Year Master';
if (streak >= 200) return '💎 Diamond Streak';
```

## 🤝 Contributing

1. Fork repository
2. Create feature branch
3. Commit changes
4. Push to branch
5. Create Pull Request

## 📄 License

MIT License - feel free to use for personal/commercial projects.

---

**Made with ❤️ using Flutter**
