# ClickPad — PC Mouse, Keyboard & Joystick 🖱️⌨️🎮

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20Ready-3DDC84?logo=android&logoColor=white)](https://android.com)
[![Protocol](https://img.shields.io/badge/Protocol-Native%20Bluetooth%20HID-0078D7?logo=bluetooth&logoColor=white)](https://en.wikipedia.org/wiki/Human_interface_device)
[![No Companion App](https://img.shields.io/badge/PC%20Server-NOT%20NEEDED-success)](#-kenapa-clickpad-berbeda)
[![License](https://img.shields.io/badge/License-Proprietary-red)](#)

> **Ubah smartphone Anda menjadi Mouse Trackpad nirkabel, Keyboard mekanikal Pebble, dan Gamepad Joystick serbaguna untuk PC, Laptop, Mac, Linux, maupun Tablet—tanpa perlu instal aplikasi server apa pun di komputer!**

---

## 📑 Daftar Isi
- [Kenapa ClickPad Berbeda?](#-kenapa-clickpad-berbeda)
- [Daftar Fitur Lengkap](#-daftar-fitur-lengkap)
  - [1. Precision Touchpad (Mouse Remote)](#1-precision-touchpad-mouse-remote)
  - [2. Pebble-Style Full Physical Keyboard](#2-pebble-style-full-physical-keyboard)
  - [3. Virtual Gamepad & Gaming Joystick](#3-virtual-gamepad--gaming-joystick)
  - [4. Custom HUD Layout Editor (PUBG Style)](#4-custom-hud-layout-editor-pubg-style)
  - [5. Gamepad Button Remapping & Preset Profiles](#5-gamepad-button-remapping--preset-profiles)
  - [6. Native Bluetooth HID & 2-Way Pairing](#6-native-bluetooth-hid--2-way-pairing)
  - [7. Tema Eksklusif & OLED Dark Mode](#7-tema-eksklusif--oled-dark-mode)
  - [8. Pengaturan & Input Tuning](#8-pengaturan--input-tuning)
  - [9. ClickPad PRO & Reward Trial](#9-clickpad-pro--reward-trial)
  - [10. Tools Hub (Koleksi 7 Alat Produktivitas & Remote)](#10-tools-hub-koleksi-7-alat-produktivitas--remote)
    - [10.1 Barcode & QR Scanner to Keystroke](#101-barcode--qr-scanner-to-keystroke)
    - [10.2 Accounting Numpad (10-Key)](#102-accounting-numpad-10-key)
    - [10.3 Presentation Clicker & Remote](#103-presentation-clicker--remote)
    - [10.4 Media Controller (Couch Remote)](#104-media-controller-couch-remote)
    - [10.5 Macro Shortcuts Deck (Stream Deck)](#105-macro-shortcuts-deck-stream-deck)
    - [10.6 Mouse Jiggler (Anti-Sleep Utility)](#106-mouse-jiggler-anti-sleep-utility)
    - [10.7 Quick Text Snippets (Template Sender)](#107-quick-text-snippets-template-sender)
- [Gesture Touchpad Cheat Sheet](#-gesture-touchpad-cheat-sheet)
- [Kompatibilitas Sistem Operasi](#-kompatibilitas-sistem-operasi)
- [Panduan Cara Menghubungkan](#-panduan-cara-menghubungkan)
- [Struktur Arsitektur Project](#-struktur-arsitektur-project)
- [Teknologi & Dependensi](#-teknologi--dependensi)
- [Cara Build & Menjalankan](#-cara-build--menjalankan)

---

## ⚡ Kenapa ClickPad Berbeda?

Sebagian besar aplikasi remote mouse di pasaran memerlukan instalasi aplikasi server/agen (seperti server Windows/Mac) di komputer Anda dan mengharuskan berada di jaringan WiFi yang sama.

**ClickPad bekerja pada level Hardware (Native Bluetooth HID Device Emulation):**
- 🚫 **Tanpa Server di PC:** Komputer Anda mendeteksi smartphone Anda murni sebagai Mouse & Keyboard Bluetooth standar (seperti Logitech/Apple Magic Trackpad).
- ⚡ **Zero-Latency (~83Hz Input Loop):** Akumulator input frame 12ms memberikan respon instan tanpa lag.
- 📶 **Tanpa WiFi & Tanpa Internet:** Berjalan offline via Bluetooth standar.
- 🔒 **Aman & Ringan:** Tidak perlu membuka port jaringan, firewall exception, atau privilege admin di komputer Anda.

---

## 🚀 Daftar Fitur Lengkap

### 1. Precision Touchpad (Mouse Remote)
* **Smooth Tracking Canvas:** Area touchpad responsif beresolusi tinggi dengan indikator ripple visual multi-touch.
* **Precision Mode:** Tombol toggle mode presisi (sensitivitas rendah) khusus untuk pekerjaan akurasi tinggi seperti desain grafis, editing foto, dan penargetan pixel-perfect.
* **Smart Block / Drag Text Mode:**
  - *Double-Tap & Slide* atau *Tahan Tombol Klik Kiri* langsung mengaktifkan mode drag/blok seleksi teks dan drag-and-drop window.
  - Dilengkapi badge indikator visual mengambang: `BLOCK / DRAG MODE ACTIVE`.
* **Tombol Fisik Mouse Bawah:**
  - **Left Click:** Mendukung single tap dan hold-to-drag.
  - **Middle Click:** Scroll lock / tab navigation click.
  - **Right Click:** Klik kanan instan dengan haptic feedback tegas.
* **Quick Action Bar:**
  - **Copy:** `Ctrl + C` (Windows/Linux) atau `Cmd + C` (macOS).
  - **Paste:** `Ctrl + V` (Windows/Linux) atau `Cmd + V` (macOS).
  - **Deteksi OS Otomatis:** Menyesuaikan tombol modifier Cmd/Ctrl otomatis sesuai nama host perangkat Anda.
* **Native Keyboard Input Bar:**
  - Akses keyboard bawaan HP (Gboard, SwiftKey, iOS keyboard) langsung dari layar touchpad.
  - Ketik teks cepat, kirim ke komputer, dilengkapi tombol *Backspace*, *Enter*, dan *Done*.
* **Fullscreen Canvas Toggle:** Masuk ke layar penuh untuk memaksimalkan area sentuh.

---

### 2. Pebble-Style Full Physical Keyboard
* **Desain Tombol Pebble Estetik:** Tampilan keycap bulat terinspirasi Logitech Pebble dengan animasi sentuh dan efek timbul yang memanjakan mata.
* **Baris Tombol Fungsi Lengkap (F1 – F12):**
  - **F1 – F3:** Indikator profil perangkat / Easy-Switch.
  - **F4:** Mute / Nonaktifkan Suara.
  - **F5 / F6:** Volume Down & Volume Up.
  - **F7:** Lagu Sebelumnya (Skip Previous).
  - **F8:** Play / Pause Media.
  - **F9:** Lagu Berikutnya (Skip Next).
  - **F10:** Windows Search / Spotlight.
  - **F11:** Voice / Microphone input.
  - **F12:** Lock Screen PC.
  - **Del:** Dedicated Forward Delete.
* **Tombol Modifikasi Nyata:**
  - `Ctrl`, `Alt`, `Cmd / Win`, `Shift`, dan `Caps Lock`.
  - Non-sticky release: langsung ter-reset setelah penekanan karakter, identik dengan perilaku keyboard mekanik fisik.
* **Baris Karakter & Simbol Lengkap:**
  - Angka `1` – `0` beserta karakter khusus (`~`, `!`, `@`, `#`, `$`, `%`, dll.).
  - Layout QWERTY standar dengan tombol `Tab`, `Backspace`, `Enter/Return`, titik dua, kutip, dan kurung kurawal.
  - 4 Tombol Panah Navigasi (`▲`, `▼`, `◄`, `►`).
* **Dukungan Orientasi Fleksibel:** Otomatis menyesuaikan orientasi layar (Portrait & Landscape penuh) untuk pengalaman mengetik dua jempol yang leluasa.

---

### 3. Virtual Gamepad & Gaming Joystick
* **360° Analog Joystick:**
  - Menghitung vektor sudut analog presisi dengan deadzone dinamis.
  - Toggle mode arah: **WASD Mode** (gerakan PC standar) atau **Arrow Keys Mode** (retro platformer).
* **Tata Letak Tombol Konsol Lengkap:**
  - Tombol Aksi Diamond **ABXY** (`A`, `B`, `X`, `Y`).
  - D-Pad 4-Arah (Up, Down, Left, Right).
  - Shoulder Buttons: **L1** (Bumper Kiri) & **R1** (Bumper Kanan).
  - Trigger Buttons: **L2** (Trigger Kiri) & **R2** (Trigger Kanan).
  - Tombol Sistem: **SELECT** (Tab/Back), **START** (Enter/Menu), **ESC** (Pause).
* **Center Camera Look Trackpad:**
  - Area touchpad di tengah kontroler khusus untuk mengarahkan kamera 3D/FPS sambil menggerakkan joystick secara bersamaan.
* **Multi-Key Simultaneous Hold:** Mampu menahan joystick arah + tombol lari (Shift) + tombol lompat (Space) sekaligus tanpa ghosting.

---

### 4. Custom HUD Layout Editor (PUBG Style)
Fitur unggulan bagi para gamers mobile:
* **Drag & Drop Repositioning:** Geser posisi setiap elemen HUD kontroler ke posisi mana pun di layar sesuai kenyamanan jempol Anda.
* **Independent Scaling Slider:** Perbesar atau perkecil modul dari ukuran mini **0.65x** hingga ukuran jumbo **1.65x**.
* **Opacity / Transparansi Slider:** Atur kepekatan tampilan tombol dari **25%** (semi-transparan) hingga **100%** (solid).
* **Modul yang Dapat Diatur:**
  - Left Joystick / D-Pad
  - ABXY Diamond Cluster
  - Camera Look Trackpad
  - L1 / L2 Left Shoulders
  - R1 / R2 Right Shoulders
  - System Buttons (Select, Start, Esc)
* **Reset to Default:** Kembalikan tata letak default kapan saja dengan satu sentuhan.

---

### 5. Gamepad Button Remapping & Preset Profiles
Ubah fungsi setiap tombol joystick sesuai game favorit Anda tanpa emulator tambahan:
* **Katalog 100+ Tombol Keyboard HID:** Bebas petakan ke sembarang tombol alfabet (A-Z), angka (0-9), modifier (Shift, Ctrl, Alt), spasi, enter, tombol panah, hingga tombol fungsi (F1-F12).
* **Built-in Profile Presets:**
  1. 🎯 **FPS & Action RPG (Default):** WASD movement, Space jump, Shift sprint, Ctrl crouch, E interact, R reload.
  2. 🧱 **Roblox & Tablets:** Disesuaikan untuk Roblox/Minecraft di PC & iPad dengan tombol jump, shift-lock, dan tas inventaris.
  3. 👾 **Retro & Emulators:** Tombol panah, Z jump/action, X attack, C dash, Shift run, Esc pause.
  4. 🏎️ **Racing & Driving:** W/R2 throttle, S/L2 brake, Space handbrake, Shift nitro/boost, C camera.
  5. 📺 **Media & Desktop Remote:** Kontrol navigasi slide presentasi PowerPoint/Keynote & kontrol player video.

---

### 6. Native Bluetooth HID & 2-Way Pairing
* **Emulasi Hardware Standar:** Menggunakan protokol resmi `BluetoothHidDevice` Android (API 28+).
* **2 Metode Pairing Fleksibel:**
  - **Auto-Scan PC Mode:** ClickPad memindai beacon Bluetooth komputer di sekitar dan menghubungkan dengan 1 klik.
  - **Broadcast Mode (Discoverable):** Smartphone masuk ke status discoverable sehingga komputer/laptop Anda dapat memindai dan memasangkan ClickPad dari menu Bluetooth Settings PC.
* **Smart Device Management:**
  - Daftar perangkat terpasang (*Bonded/Paired Devices*) dengan penyambungan ulang instan.
  - Indikator kuat sinyal (RSSI).
  - Auto-prune perangkat kadaluarsa yang sudah di luar jangkauan.
* **Panduan Pairing Terintegrasi:** Langkah demi langkah lengkap dengan ilustrasi untuk:
  - 🍎 **macOS** (Ventura, Sonoma, Sequoia)
  - 🪟 **Windows** (Windows 10 & Windows 11)
  - 🐧 **Linux** (Ubuntu, Fedora, Arch)
  - 📱 **iPadOS & Android Tablets**

---

### 7. Tema Eksklusif & OLED Dark Mode
Tersedia 10 palet tema modern yang didesain secara teliti:
| No | Tema | Varian | Keterangan |
| :---: | :--- | :--- | :--- |
| 1 | **Midnight Slate** | Light & Dark | Biru indigo & navy modern (Default) |
| 2 | **OLED Pure** | Pure Black & Pure White | Hitam pekat hemat daya AMOLED & putih bersih |
| 3 | **Cyberpunk** | Pastel & Neon | Kombinasi aksen neon futuristik dan cyan |
| 4 | **Emerald Pebble** | Light & Dark | Nuansa hijau zamrud & sage organik |
| 5 | **Sunset Amber** | Light & Dark | Sentuhan jingga senja hangat & elegan |

---

### 8. Pengaturan & Input Tuning
* **Mouse Sensitivity Slider:** Kalibrasi kecepatan kursor dari `0.5x` hingga `4.0x`.
* **Scroll Speed Slider:** Atur kelancaran gulir vertikal dari `0.5x` hingga `4.0x`.
* **Cursor Acceleration:** Tingkatkan kecepatan kursor secara dinamis saat jari mengibaskan layar dengan cepat.
* **Tactile Haptic Feedback:** Getaran haptik halus pada setiap ketukan touchpad, klik tombol mouse, dan penekanan tombol keyboard.
* **Keep-Screen-On (Wakelock):** Mencegah layar smartphone mati saat sedang dipakai mengendalikan presentasi atau bermain game.

---

### 9. ClickPad PRO & Reward Trial
* 👑 **Pro Lifetime Pass:**
  - Beli satu kali, miliki selamanya tanpa langganan.
  - Menghilangkan seluruh iklan (100% Ad-Free).
  - Membuka semua tema Pebble & OLED Dark Mode.
  - Membuka akses penuh Virtual Gamepad, Layout Editor, & Button Remapping.
* 🎮 **Joystick Game Pass Only:**
  - Paket hemat khusus untuk membuka fitur Virtual Gamepad & Gaming Controller.
* 🎁 **Free Reward Trial:**
  - Tonton 1 video pendek untuk mencoba Joystick selama 3 menit secara gratis.
  - Dapat diperpanjang terus menerus (+3 Menit per video).
* 🔄 **Restore Purchases:** Sinkronisasi kembali lisensi pembelian Google Play Store Anda kapan saja.

---

### 10. Tools Hub (Koleksi 7 Alat Produktivitas & Remote)
Menu baru yang mengubah smartphone Anda menjadi pusat peralatan multifungsi yang berinteraksi langsung dengan komputer secara nirkabel:

#### 10.1 Barcode & QR Scanner to Keystroke
* **Hardware-Grade Scanner:** Memindai berbagai barcode (EAN-13, UPC, Code 128) dan QR Code menggunakan kamera HP.
* **Auto Keystroke Injection:** Hasil pemindaian langsung otomatis diketikkan ke kolom aktif di PC (Excel, browser, software kasir POS, Notepad, ERP).
* **Suffix Cerdas:** Opsi penambahan tombol otomatis setelah pemindaian: `Enter ↵`, `Tab ⇥`, atau `None`.
* **Fitur Tambahan:** Senter/flashlight toggle, switch kamera depan/belakang, input manual fallback, serta riwayat scan dengan tombol kirim ulang 1-ketuk.

#### 10.2 Accounting Numpad (10-Key)
* **Papan Angka Khusus:** Solusi sempurna untuk laptop 13-14 inch atau MacBook yang tidak memiliki numpad fisik.
* **Layout Akuntansi Ergonomis:** Angka `0-9`, tombol ganda `00`, tanda koma/titik `.`, operator hitung (`+`, `-`, `*`, `/`), `Esc`, `Tab`, `Backspace ⌫`, dan `Enter`.
* **Layar Digital Display:** Menampilkan ekspresi angka yang sedang diketikkan ke PC secara real-time.
* Sangat optimal untuk akuntan, data entry Excel, perbankan, dan shortcut navigasi Blender 3D.

#### 10.3 Presentation Clicker & Remote
* **Remote Slide Profesional:** Pengendali presentasi untuk PowerPoint, Google Slides, Keynote, dan dokumen PDF.
* **Tombol Raksasa:** Next Slide (`Right Arrow`/`Space`) dan Previous Slide (`Left Arrow`).
* **Kontrol Pertunjukan Lengkap:**
  - `F5`: Memulai slideshow dari awal.
  - `Shift + F5`: Memulai slideshow dari slide aktif saat ini.
  - `B`: Layar hitam (*Black Screen*) untuk mengalihkan fokus audiens ke pembicara.
  - `W`: Layar putih (*White Screen*).
  - `Esc`: Keluar dari mode presentasi.
* **Stopwatch & Timer Terintegrasi:** Dilengkapi timer durasi presentasi dan penghitung jumlah slide (*Slide Counter*).

#### 10.4 Media Controller (Couch Remote)
* **Remote Santai Sofa & Kasur:** Mengendalikan pemutaran YouTube, Netflix, Spotify, VLC, dan pemutar video lainnya dari jarak jauh.
* **Pusat Navigasi Cakram (Disc Hub):** Kontrol Volume Up, Volume Down, Lagu Sebelumnya, Lagu Berikutnya, serta tombol Play/Pause utama di tengah.
* **Fitur Lanjutan:** Tombol lompat waktu `-10 Detik` (J) dan `+10 Detik` (L), Toggle Mute/Unmute instan, Fullscreen (`F`), dan Subtitle/Captions (`C`).

#### 10.5 Macro Shortcuts Deck (Stream Deck)
* **Grid Pintasan Satu Ketukan:**
  - **Pintasan Sistem:** Kunci PC (`Win+L` / `Ctrl+Cmd+Q`), Screenshot Area (`Win+Shift+S` / `Cmd+Shift+4`), Buka Task Manager / Activity Monitor, Pengalih Aplikasi (*Alt+Tab* / *Cmd+Tab*), Tampilkan Desktop, Buka File Explorer, dan Tutup Jendela.
  - **Pintasan Browser & Editing:** Buka Tab Baru (`Ctrl/Cmd + T`), Tutup Tab, Buka Kembali Tab yang Tertutup (*Reopen Tab*), Refresh Halaman, Undo Cepat, dan Simpan Berkas (`Ctrl/Cmd + S`).

#### 10.6 Mouse Jiggler (Anti-Sleep Utility)
* **Cegah PC Sleep & Lock Screen:** Menggerakkan kursor mouse 1-pixel secara mikro dan berkala tanpa mengganggu pandangan mata atau pekerjaan di komputer Anda.
* **Frekuensi Dinamis:** Pilihan jeda waktu 10 detik, 30 detik, atau 60 detik.
* **Animasi Radar Aktif:** Tombol status berpendar dengan penghitung mundur (*countdown*) visual.
* **Statistik Sesi:** Menghitung total micro-jiggle yang dikirim dan durasi aktif sesi. Otomatis mengaktifkan *wakelock* HP.

#### 10.7 Quick Text Snippets (Template Sender)
* **Kirim Template Teks Instan:** Simpan teks salam pembuka, format alamat pengiriman, konfirmasi terima dokumen, penutup email resmi, atau catatan penting lainnya.
* **Ketik Satu Ketuk:** Tekan tombol kirim dan seluruh teks akan langsung terketik ke PC huruf demi huruf secara otomatis.
* **Manajemen Fleksibel:** Tambah, edit, dan hapus snippet dengan penyimpanan lokal persisten (*SharedPreferences*).

---

## 🖐️ Gesture Touchpad Cheat Sheet

| Gesture | Aksi di Komputer |
| :--- | :--- |
| **1 Jari Geser** | Menggerakkan kursor mouse |
| **1 Jari Ketuk (Tap)** | Klik Kiri (Left Click) |
| **2 Jari Ketuk (Tap)** | Klik Kanan (Right Click) |
| **2 Jari Geser Atas/Bawah** | Menggulir halaman (Scroll Up / Down) |
| **2 Jari Geser Kiri/Kanan** | Menggulir horizontal (Horizontal Scroll) |
| **Double-Tap & Geser Tahan** | Blok seleksi teks / Drag and Drop jendela |
| **Tahan Tombol Left Click + Geser** | Blok seleksi teks panjang secara presisi |
| **Tombol Precision Mode** | Kursor lambat & stabil untuk menggambar / edit |

---

## 🖥️ Kompatibilitas Sistem Operasi

Karena ClickPad menggunakan standar protokol **Bluetooth Human Interface Device (HID)**, aplikasi ini kompatibel dengan hampir seluruh OS modern:

| Platform | Mouse | Keyboard | Gamepad | Tanpa Software Tambahan? |
| :--- | :---: | :---: | :---: | :---: |
| **Windows 11 / 10 / 8** | ✅ | ✅ | ✅ | ✅ Ya, 100% Driverless |
| **macOS (Apple Silicon & Intel)** | ✅ | ✅ | ✅ | ✅ Ya, Plug-and-Play |
| **Linux (Ubuntu, Debian, Fedora, Arch)** | ✅ | ✅ | ✅ | ✅ Ya, Driver Kernel Linux |
| **iPadOS / iOS** | ✅ | ✅ | ✅ | ✅ Ya, Pasangkan via Bluetooth |
| **Android TV / Smart TV** | ✅ | ✅ | ✅ | ✅ Ya, Kompatibel |
| **Steam Deck / ROG Ally** | ✅ | ✅ | ✅ | ✅ Ya, Deteksi Gamepad/Keyboard |

---

## 🔌 Panduan Cara Menghubungkan

1. **Buka Aplikasi ClickPad** di ponsel Android Anda.
2. Pastikan **Bluetooth** di smartphone dan komputer Anda dalam keadaan **ON**.
3. Di layar **Bluetooth Pairing**:
   - Klik **Scan Nearby PC** untuk menemukan PC Anda, **atau**
   - Aktifkan **Broadcast Mode** di ClickPad, lalu buka menu Bluetooth di PC Anda dan klik *Add Device* -> pilih **ClickPad**.
4. Setujui permintaan **Pairing PIN** yang muncul di layar HP dan PC.
5. Selesai! Kini smartphone Anda berfungsi sebagai Mouse, Keyboard, dan Gamepad nirkabel.

---

## 📂 Struktur Arsitektur Project

```text
mouse_and_keyboard_for_desktop/
├── android/app/src/main/kotlin/com/sekala/clickpad/
│   └── MainActivity.kt             # Native Android Bluetooth HID Device Registration & MethodChannels
├── lib/
│   ├── main.dart                   # Inisialisasi app, dependency injection, and theme bootstrapping
│   ├── models/
│   │   ├── connection_type.dart    # Status dan tipe koneksi HID
│   │   ├── device_model.dart       # Model perangkat yang terdeteksi & RSSI
│   │   ├── gamepad_layout.dart     # Model posisi, ukuran, dan opacity HUD Gamepad
│   │   ├── gamepad_mapping.dart    # Scancode HID tombol, remapping, dan preset profiles
│   │   └── input_command.dart      # Format data perintah mouse & keyboard
│   ├── screens/
│   │   ├── bluetooth_pairing_screen.dart # Layar radar pairing 2-arah & panduan platform
│   │   ├── joystick_screen.dart    # Layar Gamepad 360°, ABXY, D-Pad & Camera Look
│   │   ├── keyboard_screen.dart    # Layar Keyboard fisik Pebble & Function keys
│   │   ├── main_navigation_screen.dart # Navigasi bawah, banner ad, dan status koneksi
│   │   ├── onboarding_screen.dart  # Panduan interaktif awal pengguna baru
│   │   ├── settings_screen.dart    # Tuning sensitivitas, tema, dan profil PRO
│   │   ├── tools_screen.dart       # Dashboard utama Hub Tools
│   │   ├── tools/
│   │   │   ├── macro_deck_screen.dart   # Stream deck pintasan sistem & browser
│   │   │   ├── media_remote_screen.dart # Remote media cakram & volume
│   │   │   ├── mouse_jiggler_screen.dart# Utilitas jiggler kursor anti-sleep
│   │   │   ├── numpad_screen.dart       # Numpad akuntansi 10-key
│   │   │   ├── presentation_screen.dart # Clicker slide & timer presentasi
│   │   │   ├── scanner_screen.dart      # Pemindai Barcode/QR ke PC
│   │   │   └── snippets_screen.dart     # Pengirim template teks tersimpan
│   │   └── touchpad_screen.dart    # Kanvas mouse multi-touch, gesture engine & shortcut
│   ├── services/
│   │   ├── ad_service.dart         # Google Mobile Ads (Banner, Rewarded Interstitials)
│   │   ├── bluetooth_service.dart  # Komunikasi Bluetooth BLE & Native MethodChannel
│   │   ├── connection_service.dart # State machine konektivitas
│   │   ├── gamepad_layout_service.dart # Persistensi custom layout HUD
│   │   ├── gamepad_mapping_service.dart# Persistensi mapping tombol kustom
│   │   ├── iap_service.dart        # In-App Purchase Google Play Store
│   │   └── settings_service.dart   # Persistensi SharedPreferences & tema
│   ├── theme/
│   │   └── app_colors.dart         # 10 Palet tema, warna responsif, & typography
│   ├── utils/
│   │   ├── haptic_helper.dart      # Haptic feedback tactile vibration
│   │   └── hid_helper.dart         # Helper terpusat pengiriman keystroke & shortcut
│   └── widgets/
│       ├── banner_ad_widget.dart   # Widget banner iklan AdMob
│       ├── gamepad_layout_editor.dart # Editor seret & ubah ukuran kontroler (PUBG-Style)
│       ├── gamepad_remapping_modal.dart # Modal pemetaan tombol keyboard ke gamepad
│       ├── joystick_widget.dart    # Analog thumbstick widget
│       └── pro_purchase_modal.dart # Bottom sheet pembelian PRO & Reward Video Trial
└── pubspec.yaml                    # Dependensi Flutter & metadata
```

---

## 🛠️ Teknologi & Dependensi

* **Framework:** [Flutter](https://flutter.dev) (Dart SDK `^3.11.5`)
* **Bluetooth Native:** Android `BluetoothHidDevice` API via MethodChannel
* **Bluetooth BLE Discovery:** `flutter_blue_plus`
* **In-App Billing:** `in_app_purchase` (Google Play In-App Billing)
* **Monetisasi:** `google_mobile_ads` (AdMob Banner & Rewarded Ads)
* **Styling & Motion:** `google_fonts`, `flutter_animate`
* **Local Storage:** `shared_preferences`
* **Screen State:** `wakelock_plus`
* **Haptics:** Native Vibration & System Feedback

---

## 📦 Cara Build & Menjalankan

### Kebutuhan:
- Flutter SDK 3.x+ terpasang
- Android SDK dengan minimum SDK versi 28 (Android 9.0 Pie) untuk dukungan penuh `BluetoothHidDevice`
- Smartphone Android fisik dengan hardware Bluetooth 4.0+ (HID Device Profile membutuhkan perangkat fisik, tidak didukung di Android Emulator).

### Langkah Instalasi:

1. **Clone repository:**
   ```bash
   git clone https://github.com/username/mouse_and_keyboard_for_desktop.git
   cd mouse_and_keyboard_for_desktop
   ```

2. **Pasang paket dependensi:**
   ```bash
   flutter pub get
   ```

3. **Jalankan ke perangkat Android fisik:**
   ```bash
   flutter run
   ```

4. **Build APK Release:**
   ```bash
   flutter build apk --release
   ```

---

<p align="center">
  Dibuat dengan ❤️ untuk kemudahan produktivitas dan gaming di komputer Anda.
</p>
