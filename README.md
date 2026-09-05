# ⛅ Mausam PersonalAI

> **Next-Generation Weather Intelligence & Adaptive Personalization Platform**  
> Built with Flutter (Mobile Shell & Visual Identity) and FastAPI (Personalization & Context Engine).

---

## 🚀 Quick Overview

Mausam PersonalAI is an intelligent weather experience tailored for **Fitness**, **Health**, and **Traveler** personas. It combines real-time Open-Meteo forecasts, AQI monitoring, localized environmental advisories, and an adaptive persona engine.

### 🌟 Key Highlights
- **Obsidian Monochrome Aesthetic:** Premium dark design system with dynamic glassmorphism and atmospheric wallpaper transitions.
- **3-Destination Dock & Weather AI Action:** Persistent bottom navigation with raised centerpiece Weather AI floating action.
- **Persona Context Engine:** Dynamic card ranking tailored for Fitness, Health, and Travel needs.
- **Zero-Config Teammate Google Sign-In:** Shared `debug.keystore` bundled directly in repository for seamless Google Sign-In across all developer OS environments.

---

## 🛠️ Prerequisites

Before getting started, ensure you have the following installed on your operating system:

| Tool | Minimum Version | Required For |
| :--- | :--- | :--- |
| **Git** | `2.30+` | Cloning codebase & submodules |
| **Flutter SDK** | `3.22+` (Channel Stable) | Running Mobile Application |
| **Java JDK** | `17` | Android Gradle Builds & Keytool |
| **Python** | `3.11+` | Local Backend Engine |
| **Docker Desktop / Engine** | `24.0+` | Containerized PostgreSQL, PostGIS & Redis |

---

## 💻 OS-Specific Installation & Setup Guides

### 🪟 Windows Setup Guide

#### 1. Clone the Repository
Open PowerShell or Git Bash:
```powershell
git clone https://github.com/VCXZZSE/mausam-weather-app.git
cd mausam-weather-app
```

#### 2. Environment Configuration
Copy the environment template:
```powershell
cp .env.example .env
```

#### 3. Start Backend & Infrastructure Services
**Option A: Using Docker Desktop (Recommended)**
Ensure Docker Desktop for Windows is running, then execute:
```powershell
docker-compose up -d --build
```

**Option B: Running Backend Locally (Without Docker)**
```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

#### 4. Run Mobile App
Open a new PowerShell terminal:
```powershell
cd mobile
flutter pub get
flutter doctor
```

- **Run on Android Emulator (Default):**
  ```powershell
  flutter run
  ```
- **Run on Physical Android Phone (Connected via USB or Wi-Fi):**
  Find your machine's local IP address using `ipconfig` (e.g. `192.168.1.43`), then run:
  ```powershell
  flutter run --dart-define=API_BASE_URL=http://192.168.1.43:8000
  ```

---

### 🐧 Linux Setup Guide (Ubuntu / Debian / Fedora)

#### 1. Install System Dependencies & Clone Repository
```bash
# Ubuntu / Debian
sudo apt update && sudo apt install -y git curl unzip openjdk-17-jdk python3-venv

# Clone Repository
git clone https://github.com/VCXZZSE/mausam-weather-app.git
cd mausam-weather-app
```

#### 2. Environment Configuration
```bash
cp .env.example .env
```

#### 3. Start Backend Services
```bash
# Using Docker Compose
docker compose up -d --build

# Verify backend health
curl http://localhost:8000/health
```

#### 4. Launch Flutter App
```bash
cd mobile
flutter pub get

# Run on connected emulator or Linux desktop target:
flutter run

# Or run on physical Android phone via LAN IP:
flutter run --dart-define=API_BASE_URL=http://192.168.1.43:8000
```

---

### 🍎 macOS Setup Guide

#### 1. Install Prerequisites via Homebrew & Clone
```bash
# Install Homebrew dependencies
brew install git flutter python@3.11 openjdk@17

# Clone Repository
git clone https://github.com/VCXZZSE/mausam-weather-app.git
cd mausam-weather-app
```

#### 2. Environment Configuration
```bash
cp .env.example .env
```

#### 3. Start Backend Services
Ensure Docker Desktop for Mac is running:
```bash
docker compose up -d --build
curl http://localhost:8000/health
```

#### 4. Run Mobile Application
```bash
cd mobile
flutter pub get

# Run on iOS Simulator or Android Emulator:
flutter run

# Run on physical iOS / Android device via LAN IP:
flutter run --dart-define=API_BASE_URL=http://<YOUR_MAC_IP>:8000
```

---

## 🔑 Google Sign-In Out-of-the-Box Configuration

> [!TIP]
> **Zero Configuration Required for Teammates!**
> 
> The project includes a shared development debug keystore at `mobile/android/app/debug.keystore` which matches the SHA-1 certificate fingerprint (`5C:0C:FB:6C:DC:3D:07:C2:1D:87:E0:D3:7F:07:F9:ED:FA:BA:30:8C`) pre-registered in `google-services.json`. 
> 
> Every teammate who clones the codebase on **Windows, Linux, or macOS** will automatically build debug APKs signed with this shared key, preventing `ApiException: 10` errors without needing to touch Firebase Console.

---

## 🧪 Testing & Code Verification

Run automated test suites and static analysis across platforms:

```bash
cd mobile

# Static Analysis
flutter analyze

# Run Complete Widget & Navigation Test Suite
flutter test
```

---

## 📱 Interactive Feature Demos

1. **Persona Switching Demo:**
   - Open the app and navigate to **Profile & Settings**.
   - Select **Fitness Enthusiast**, **Health Focus**, or **Active Traveler**.
   - Return Home or Insights to see prioritized cards, outdoor activity windows, and advisories automatically re-ranked.

2. **Location & Destination Switching:**
   - Tap the location title in the top Floating Navbar to open **My Locations**.
   - Select or search any destination city. The app dynamically fetches weather and personalized packing/commute insights for that location.

3. **Weather AI Centerpiece Action:**
   - Tap the raised central **Mausam Weather AI Action** on the bottom navigation dock to immediately view weather intelligence interpretations.
