# Find Restaurant

<p align="center">
  <b>An AI-Powered Restaurant Discovery & Dining Concierge Mobile Application built with Flutter & Firebase.</b>
</p>

<p align="center">
  <b>English</b> | <a href="README-tw.md">繁體中文</a>
</p>

---

## 📖 About The Project

**Find Restaurant** is a feature-rich, cross-platform mobile application designed to streamline restaurant discovery and dining decisions. Integrating the **Yelp Fusion API** with **Firebase AI Logic (Google Gemini)**, the app combines real-time location-based culinary exploration with cutting-edge multimodal artificial intelligence:

- **Conversational AI Concierge**: Understands natural language dining scenarios (e.g., *"Izakaya near Zhongshan station for 4 people with $600 budget"*) and responds with comparative recommendation matrices.
- **Interactive Decision Roulette**: A custom canvas-rendered animated wheel that randomly picks from candidates to solve dining indecision.
- **AI Menu Vision & Allergen Analysis**: Multimodal camera and gallery analysis that translates foreign menus into Traditional Chinese while detecting potential allergens and key ingredients.

Built with **Clean Architecture**, **BLoC (v9+)**, and **Dart 3**, the codebase demonstrates production-ready mobile engineering, strict unidirectional data flow, and adaptive cross-platform UI.

---

## 📸 Screenshots

| 1. Restaurant Discovery (Home) | 2. AI Dining Concierge | 3. Decision Roulette |
| :---: | :---: | :---: |
| <img src="doc/screenshots/Screenshot_home.png" width="240" alt="Home Screen" /> | <img src="doc/screenshots/Screenshot_ai_assistant_recommand.png" width="240" alt="AI Foodie Assistant" /> | <img src="doc/screenshots/Screenshot_roulette.png" width="240" alt="Decision Roulette" /> |
| **Explore Nearby Restaurants**<br>Distance, ratings, price tiers & categories | **Scenario-based Recommendations**<br>Natural language prompts & GenUI cards | **Random Draw Roulette**<br>Interactive canvas wheel to pick a place |

| 4. AI Menu Vision | 5. Restaurant Details & Navigation | 6. Authentication |
| :---: | :---: | :---: |
| <img src="doc/screenshots/Screenshot_menu_vision.png" width="240" alt="Menu Vision" /> | <img src="doc/screenshots/Screenshot_navigation.png" width="240" alt="Navigation & Street View" /> | <img src="doc/screenshots/Screenshot_login.png" width="240" alt="Login & Sign Up" /> |
| **Multimodal Menu Translation**<br>Ingredient breakdown & allergen alerts | **Google Maps & Navigation**<br>Route directions, Street View & phone dialing | **Identity & Guest Mode**<br>Google Sign-In, Email/Password & Guest access |

---

## ✨ Key Features

- 📍 **Nearby Restaurant Discovery**: Location-aware discovery powered by Yelp Fusion API with cuisine filtering, rating tiers, price levels, and user reviews.
- 🤖 **AI Smart Foodie Assistant**: Context-aware natural language recommendation powered by Gemini 3.5 Flash Lite via Firebase AI Logic.
- 🎡 **Decision Roulette**: Custom Canvas-rendered animated wheel that turns AI suggestions into an interactive dining lottery.
- 📸 **AI Menu Vision**: Multimodal OCR and translation for paper menus, breaking down ingredients, spicy levels, and 7 critical food allergens.
- 🗺️ **Map & Navigation**: Native Google Maps integration with routing, address directions, and Street View previews.
- 🔐 **Flexible Authentication**: Firebase Auth supporting Google Sign-In, Email/Password, and Guest Mode.
- 💖 **Cloud Favorites**: Real-time bookmarking and cloud synchronization via Cloud Firestore.

---

## 🏗️ Architecture & Tech Stack

### Clean Architecture Layers
```text
Presentation Layer (UI & BLoC)
       │
       ▼
Domain Layer (Entities & Repository Interfaces) ◄── Core business contracts (depends on equatable for value equality)
       ▲
       │
Data Layer (Repo Implementations, DTOs, Data Sources)
       │
       ▼
External Services (Yelp API, Firebase, Google Maps, Gemini)
```

### Tech Stack
| Layer / Domain | Technologies | Description |
| :--- | :--- | :--- |
| **Framework** | Flutter `>=3.44.1`, Dart `>=3.10.1` | Cross-platform mobile framework (Material 3 & iOS Native) |
| **Architecture** | Clean Architecture, Feature-First | Decoupled Presentation, Domain, and Data layers |
| **State Management** | `flutter_bloc ^9.1.1`, `equatable`, `rxdart` | Unidirectional data flow, event-driven reactive state |
| **Dependency Injection** | `get_it ^8.0.0` | Service locator and dependency inversion |
| **Generative AI** | `firebase_ai ^4.0.0` (Gemini 3.5 Flash Lite) | Multimodal vision recognition & A2UI GenUI structured output |
| **Network & REST** | `dio ^5.6.0`, `retrofit ^4.2.0` | Type-safe REST client with interceptors |
| **Cloud Backend** | Firebase (`Auth`, `Firestore`, `Messaging`, `Storage`) | Authentication, real-time database, cloud messaging & storage |
| **Maps & Location** | `google_maps_flutter ^2.4.0`, `geolocator ^14.0.3` | GPS location, turn-by-turn routing, and map layers |
| **Local Storage** | `sqflite ^2.3.0`, `shared_preferences ^2.2.0` | SQLite caching and key-value preference storage |
| **Cross-Platform UI** | `flutter_platform_widgets ^10.0.1` | Dynamic adaptation for iOS Cupertino and Android Material 3 |

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.44.1+)
- [Dart SDK](https://dart.dev/get-dart) (3.10.1+)
- Xcode 15+ (for iOS development) / Android Studio (for Android development)
- Yelp Fusion API Key & Google Maps API Key
- Firebase Project Configurations (`google-services.json` and `GoogleService-Info.plist`)

### Setup & Run

```bash
# 1. Clone the repository
git clone https://github.com/Yomiamy/Finding-Restaurant-Flutter.git
cd Finding-Restaurant-Flutter/flutter_restaruant/flutter_restaruant

# 2. Install dependencies
flutter pub get

# 3. Generate code (Retrofit / JSON Serializable)
dart run build_runner build --delete-conflicting-outputs

# 4. Run the app
flutter run
```
