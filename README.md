<div align="center">

# 🔐 KeySafe
### An AI-Powered secure, local-first password manager for Android

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Android](https://img.shields.io/badge/Android-API%2021+-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-6366F1?style=for-the-badge)
![AES](https://img.shields.io/badge/Encryption-AES--256--CBC-EF4444?style=for-the-badge)

<br/>

> **KeySafe** keeps your passwords safe with AES-256 CBC encryption, PIN authentication, and zero cloud dependency. Everything stays on your device.

<br/>

</div>

---

## ✨ Features

### 🔒 Security
- **AES-256 CBC Encryption** — every password is encrypted before storage using a unique IV per entry
- **PIN Authentication** — 4-digit PIN lock screen on every launch
- **Brute-Force Protection** — 5-minute lockout after 3 wrong PIN attempts, persists across app restarts
- **Local Only** — no internet required, no cloud sync, no accounts, no telemetry

### 🗂️ Vault Management
- Add, view, edit, and delete password entries
- Fields: Site name, URL, Username, Email, Password, Category, Notes
- Optional **Security Questions** per entry (multiple Q&A pairs)
- Copy any field to clipboard with one tap

### 🎨 Usability
- **Live search** — filter entries by site name, username, or email
- **Category filter** — General, Banking, Social, Work, Shopping, Streaming
- **Password generator** — cryptographically random 12-character passwords
- **Password strength indicator** — animated Weak / Medium / Strong bar
- **Email & URL validation** — soft warnings with auto URL scheme correction
- **Favicon loading** — automatically loads site icons from `icon.horse`
- **Dynamic accent colours** — colour-coded entry cards per site

---

## 📱 Screenshots

> _Add your screenshots here_

| Lock Screen | Vault | Add Entry |
|:-----------:|:-----:|:---------:|
| ![Lock](screenshots/lock.png) | ![Vault](screenshots/vault.png) | ![Add](screenshots/add.png) |

| View Entry | Edit Entry | Settings |
|:----------:|:----------:|:--------:|
| ![View](screenshots/view.png) | ![Edit](screenshots/edit.png) | ![Settings](screenshots/settings.png) |

---

## 🏗️ Project Structure

```
lib/
├── main.dart                    # App entry point & theme
└── screens/
    ├── lock_screen.dart         # PIN auth, brute-force lockout
    ├── main_screen.dart         # Vault list, search, category filter, settings
    ├── add_entry_screen.dart    # Add new password form
    ├── edit_entries_screen.dart # Edit existing entry
    └── view_entry_screen.dart   # Read-only entry detail view
└── services/
    └── encryption_service.dart  # AES-256 CBC encrypt / decrypt

assets/
└── logo.png                     # App logo
```

---

## 🔐 How Encryption Works

KeySafe uses **AES-256 CBC** (Advanced Encryption Standard, 256-bit key, Cipher Block Chaining mode).

```
plaintext password
      │
      ▼
SHA-256 hash of secret string  →  256-bit AES key
      │
      ▼
Random 16-byte IV (new every save)
      │
      ▼
AES-256 CBC encryption
      │
      ▼
stored as  "IV_base64:ciphertext_base64"
```

- The **key** is derived from a secret string via SHA-256 — it never changes and never needs to be stored
- The **IV** is randomly generated on every encryption, ensuring identical passwords produce different ciphertext
- The **IV** is stored alongside the ciphertext (not secret, but useless without the key)
- If decryption fails for any reason, the original string is returned safely without crashing

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `3.x` or higher
- Android Studio or VS Code with Flutter extension
- Android emulator or physical device (API 21+)

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/yourusername/keysafe.git
cd keysafe

# 2. Install dependencies
flutter pub get

# 3. Generate app icons (optional)
dart run flutter_launcher_icons

# 4. Run the app
flutter run
```

### Default PIN

```
1234
```
You can change this from the Settings tab inside the app.

---

## 📦 Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `shared_preferences` | ^2.2.2 | Local key-value storage |
| `encrypt` | ^5.0.3 | AES-256 CBC encryption |
| `crypto` | ^3.0.3 | SHA-256 key derivation |
| `cached_network_image` | latest | Favicon loading with cache |
| `flutter_launcher_icons` | ^0.13.1 | App icon generation |

---

## 🛡️ Security Notes

- All passwords are encrypted **before** being written to storage — plaintext is never persisted
- The master PIN is stored in SharedPreferences as plaintext — for stronger security, consider hashing it with bcrypt in future versions
- No data leaves the device at any point — all storage is local via SharedPreferences
- The encryption secret key is hardcoded in `encryption_service.dart` — for production apps, consider using Flutter Secure Storage or platform keystore

---

## 🎓 Academic Context

This application was developed as an assignment for:

> **UCCD3223 — Mobile Applications Development**
> Universiti Tunku Abdul Rahman (UTAR)
> February 2026 Trimester

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgements

- [Flutter](https://flutter.dev) — UI framework
- [encrypt](https://pub.dev/packages/encrypt) — AES encryption package
- [icon.horse](https://icon.horse) — favicon API service
- [shields.io](https://shields.io) — README badges

---

<div align="center">

Made with ❤️ using Flutter

</div>
