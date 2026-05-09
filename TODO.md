# TODO - BlackboxAI (Habit Tracker Pro)

## Plan Execute

- [ ] 1) Rapikan `lib/providers/habits_riverpod.dart` supaya hanya berisi Riverpod providers terkait daily habits (tanpa campur ulang kode/services lain).
- [ ] 2) Matikan / rapikan `lib/providers/habit_provider.dart` agar tidak bentrok dengan Riverpod (tetap compile, tidak dead/unused yang memicu error).
- [ ] 3) Pastikan model `lib/models/daily_habit_model.dart` dipakai konsisten oleh SQLite helper dan UI.
- [ ] 4) Pastikan `AddEditHabitScreen` membuat habit sesuai field model (target/schedule/category) dan menyimpan ke SQLite.
- [ ] 5) Pastikan `DailyHabitTrackerScreen` memanggil provider yang benar: `dailyHabitsProvider`, `dailyProgressProvider`, `toggleHabitCompletion`, dll.
- [ ] 6) Pastikan `HomeScreen` dan `ProfileScreen` tidak memanggil provider/services yang tidak ada; jika fitur cloud/auth tidak tersedia, buat fallback/stub agar tidak crash.
- [ ] 7) Bersihkan sampah/duplikasi: hapus kelas/provider yang tidak dipakai atau singkirkan logika yang tumpang tindih.
- [ ] 8) Jalankan `flutter clean && flutter pub get` lalu compile/run untuk web (chrome).


