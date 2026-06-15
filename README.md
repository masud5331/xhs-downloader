# XHS Downloader

A complete, production-ready Flutter Android App for **Xiaohongshu (RedNote / 小红书)** profile batch video downloading. Download entire profiles or single posts in the highest quality, watermark-free.

---

## Features

| Feature | Details |
|---|---|
| **Single Video Download** | Paste any post link and download instantly |
| **Profile Batch Download** | Scrape and download all videos from any profile |
| **No Watermark** | Extracts the original, watermark-free media stream |
| **Cookie Authentication** | Upload `cookies.txt` for authenticated scraping |
| **Download History** | Persistent log of all downloaded files |
| **Real-time Progress** | Individual + overall progress bars |
| **Cancel Support** | Cancel any download at any time |
| **Notifications** | System notification on download completion |
| **Settings** | Quality, concurrency, delay, proxy configuration |
| **Dark UI** | Beautiful dark-themed Material 3 design |

---

## App Architecture

```
lib/
├── main.dart                        # App entry point, theme, routing
├── models/
│   └── download_task.dart           # Download task data model
├── providers/
│   └── app_provider.dart            # State management (Provider)
├── screens/
│   ├── home_screen.dart             # Main screen with link input & buttons
│   ├── progress_screen.dart         # Real-time download progress
│   ├── history_screen.dart          # Download history log
│   └── settings_screen.dart        # Cookie, quality, proxy settings
├── services/
│   ├── xhs_downloader_service.dart  # Core scraping & download engine
│   ├── cookie_service.dart          # Cookie persistence (SharedPreferences)
│   └── notification_service.dart   # Local push notifications
└── utils/
    └── helpers.dart                 # URL parsing, permissions, file utils
```

---

## Prerequisites

Before building, ensure you have the following installed:

| Tool | Version | Install |
|---|---|---|
| Flutter SDK | 3.24+ | [flutter.dev](https://flutter.dev/docs/get-started/install) |
| Dart SDK | 3.2+ | Included with Flutter |
| Android Studio | Latest | [developer.android.com](https://developer.android.com/studio) |
| Java JDK | 17+ | `sudo apt install openjdk-17-jdk` |
| Android SDK | API 34 | Via Android Studio SDK Manager |

---

## How to Build the Release APK

### Option 1: Using GitHub Actions (Recommended for Easy APK)

This project includes a GitHub Actions workflow that automatically builds the release APK for you. This is the easiest way to get the APK without setting up a local Flutter development environment.

1.  **Upload to GitHub:** Create a new repository on GitHub and push this project code to it.
2.  **Trigger Workflow:**
    *   **Automatic:** The workflow will run automatically on every `push` to the `main` branch or `pull_request` targeting `main`.
    *   **Manual:** Go to your repository on GitHub, click on the **Actions** tab, select "Android APK Build" from the workflows list, and click "Run workflow".
3.  **Download APK:** Once the workflow completes (look for a green checkmark), click on the workflow run. Under the "Artifacts" section, you will find `xhs-downloader-apk`. Download this zip file, extract it, and you will find your `app-release.apk`.

### Option 2: Using Standard Terminal / Command Prompt (Local Build)

### Step 1: Get Dependencies

```bash
cd xhs_downloader
flutter pub get
```

### Step 2: Build the Release APK

```bash
flutter build apk --release
```

The output APK will be at:
```
build/app/outputs/flutter-apk/app-release.apk
```

### Step 3 (Optional): Build a Split APK per ABI (Smaller File Size)

```bash
flutter build apk --split-per-abi --release
```

This generates separate APKs for `arm64-v8a`, `armeabi-v7a`, and `x86_64`. For most modern phones, use the `arm64-v8a` APK.

---

## How to Install on Your Phone

**Method 1: ADB (Recommended)**
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

**Method 2: Manual Transfer**
1. Copy `app-release.apk` to your phone via USB or cloud.
2. Open your file manager and tap the APK.
3. Enable "Install unknown apps" for your file manager if prompted.
4. Tap **Install**.

---

## How to Sign the APK for Production

The default `build.gradle` uses the debug keystore. For Play Store distribution or production use, follow these steps:

### Step 1: Generate a Keystore

```bash
keytool -genkey -v \
  -keystore xhs-release-key.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias xhs-key
```

Follow the prompts to set a password and fill in your organization details.

### Step 2: Create `android/key.properties`

Create a file at `android/key.properties` with the following content:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=xhs-key
storeFile=../xhs-release-key.jks
```

> **Important:** Add `key.properties` to your `.gitignore` to keep it private.

### Step 3: Update `android/app/build.gradle`

Replace the `signingConfigs` and `buildTypes` blocks with:

```groovy
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    ...
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
        }
    }
}
```

### Step 4: Build the Signed APK

```bash
flutter build apk --release
```

---

## How to Get `cookies.txt` (Required for Profile Download)

Xiaohongshu requires authentication to view profiles. You need to export your browser cookies.

### Method 1: Chrome/Edge Extension (Easiest)

1. Open **Google Chrome** or **Microsoft Edge** on your PC.
2. Install the extension: [**Get cookies.txt LOCALLY**](https://chrome.google.com/webstore/detail/get-cookiestxt-locally/cclelndahbckbenkjhflpdbgdldlbecc)
3. Go to [https://www.xiaohongshu.com](https://www.xiaohongshu.com) and **log in**.
4. Click the extension icon in your toolbar.
5. Select **Export** → **Current Site** → save as `cookies.txt`.
6. Transfer the file to your Android phone.
7. Open **XHS Downloader** → **Settings** → **Upload cookies.txt**.

### Method 2: Firefox Extension

1. Install [**cookies.txt**](https://addons.mozilla.org/en-US/firefox/addon/cookies-txt/) extension.
2. Log in to Xiaohongshu.
3. Click the extension → **Export** → save as `cookies.txt`.

### Cookie File Format

The app expects the standard Netscape/Mozilla cookie format:
```
# Netscape HTTP Cookie File
.xiaohongshu.com	TRUE	/	FALSE	1735689600	web_session	YOUR_SESSION_TOKEN
...
```

---

## Building on Termux (Advanced)

Building a full Flutter app on Termux requires significant setup. This is recommended only for advanced users.

```bash
# Install required packages
pkg update && pkg upgrade
pkg install git wget unzip openjdk-17

# Download Flutter SDK
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.0-stable.tar.xz
tar xf flutter_linux_3.24.0-stable.tar.xz
export PATH="$PATH:$HOME/flutter/bin"

# Download Android command-line tools
mkdir -p $HOME/android-sdk/cmdline-tools
wget https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
unzip commandlinetools-linux-11076708_latest.zip -d $HOME/android-sdk/cmdline-tools
mv $HOME/android-sdk/cmdline-tools/cmdline-tools $HOME/android-sdk/cmdline-tools/latest

export ANDROID_HOME=$HOME/android-sdk
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools"

# Accept licenses and install SDK
yes | sdkmanager --licenses
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"

# Build the app
cd xhs_downloader
flutter pub get
flutter build apk --release
```

---

## Supported Link Formats

| Format | Example |
|---|---|
| Short link | `https://xhslink.com/a/AbCdEf` |
| Full post URL | `https://www.xiaohongshu.com/explore/64f1a2b3c4d5e6f7a8b9c0d1` |
| Profile URL | `https://www.xiaohongshu.com/user/profile/5e1234567890abcdef123456` |

---

## Permissions Required

| Permission | Reason |
|---|---|
| `INTERNET` | Fetching media from Xiaohongshu servers |
| `WRITE_EXTERNAL_STORAGE` | Saving downloaded files (Android ≤ 9) |
| `MANAGE_EXTERNAL_STORAGE` | Saving to custom folder (Android 10+) |
| `POST_NOTIFICATIONS` | Download completion notifications |

---

## Troubleshooting

**"Cookie is required" error**
→ Upload a valid `cookies.txt` from a logged-in Xiaohongshu session in Settings.

**"No downloadable media found" error**
→ The post may be private or the cookie may have expired. Re-export a fresh cookie.

**Download stuck at 0%**
→ Check your internet connection. The XHS server may be temporarily blocking requests. Try increasing the delay in Settings.

**APK build fails with Gradle error**
→ Ensure you have JDK 17 installed and `JAVA_HOME` is set correctly. Run `flutter doctor` for diagnostics.

---

## Disclaimer

This tool is intended for personal use only. Respect the intellectual property rights of content creators. Do not redistribute downloaded content without permission. This project is not affiliated with Xiaohongshu (小红书) or its parent company.
