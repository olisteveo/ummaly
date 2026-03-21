# Changelog

## 2026-03-21 — Health Audit & Performance Fixes

### Startup Performance
- Parallelised critical init calls (`Firebase`, `EasyLocalization`, `SystemChrome`) via `Future.wait`
- `runApp()` now fires immediately after Firebase init — splash shows while services load in background
- Removed blocking Firestore call from `LocaleManager.init()` at startup; replaced with instant `initFromDevice()`
- Deferred `PillarContentService`, `SubscriptionService`, `FavoritesService`, `PrayerNotificationService` to load in parallel during splash animation
- Profile screen: removed redundant `PrayerNotificationService.load()` call; added 3s timeout on Firestore user query

### Security
- Created `firestore.rules` — users can only read/write their own document; all other collections denied
- Updated `.gitignore` to exclude `google-services.json`, `GoogleService-Info.plist`, `.env`, service account keys
- Fixed account deletion treating 401 (Unauthorized) as success — now throws error so user can retry

### Code Cleanup
- Removed dead code: `ApiService`, `ScanHistoryService`, `GuestService`, `PingService`
- Removed deprecated `Config` class — all callers migrated to `AppConfig`
- Deleted `backup/` folder (duplicate files + 633KB git bundle)
- Deleted junk zero-byte files at project root (`$`, `bash`, `java`, `INFO`, `ollie@LAPTOP-EAGA3J5M`)

### Prayer Notifications
- Built full notification system for web, Android, and iOS
- `NotificationDispatcher` — platform-agnostic singleton with conditional imports
- `MobileNotifier` — `flutter_local_notifications` v21, exact alarm scheduling, boot receiver
- `WebNotifier` — browser Notification API via `dart:js_interop`, 30s polling timer
- Added notification toggle bar on home dashboard (attached below prayer card, auth users only)
- Android: added `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, `RECEIVE_BOOT_COMPLETED` permissions + boot receiver
- Toggle saves preference even if browser blocks permission (graceful degradation)

### Web/Mobile Differentiation
- Home screen: barcode scanner card replaced with "Download the App" CTA on web
- Profile: guest CTA text adjusted for web context (no barcode scanner references)
- Scan history hidden on web

### Restaurant Search
- Fixed map scroll/zoom conflict on web — disabled scroll-based gestures on map to prevent list scrolling from zooming the map
- Custom map styling with Ummaly design system (emerald/teal/gold/cream)
- Teal marker hues, branded recenter button

### Branding
- Replaced all web icons (favicon, 192px, 512px, maskable) with Ummaly mosque logo
- Added SVG favicon for crisp rendering at any tab size
- Updated page title to "Ummaly"
