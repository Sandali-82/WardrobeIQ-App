# WardrobeIQ

**Dress with Intelligence** — an AI-powered personal styling mobile app.

## Overview

WardrobeIQ is the Flutter client for the WardrobeIQ platform. It lets users build a digital wardrobe, get their face shape, body shape, and skin undertone analyzed, and receive AI-generated, occasion-based outfit suggestions and styling guidance.

## Features

- 🔐 Secure login/signup (JWT-based, connected to the WardrobeIQ API) with email confirmation and deep-link auto-login
- 👕 Add and delete wardrobe items (with photo upload), build outfits, and log what you wear on an outfit calendar
- 🔔 Optional "wear this today" reminders for outfits planned on the calendar
- 📐 Face shape & body shape results based on user measurements
- 🎨 Skin undertone detection from a photo (Gemini vision, via backend)
- 🧠 Occasion-based AI outfit suggestions tailored to the user's wardrobe and profile
- 💡 Personalized styling guide (necklines, hairstyles, sleeves, silhouettes, colors, items to avoid)

## Tech Stack

- **Framework:** Flutter
- **Backend:** [WardrobeIQ API](https://github.com/Sandali-82/WardrobeIQ-API) (ASP.NET Core + MongoDB + Gemini API)
- **Image hosting:** Cloudinary (direct unsigned upload from the device)
- **Main packages:** `http`, `shared_preferences`, `table_calendar`, `image_picker`, `flutter_local_notifications`, `timezone`, `app_links`

## Getting Started

### Prerequisites

- Flutter SDK (Dart SDK ^3.13.3)
- A running instance of the [WardrobeIQ API](https://github.com/Sandali-82/WardrobeIQ-API)

### Setup

1. Clone the repository

```bash
   git clone https://github.com/Sandali-82/WardrobeIQ-App.git
   cd WardrobeIQ-App
```

2. Install dependencies:

```bash
   flutter pub get
```

3. Point the app to your backend — update the `baseUrl` constant in `lib/services/http_api_service.dart`:

```dart
   static const String baseUrl = 'https://<your-backend-ip-or-domain>:<port>';
```

   During local development, this should be your machine's local network IP (not `localhost`), so the app can reach it from a physical device or emulator on the same network.

   > **Note:** the repository is currently configured to use the hosted API at `https://wardrobeiq-api.onrender.com`, so you can run the app without setting up your own backend. The API is hosted on Render's free plan, which puts the server to sleep after a period of inactivity. The first request after that (for example the first login) can take up to a minute while the server wakes up. Later requests are fast.

4. Run the app:

```bash
   flutter run
```

## Testing

Run the whole suite with:

```bash
flutter test
```

The project has more than 200 automated unit and widget tests. They run without a device, an emulator, or a network connection.

### How the code is structured for testing

- Screens never call the API directly. They go through small repositories (`ClothingRepository`, `OutfitRepository`, `WornLogRepository`, `SuggestionRepository`, `ProfileRepository`, `AuthRepository`). Each one has a static `instance`, so a test can swap in a mock:

```dart
  ClothingRepository.instance = MockClothingRepository();
```

- Repositories delegate to the abstract `ApiService`, which is implemented by `HttpApiService`. The HTTP client is injected, so the real request and error-handling logic can be tested with a fake client.
- Code that depends on platform plugins sits behind thin wrappers (`PhotoPicker`, `ImageUploader`, `ReminderService`), so screens that use the camera, uploads, or notifications can still be tested.
- Tooling: `flutter_test`, `mocktail`, and `MockClient` from the `http` package.

### What is covered

- **Widget tests for every screen:** loading, empty, error, and success states, form validation, confirmation dialogs, navigation, and the home tabs.
- **Model tests:** `fromJson` parsing, including defaults for missing fields and UTC to local date conversion.
- **Service tests:**
  - `HttpApiService`: session storage, request bodies and headers for every endpoint, backend error messages, timeouts, and connection errors.
  - `CloudinaryService`: multipart upload request and error handling.
  - `NotificationService`: reminder id logic, scheduling rules (reminders turned off, dates in the past, custom time), and cancelling.

### Not covered by automated tests (checked manually on a device)

- Camera and gallery picker, and the real Cloudinary upload
- Reminder notifications actually firing
- The email confirmation deep link opening the app
- Plugin initialisation at app start

## Screenshots

*(Coming soon — screenshots will be added once core screens are finalized.)*

## Related Repositories

- ⚙️ **Backend API (.NET):** [WardrobeIQ-API](https://github.com/Sandali-82/WardrobeIQ-API)

## License

MIT License

Copyright (c) 2026 Sandali Kodippili

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.