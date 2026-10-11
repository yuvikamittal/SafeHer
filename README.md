# SafeHer 🛡️

A personal-safety companion application for women, built with Flutter.
SafeHer brings essential safety tools into one modern and user-friendly
application, including emergency SOS, location sharing, safe-route guidance,
nearby emergency help, safety assistance, and trusted contacts.

> **Project Status:** Frontend prototype with a service-layer architecture.
> The Web version is currently the primary supported platform, while Android
> support is partially implemented. External device and network features
> currently use sample data so the project can run without exposing private
> credentials or requiring device permissions.

---

## 🌸 Overview

SafeHer is designed to provide a centralized safety experience for women.
Instead of switching between multiple applications during an emergency, users
can access important safety features from a single interface.

The current version focuses on the complete frontend experience and application
flow. Device and network-dependent functionality such as GPS, SMS, maps, push
notifications, and authentication is represented through a `services/` layer
using sample data.

The architecture is designed so that real APIs or device plugins can be
integrated later without changing the application's main UI.

---

## ✨ Features

### 🚨 Emergency SOS

- Hold-to-activate SOS countdown
- Emergency dispatch interface
- Call and message actions
- Quick access during emergency situations

### 📍 Live Location

- Location preview
- Location-sharing duration
- Per-contact location sharing
- Designed for future real GPS integration

### 🛣️ Safe Route

- Safety-scored route suggestions
- Route map interface
- Nearby police-station information
- Designed for future real map and routing integration

### 👥 Emergency Contacts

- Add trusted contacts
- Edit and remove contacts
- Per-contact safety controls
- Contact management interface

### 🏥 Nearby Help

- Police stations
- Hospitals
- Safe zones
- Shelters
- Category-based filtering

### 🔔 Alerts & Notifications

- Alerts and notifications interface
- Tab-based organization
- Adjustable notification sensitivity

### 🤖 Safety Assistant

- In-app safety assistant
- Keyword-based safety guidance
- Quick safety prompts
- Designed for future AI/API integration

### 👤 Profile & Settings

- User information
- Safety statistics
- Application preferences
- Safety-related settings

### 🔐 Authentication UI

- Email/password login interface
- Remember-me option
- Forgot-password flow
- Biometric and SSO entry points
- Request-access/sign-up form with validation

---

## 🛠️ Tech Stack

- **Framework:** Flutter
- **Language:** Dart
- **Architecture:** Service-layer architecture
- **UI:** Flutter Widgets
- **Data Layer:** Service classes with sample data
- **Primary Platform:** Web
- **Additional Platform:** Android (partial support)

---

## 📱 Platform Support

| Platform | Status |
|---|---|
| 🌐 Web | **Fully functional and currently the primary supported platform** |
| 🤖 Android | **Partially supported; some features and device-specific integrations are still under development** |
| 🍎 iOS | **Not currently supported/tested** |

The application is currently developed and tested primarily for the Web
platform. Android support is partially implemented, while additional
device-specific functionality can be developed in future iterations.

---

## 🏗️ Architecture

SafeHer follows a service-layer approach that separates the UI from external
device and network functionality.

```text
                    SafeHer App
                        │
                        ▼
                   UI / Screens
                        │
                        ▼
                    Services
                        │
                        ▼
                     Models
                        │
                        ▼
              Sample / External Data
