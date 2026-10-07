# 📱 Panduan Lengkap Setup In-App Purchase (IAP) ClickPad
### Untuk Google Play Console (Android) & Apple App Store Connect (iOS)

---

## 🚀 Ringkasan & Konfirmasi Dukungan Platform

Aplikasi ClickPad menggunakan plugin resmi Flutter **`in_app_purchase`** (versi `^3.2.0`).

> **Apakah mendukung Android dan iOS?**  
> **YA, 100% MENDUKUNG KEDUANYA!**  
> Di Android, plugin ini otomatis berjalan di atas **Google Play Billing Library**.  
> Di iOS, plugin ini otomatis berjalan di atas **Apple StoreKit**.  
> Seluruh alur transaksi, pengiriman produk, pemulihan pembelian (*Restore Purchases*), dan penanganan error sudah terintegrasi rapi di dalam [`lib/services/iap_service.dart`](file:///Users/sifasalafiah/Documents/Project/mouse_and_keyboard_for_desktop/lib/services/iap_service.dart).

---

## 🔑 Product ID yang Digunakan di Aplikasi

Pastikan Product ID yang Anda daftarkan di konsol toko **sama persis** (case-sensitive) dengan kode di aplikasi:

| Nama Produk | Tipe Produk | Product ID (SKU) | Estimasi Harga Default | Manfaat |
|---|---|---|---|---|
| **ClickPad PRO Lifetime** | Non-Consumable (Sekali Beli) | `clickpad_pro_lifetime` | Rp 29.000 / $1.99 | Bebas iklan 100%, Gamepad Virtual, Gyro Steering, Tema Eksklusif OLED Dark Mode, Zero Latency mode |
| **Joystick Game Pass Only** | Non-Consumable (Sekali Beli) | `clickpad_joystick_pass` | Rp 15.000 / $0.99 | Khusus membuka Virtual Gamepad & Joystick Controller |

---

## 🤖 Bagian 1: Panduan Setup Google Play Console (Android)

### 1. Prasyarat Akun
1. Akun **Google Play Console** aktif.
2. Siapkan **Profil Pembayaran Google Merchant** (di menu *Settings -> Payments profile*) untuk menerima pembayaran.

### 2. Upload Bundle Pertama (Wajib!)
> ⚠️ **Catatan Penting Google Play**: Anda **TIDAK BISA** membuat Produk In-App sebelum mengunggah minimal 1 build AAB (*Android App Bundle*) yang memiliki izin penagihan (*Billing Permission*).

1. Build aplikasi Android:
   ```bash
   flutter build appbundle --release
   ```
2. Buka Google Play Console $\rightarrow$ Pilih aplikasi ClickPad.
3. Masuk ke **Pengujian (Testing)** $\rightarrow$ **Pengujian internal (Internal testing)**.
4. Buat rilis baru dan unggah file `build/app/outputs/bundle/release/app-release.aab`.
5. Rilis ke penguji internal (tidak perlu menunggu review publik Google).

### 3. Buat Produk In-App di Google Play Console
1. Di menu sebelah kiri, cari bagian **Monetisasi (Monetize)** $\rightarrow$ klik **Produk dalam aplikasi (In-app products)**.
2. Klik tombol **Buat produk (Create product)**.
3. Buat Produk 1:
   * **ID Produk**: `clickpad_pro_lifetime`
   * **Nama**: `ClickPad PRO Lifetime Pass`
   * **Deskripsi**: `Akses seumur hidup semua fitur pro, bebas iklan, virtual gamepad, dan tema eksklusif.`
   * **Status**: Aktif (*Active*)
   * **Harga**: Tentukan harga dasar (misal: Rp 29.000 atau $1.99).
4. Buat Produk 2:
   * **ID Produk**: `clickpad_joystick_pass`
   * **Nama**: `Joystick Game Pass`
   * **Deskripsi**: `Buka akses Virtual Gamepad & Joystick Controller.`
   * **Status**: Aktif (*Active*)
   * **Harga**: Tentukan harga dasar (misal: Rp 15.000 atau $0.99).
5. Klik **Simpan (Save)** lalu **Aktifkan (Activate)**.

### 4. Setup Pengujian Tanpa Biaya (License Testers)
Agar Anda dapat menguji pembelian tanpa kartu kredit riil:
1. Di Google Play Console, buka menu utama **Semua aplikasi** $\rightarrow$ **Setelan (Settings)** $\rightarrow$ **Pengujian lisensi (License testing)**.
2. Tambahkan alamat email Gmail akun Google Play yang ada di HP Android tester Anda.
3. Pada **Respons lisensi**, pilih `RESPOND_NORMALLY`.
4. Saat tester melakukan pembelian di aplikasi, Google Play akan menampilkan kartu kredit uji (*Test Instrument*) tanpa memotong saldo/kartu riil.

---

## 🍏 Bagian 2: Panduan Setup Apple App Store Connect (iOS)

### 1. Prasyarat Akun Apple
1. Akun **Apple Developer Program** aktif ($99/tahun).
2. Di [App Store Connect](https://appstoreconnect.apple.com/), buka menu **Agreements, Tax, and Banking**.
3. Pastikan status **Paid Applications Agreement** berstatus *Active*, serta rekening bank dan formulir pajak (*Tax Forms*) sudah terisi. (Jika belum aktif, produk IAP tidak akan dapat dimuat di iOS).

### 2. Tambahkan Capability di Xcode
1. Buka folder `ios` di Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```
2. Pilih target **Runner** di panel kiri.
3. Buka tab **Signing & Capabilities**.
4. Klik tombol **`+ Capability`** di kiri atas.
5. Cari dan pilih **In-App Purchase**.
6. Simpan proyek.

### 3. Buat Produk In-App di App Store Connect
1. Buka [App Store Connect](https://appstoreconnect.apple.com/) $\rightarrow$ Pilih aplikasi **ClickPad**.
2. Di menu kiri pada bagian **Monetization**, pilih **In-App Purchases**.
3. Klik tombol **`+` (Create)**:
   * **Type**: Pilih **Non-Consumable** (karena pembelian bersifat permanen/sekali beli seumur hidup).
4. Konfigurasi Produk 1:
   * **Reference Name**: `ClickPad PRO Lifetime`
   * **Product ID**: `clickpad_pro_lifetime` *(Wajib sama persis dengan kode!)*
   * **Price Tier**: Pilih Tier yang setara (misal: Tier 2 / $1.99 / Rp 29.000).
   * **Display Name**: `ClickPad PRO Lifetime`
   * **Description**: `Unlock all pro features, remove ads forever, and access virtual gamepad.`
   * **Review Information**: Unggah screenshot dari aplikasi yang menampilkan modal pembelian Pro (ukuran 640x920px atau screenshot layar iPhone asli).
5. Konfigurasi Produk 2:
   * **Type**: **Non-Consumable**
   * **Reference Name**: `Joystick Game Pass`
   * **Product ID**: `clickpad_joystick_pass`
   * **Price Tier**: Pilih Tier yang setara (misal: Tier 1 / $0.99 / Rp 15.000).
   * **Display Name**: `Joystick Game Pass`
   * **Description**: `Unlock virtual gamepad and joystick controller.`
   * **Review Information**: Unggah screenshot modal pembelian Joystick.
6. Klik **Save**.

### 4. Setup Akun Sandbox Tester (iOS)
1. Di App Store Connect, buka menu **Users and Access** $\rightarrow$ **Sandbox Testers** (di panel kiri bawah).
2. Klik tombol `+` untuk membuat akun tester baru:
   * Masukkan email sembarang (tidak perlu Apple ID asli, misal: `tester1@sekala.dev`).
   * Password harus memenuhi syarat Apple (ada huruf besar, angka, simbol).
   * Pilih Storefront (misal: Indonesia atau United States).
3. Di iPhone fisik untuk pengujian:
   * Buka **Settings (Pengaturan)** $\rightarrow$ **App Store**.
   * Gulir ke bagian paling bawah ke menu **Sandbox Account**.
   * Masuk (*Sign In*) menggunakan email Sandbox Tester yang baru saja dibuat.
4. Buka aplikasi ClickPad di iPhone, klik tombol Upgrade PRO, dan lakukan pembelian uji coba.

---

## 🔄 Pemulihan Pembelian (*Restore Purchases*)

Sesuai **Apple App Store Review Guidelines (Guideline 3.1.1)**, setiap aplikasi dengan fitur non-consumable **WAJIB** menyediakan tombol *Restore Purchases*.

Di ClickPad:
* Tombol **"Restore Purchases"** sudah tersedia di bagian bawah dialog/modal pembelian [`ProPurchaseModal`](file:///Users/sifasalafiah/Documents/Project/mouse_and_keyboard_for_desktop/lib/widgets/pro_purchase_modal.dart).
* Tombol ini memanggil `IapService.instance.restorePurchases()`.
* Jika pengguna menginstal ulang aplikasi atau berganti perangkat baru dengan akun Google/Apple yang sama, fitur Pro akan otomatis aktif kembali.

---

## 🛠️ Mode Simulasi / Sandbox untuk Pengembangan (Debug)

Untuk kenyamanan pengembangan lokal ketika Anda belum menghubungkan aplikasi ke akun Google Play / Apple ID tester:
* Tombol pembelian di ClickPad memiliki mekanisme **fallback otomatis**:
  * Jika produk toko Google/Apple terdeteksi $\rightarrow$ Aplikasi otomatis memanggil antarmuka pembayaran asli Google Play / Apple StoreKit.
  * Jika dijalankan di Emulator/Simulator/Offline $\rightarrow$ Aplikasi otomatis mengaktifkan status PRO simulasi secara instan sehingga Anda bisa menguji seluruh fitur PRO (Joystick, Gyro, OLED theme, dll.) tanpa hambatan.
* Terdapat juga fitur **3-Minute Free Trial** bawaan untuk menguji fitur Joystick secara langsung bagi pengguna gratis.
