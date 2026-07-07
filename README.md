# MediSync

**Health Lifestyle Monitoring Application**

MediSync adalah aplikasi mobile yang membantu pengguna memantau dan mengevaluasi kebiasaan kesehatan harian melalui pencatatan data tidur, aktivitas fisik, dan konsumsi air.

---

## Fitur Utama

- **Autentikasi** - Login/Register via Email atau Google Sign-In
- **Email Verification** - Verifikasi email via Firebase Auth
- **Password Reset** - Reset password via email link
- **Onboarding** - Pengisian data diri pengguna
- **Input Harian** - Pencatatan tidur, aktivitas, dan air
- **Skor Kesehatan** - Perhitungan otomatis berdasarkan data
- **Dashboard** - Menampilkan skor hari ini dan rekomendasi
- **Riwayat** - Chart dan statistik 7 hari terakhir
- **Profil** - Pengelolaan data profil
- **Ubah Password** - Ganti password dari profil
- **Notifikasi** - Pengingat harian jam 22:00
- **Share** - Membagikan poster kesehatan (9:16)

---

## Teknologi

| Komponen         | Teknologi                   |
|------------------|-----------------------------|
| Framework        | Flutter 3.x                 |
| Bahasa           | Dart                        |
| Backend          | Firebase                    |
| Database         | Cloud Firestore             |
| Autentikasi      | Firebase Auth               |
| State Management | Provider                    |
| Charts           | fl_chart                    |
| Notifications    | flutter_local_notifications |

---

## Screenshots

| Dashboard     | Input Harian          | Riwayat      | Profil      |
|---------------|-----------------------|--------------|-------------|
| Skor hari ini | Tidur, Aktivitas, Air | Chart 7 hari | Data profil |

---

## Struktur Proyek

```
lib/
├── config/
│   └── app_config.dart          # Routes dan konfigurasi
├── models/
│   ├── health_record_model.dart  # Model data kesehatan
│   └── user_model.dart          # Model pengguna
├── providers/
│   ├── auth_provider.dart       # State autentikasi
│   ├── health_provider.dart     # State data kesehatan
│   └── navigation_provider.dart # State navigasi
├── screens/
│   ├── splash_screen.dart
│   ├── welcome_screen.dart
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── forgot_password_screen.dart
│   ├── email_verification_screen.dart
│   ├── onboarding1_screen.dart
│   ├── onboarding2_screen.dart
│   ├── dashboard_screen.dart
│   ├── daily_input_screen.dart
│   ├── result_screen.dart
│   ├── history_screen.dart
│   ├── profile_screen.dart
│   ├── change_password_screen.dart
│   └── main_navigation_screen.dart
├── services/
│   ├── auth_service.dart        # Firebase Auth
│   ├── firestore_service.dart   # Firestore CRUD
│   ├── local_storage_service.dart # SharedPreferences
│   └── notification_service.dart # Local notifications
├── theme/
│   └── app_theme.dart           # Tema dan warna
├── widgets/
│   ├── custom_text_field.dart   # Input field reusable
│   ├── score_card.dart          # Kartu skor
│   ├── suggestion_card.dart     # Kartu rekomendasi
│   └── main_bottom_nav.dart     # Bottom navigation
├── firebase_options.dart
└── main.dart
```

---

## Skor Kesehatan

### Sleep Score (0-40)
| Durasi  | Skor |
|---------|------|
| 7-9 jam | 40   |
| 6 jam   | 30   |
| 5 jam   | 20   |
| 4 jam   | 10   |
| <4 jam  | 5    |

### Activity Score (0-30)
| Aktivitas      | ≥30 mnt | <30 mnt |
|----------------|---------|---------|
| Heavy Exercise | 30      | 20      |
| Light Exercise | 25      | 15      |
| Walking        | 20      | 10      |
| No Activity    | 0       | 0       |

### Water Score (0-30)
| Gelas | Skor |
|-------|------|
| ≥8    | 30   |
| 7     | 26   |
| 6     | 22   |
| 5     | 18   |
| 4     | 14   |
| 3     | 10   |
| 2     | 6    |
| 1     | 3    |
| 0     | 0    |

### Label Skor
| Skor   | Label     |
|--------|-----------|
| 80-100 | Excellent |
| 60-79  | Good      |
| 40-59  | Fair      |
| 20-39  | Poor      |
| 0-19   | Bad       |

---

## Instalasi

### Prasyarat
- Flutter SDK >=3.0.0
- Dart SDK >=3.0.0
- Android Studio / VS Code
- Firebase project

### Langkah Instalasi

1. Clone repository
```bash
git clone https://github.com/username/medisync.git
cd medisync
```

2. Install dependencies
```bash
flutter pub get
```

3. Konfigurasi Firebase
- Buat project di Firebase Console
- Download `google-services.json` (Android) dan `GoogleService-Info.plist` (iOS)
- Letakkan di direktori yang sesuai

4. Jalankan aplikasi
```bash
flutter run
```

---

## Konfigurasi Firebase

### Firestore Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    match /health_records/{recordId} {
      allow read: if request.auth != null && request.auth.uid == resource.data.userId;
      allow create: if request.auth != null
        && request.auth.uid == request.resource.data.userId;
      allow update, delete: if request.auth != null
        && request.auth.uid == resource.data.userId;
    }
  }
}
```

### Android Permissions
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
```

---

## Flow Aplikasi

```
┌─────────────┐
│   Splash    │
└──────┬──────┘
       │
┌──────▼──────┐
│   Welcome   │
└──────┬──────┘
       │
┌──────▼──────┐     ┌─────────────┐
│    Login    │────►│   Register  │
└──────┬──────┘     └──────┬──────┘
       │                   │
       │            ┌──────▼──────┐
       │            │   Email     │
       │            │ Verification│
       │            └──────┬──────┘
       │                   │
┌──────▼───────────────────▼──────┐
│         Onboarding 1 & 2        │
└──────────────┬──────────────────┘
               │
       ┌───────▼───────┐
       │   Dashboard   │◄──┐
       └───────┬───────┘   │
               │           │
       ┌───────▼───────┐   │
       │  Daily Input  │───┘
       └───────┬───────┘
               │
       ┌───────▼───────┐
       │    Result     │
       └───────────────┘
```

---

## Peran Saya

Sebagai **Mobile Developer**, saya bertanggung jawab atas:

- Pengembangan UI/UX dengan Flutter
- Integrasi Firebase Auth dan Firestore
- Implementasi state management dengan Provider
- Pembuatan chart dengan fl_chart
- Implementasi notifikasi lokal
- Fitur share poster kesehatan
- Optimasi performa aplikasi

---

## Dokumen

- [Software Requirements Specification (SRS)](SRS.md)

---

## Lisensi

MIT License

---

**MediSync - Health Lifestyle Monitoring Application**
