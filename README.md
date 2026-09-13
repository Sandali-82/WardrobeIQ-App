# WardrobeIQ

**Dress with Intelligence** — an AI-powered personal styling mobile app.

## Overview

WardrobeIQ is the Flutter client for the WardrobeIQ platform. It lets users build a digital wardrobe, get their face shape, body shape, and skin undertone analyzed, and receive AI-generated, occasion-based outfit suggestions and styling guidance.

## Features

- 🔐 Secure login/signup (JWT-based, connected to the WardrobeIQ API)
- 👕 Add, edit, and browse wardrobe items, outfits, and worn logs
- 📐 Face shape & body shape results based on user measurements
- 🎨 Skin undertone detection from a photo (Gemini vision, via backend)
- 🧠 Occasion-based AI outfit suggestions tailored to the user's wardrobe and profile
- 💡 Personalized styling guide (necklines, hairstyles, sleeves, silhouettes, colors, items to avoid)

## Tech Stack

- **Framework:** Flutter
- **Backend:** [WardrobeIQ API](https://github.com/Sandali-82/WardrobeIQ-API) (ASP.NET Core + MongoDB + Gemini API)

## Getting Started

### Prerequisites

- Flutter SDK (version used by this project)
- A running instance of the [WardrobeIQ API](https://github.com/Sandali-82/WardrobeIQ-API)

### Setup

1. Clone the repository

   ```bash
   git clone https://github.com/Sandali-82/WardrobeIQ-App.git
   cd wardrobe_app
   ```

2. Install dependencies:

   ```bash
   flutter pub get
   ```

3. Point the app to your backend — update the `baseUrl` constant in `lib/services/api_service.dart`:

   ```dart
   static const String baseUrl = 'https://<your-backend-ip-or-domain>:<port>';
   ```

   During local development, this should be your machine's local network IP (not `localhost`), so the app can reach it from a physical device or emulator on the same network.

4. Run the app:

   ```bash
   flutter run
   ```

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