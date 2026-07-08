# Software Requirements Specification (SRS)
## MediSync - Health Lifestyle Monitoring Application

**Versi:** 1.0  
**Tanggal:** 7 Juli 2025  
**Status:** Final

---

## 1. Pendahuluan

### 1.1 Tujuan
MediSync adalah aplikasi mobile yang membantu pengguna memantau dan mengevaluasi kebiasaan kesehatan harian melalui pencatatan data tidur, aktivitas fisik, dan konsumsi air.

### 1.2 Ruang Lingkup
Aplikasi ini menyediakan fitur:
- Autentikasi pengguna (Email/Password dan Google Sign-In)
- Input data kesehatan harian
- Perhitungan skor kesehatan
- Riwayat dan visualisasi data 7 hari
- Rekomendasi kesehatan berbasis data
- Notifikasi pengingat harian
- Fitur share poster kesehatan

### 1.3 Definisi, Istilah, dan Singkatan
| Istilah        | Definisi                                                    |
|----------------|-------------------------------------------------------------|
| Skor Kesehatan | Angka 0-100 yang merepresentasikan kondisi kesehatan harian |
| Sleep Score    | Skor berdasarkan durasi tidur (0-40)                        |
| Activity Score | Skor berdasarkan jenis dan durasi aktivitas (0-30)          |
| Water Score    | Skor berdasarkan konsumsi air (0-30)                        |
| OobCode        | One-time code untuk reset password via email                |

---

## 2. Gambaran Umum

### 2.1 Perspektif Sistem
MediSync adalah aplikasi mobile standalone yang menggunakan Firebase sebagai backend untuk autentikasi, database, dan notifikasi.

### 2.2 Fitur Utama
1. **Autentikasi** - Login/Register via Email atau Google
2. **Onboarding** - Pengisian data diri pengguna
3. **Input Harian** - Pencatatan tidur, aktivitas, dan air
4. **Dashboard** - Menampilkan skor hari ini
5. **Riwayat** - Chart dan statistik 7 hari terakhir
6. **Profil** - Pengelolaan data profil
7. **Notifikasi** - Pengingat harian jam 22:00
8. **Share** - Membagikan poster kesehatan

### 2.2.1 Karakteristik Pengguna
- Pengguna usia 13+ tahun
- Pengguna Android/iOS
- Tidak memerlukan keahlian teknis khusus

### 2.2.2 Kendala Operasional
- Memerlukan koneksi internet untuk sinkronisasi data
- Notifikasi memerlukan izin dari pengguna

### 2.2.3 Asumsi dan Ketergantungan
- Pengguna memiliki device Android/iOS
- Firebase services aktif dan berfungsi
- Koneksi internet tersedia

---

## 3. Spesifikasi Fungsional

### 3.1 Autentikasi Pengguna

#### 3.1.1 Login Email/Password
- **Input:** Email, Password
- **Proses:** Validasi format email, autentikasi via Firebase Auth
- **Output:** Redirect ke Dashboard atau Onboarding

#### 3.1.2 Login Google
- **Input:** Akun Google pengguna
- **Proses:** OAuth 2.0 via Google Sign-In
- **Output:** Redirect ke Dashboard atau Onboarding

#### 3.1.3 Register
- **Input:** Nama, Email, Password, Konfirmasi Password
- **Proses:** Validasi input, create akun Firebase, kirim email verifikasi
- **Output:** Redirect ke Email Verification Screen

#### 3.1.4 Lupa Password
- **Input:** Email
- **Proses:** Kirim email reset password via Firebase
- **Output:** Dialog konfirmasi

#### 3.1.5 Ubah Password (Authenticated Mode)
- **Input:** Password Lama, Password Baru, Konfirmasi Password
- **Proses:** Re-authenticate, update password
- **Output:** Redirect ke Profil

### 3.2 Onboarding

#### 3.2.1 Langkah 1
- **Input:** Persetujuan pengguna
- **Proses:** Menampilkan informasi aplikasi
- **Output:** Navigasi ke Langkah 2

#### 3.2.2 Langkah 2
- **Input:** Nama, Jenis Kelamin, Tanggal Lahir, Tinggi Badan, Berat Badan
- **Proses:** Validasi input, simpan ke Firestore
- **Output:** Redirect ke Dashboard

### 3.3 Input Harian

#### 3.3.1 Jam Tidur
- **Input:** Jam Mulai Tidur, Jam Bangun
- **Proses:** Hitung durasi tidur otomatis
- **Output:** Durasi tidur dalam jam

#### 3.3.2 Aktivitas Fisik
- **Input:** Jenis Aktivitas (Walking/Light Exercise/Heavy Exercise/No Activity), Durasi
- **Proses:** Hitung skor aktivitas
- **Output:** Skor aktivitas

#### 3.3.3 Konsumsi Air
- **Input:** Jumlah gelas (0-8)
- **Proses:** Hitung skor air
- **Output:** Skor air

#### 3.3.4 Hitung Skor
- **Input:** Semua data di atas
- **Proses:** Hitung total skor = Sleep Score + Activity Score + Water Score
- **Output:** Total skor (0-100) dan label (Excellent/Good/Fair/Poor/Bad)

### 3.4 Dashboard

#### 3.4.1 Tampilan Utama
- **Data:** Skor hari ini, label, rekomendasi
- **Proses:** Ambil data dari provider
- **Output:** Menampilkan kartu skor, rincian skor, dan saran

#### 3.4.2 Share Poster
- **Input:** Tombol share
- **Proses:** Generate poster 9:16 dengan data pengguna
- **Output:** File PNG yang dibagikan

### 3.5 Riwayat

#### 3.5.1 Chart 7 Hari
- **Data:** Record 7 hari terakhir (Senin-Minggu)
- **Proses:** Query Firestore, mapping ke hari
- **Output:** Bar chart dengan label hari

#### 3.5.2 Statistik
- **Data:** Semua record
- **Proses:** Hitung rata-rata, tertinggi, streak
- **Output:** Kartu statistik

#### 3.5.3 Insight
- **Data:** Record 7 hari terakhir
- **Proses:** Analisis pola tidur, aktivitas, air
- **Output:** Daftar insight dalam bentuk kartu

### 3.6 Profil

#### 3.6.1 Tampilan Profil
- **Data:** Data pengguna dari Firestore
- **Proses:** Ambil data dari provider
- **Output:** Menampilkan avatar, nama, email, data diri

#### 3.6.2 Edit Profil
- **Input:** Nama, Usia, Jenis Kelamin, Tinggi, Berat, Ubah Password
- **Proses:** Update data di Firestore
- **Output:** Profil terbaru

#### 3.6.3 Toggle Notifikasi
- **Input:** Switch notifikasi
- **Proses:** Update preference di SharedPreferences dan Firestore
- **Output:** Notifikasi aktif/nonaktif

### 3.7 Notifikasi

#### 3.7.1 Daily Reminder
- **Waktu:** 22:00 setiap hari
- **Proses:** Notifikasi muncul saat user buka app setelah jam 22:00 (fallback untuk device dengan aggressive battery optimization seperti Xiaomi/MIUI)
- **Output:** Notifikasi "Jangan lupa catat data kesehatanmu hari ini."
- **Catatan:** Untuk notifikasi tepat waktu di background, user perlu matikan battery optimization untuk MediSync

---

## 4. Spesifikasi Non-Fungsional

### 4.1 Performa
- Waktu respons < 2 detik untuk operasi CRUD
- Ukuran aplikasi < 50MB
- Frame rate minimal 60fps

### 4.2 Keamanan
- Password di-hash oleh Firebase Auth
- Firestore rules: user hanya bisa akses data sendiri
- Enkripsi data transit (HTTPS)

### 4.3 Usability
- UI menggunakan Google Fonts Poppins
- Warna utama: Medical Blue (#1E5EFF)
- Form input dengan validasi real-time
- Loading indicator pada operasi async

### 4.4 Reliability
- Offline fallback via SharedPreferences
- Auto-sync saat online
- Error handling di setiap operasi

### 4.5 Maintainability
- Clean architecture (models, services, providers, screens, widgets)
- Konsisten naming convention
- Dokumentasi kode minimal

---

## 5. Spesifikasi Teknis

### 5.1 Platform
- **Target:** Android API 21+, iOS 12+
- **Framework:** Flutter 3.x
- **Bahasa:** Dart

### 5.2 Backend Services
| Service              | Fungsi               |
|----------------------|----------------------|
| Firebase Auth        | Autentikasi pengguna |
| Cloud Firestore      | Database NoSQL       |

### 5.3 Dependencies
| Package                     | Versi   | Fungsi              |
|-----------------------------|---------|---------------------|
| firebase_core               | ^3.12.1 | Core Firebase       |
| firebase_auth               | ^5.5.4  | Authentication      |
| cloud_firestore             | ^5.6.9  | Database            |
| google_sign_in              | ^6.2.2  | Google OAuth        |
| provider                    | ^6.1.2  | State management    |  
| fl_chart                    | ^0.70.2 | Charts              |
| share_plus                  | ^10.1.4 | Share content       |
| flutter_local_notifications | ^18.0.1 | Local notifications |
| timezone                    | ^0.10.0 | Timezone handling   |
| google_fonts                | ^6.2.1  | Typography          |
| screenshot                  | ^3.0.0  | Capture widget      |
| path_provider               | ^2.1.5  | File system         |
| shared_preferences          | ^2.3.4  | Local storage       |
| app_links                   | ^6.4.1  | Deep links          |

### 5.4 Struktur Database

#### Collection: users
```json
{
  "uid": "string",
  "name": "string",
  "email": "string",
  "age": "number",
  "gender": "string",
  "height": "number",
  "weight": "number",
  "onboardingCompleted": "boolean",
  "notificationEnabled": "boolean",
  "createdAt": "timestamp"
}
```

#### Collection: health_records
```json
{
  "id": "string (userId_yyyy-MM-dd)",
  "userId": "string",
  "date": "timestamp",
  "sleepStartTime": "string (HH:mm)",
  "sleepEndTime": "string (HH:mm)",
  "sleepHours": "number",
  "activityType": "string",
  "activityDuration": "number (minutes)",
  "waterIntake": "number (glasses)",
  "totalScore": "number (0-100)",
  "healthLabel": "string",
  "sleepScore": "number (0-40)",
  "activityScore": "number (0-30)",
  "waterScore": "number (0-30)",
  "recommendations": "array",
  "createdAt": "timestamp"
}
```

### 5.5 Skor Kesehatan

#### Sleep Score (0-40)
| Durasi  | Skor |
|---------|------|
| 7-9 jam | 40   |
| 6 jam   | 30   |
| 5 jam   | 20   |
| 4 jam   | 10   |
| <4 jam  | 5    |

#### Activity Score (0-30)
| Aktivitas      | Durasi ≥30 mnt | Durasi <30 mnt |
|----------------|----------------|----------------|
| Heavy Exercise | 30             | 20             |
| Light Exercise | 25             | 15             |
| Walking        | 20             | 10             |
| No Activity    | 0              | 0              |     

#### Water Score (0-30)
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

#### Total Score Label
| Skor | Label        |
|------|--------------|
| 80-100 | Excellent  |
| 60-79 | Good        |
| 40-59 | Fair        |
| 20-39 | Poor        |
| 0-19 | Bad          |

---

## 6. Antarmuka Pengguna

### 6.1 Navigasi
- Bottom Navigation: Dashboard, Input, Riwayat, Profil
- Stack-based navigation untuk screen detail

### 6.2 Tema
- Warna Primer: #1E5EFF (Medical Blue)
- Warna Primer Gelap: #1546B0
- Warna Latar: #F5F9FF
- Font: Poppins

### 6.3 Layar Utama
1. Splash Screen
2. Welcome Screen
3. Login Screen
4. Register Screen
5. Forgot Password Screen
6. Email Verification Screen
7. Onboarding 1 & 2
8. Dashboard
9. Daily Input
10. Result
11. History
12. Profile
13. Change Password

---

## 7. Pengujian

### 7.1 Pengujian Fungsional
- [ ] Login dengan email valid/invalid
- [ ] Register dengan email baru
- [ ] Reset password via email
- [ ] Input data harian lengkap
- [ ] Perhitungan skor benar
- [ ] Riwayat tampil 7 hari
- [ ] Share poster berhasil
- [ ] Notifikasi muncul jam 22:00

### 7.2 Pengujian Non-Fungsional
- [ ] Aplikasi tidak lag
- [ ] Data tersimpan offline
- [ ] Auto-sync saat online
- [ ] Notifikasi berfungsi di background

---

## 8. Lampiran

### 8.1 Flow Aplikasi
```
Splash → Welcome → Login/Register → Onboarding → Dashboard
                                                      ↓
                                              Daily Input → Result
                                                      ↓
                                              History (7 hari)
```

### 8.2 Flow Autentikasi
```
Register → Email Verification → Onboarding → Dashboard
Login → Dashboard (jika onboarding completed)
Login → Onboarding (jika onboarding belum completed)
```

---

**Dokumen ini merupakan bagian dari proyek MediSync - Health Lifestyle Monitoring Application**
