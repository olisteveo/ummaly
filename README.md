# ummaly

Halal Verification App for Android & ios

# Ummaly – Halal Lifestyle Mobile App

**Ummaly** is a modern mobile application designed to help Muslims make informed halal decisions in daily life. It brings together restaurant discovery, product barcode scanning, prayer times, Islamic content, and event listings into a single, trusted platform.

---

## Purpose

Ummaly addresses the lack of a reliable, unified source for halal verification. Existing tools are often outdated, fragmented, or limited in scope. Ummaly offers a streamlined and user-friendly experience backed by community input and trusted data sources.

---

## Core Features (MVP)

- Search halal-certified restaurants by location
- Scan food and product barcodes to check haram ingredients (first 5 scans free)
- Track individual scan history by user
- View prayer times based on user geolocation
- Subscribe for unlimited scanning and full access using Stripe
- View Islamic blog posts and educational content
- Browse community events
- Basic admin functionality for content moderation and data management

---

## Tech Stack

| Layer                  | Stack                                                           |
|------------------------|-----------------------------------------------------------------|
| **Frontend**           | Flutter (Dart) – built for Android & iOS                       |
| **Backend**            | Node.js (Express)                                              |
| **Database**           | PostgreSQL (Neon) with Prisma ORM                              |
| **Authentication**     | Firebase Authentication (email/password, password reset, email verification) |
| **Payments**           | Stripe API (planned)                                           |
| **Cloud Functions**    | Firebase Admin SDK (token verification, future server tasks)   |
| **APIs & Integrations**| Open Food Facts API (product data), future halal certification APIs |
| **Developer Tools**    | Android Studio (Flutter frontend), VS Code (Node.js backend), GitHub (version control) |
| **Hosting/Infra**      | Local dev server for backend (moving to cloud later)           |


---

## Project Structure (Flutter)



## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
