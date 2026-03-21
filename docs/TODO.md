# Outstanding Tasks

## High Priority
- [ ] **Deploy Firestore rules** — paste `firestore.rules` into Firebase Console > Firestore > Rules and publish
- [ ] **RevenueCat setup** — replace placeholder API keys in `lib/config/subscription_config.dart` with real keys from RevenueCat dashboard
- [ ] **App Store / Play Store URLs** — update download button links in `home_screen.dart` `_buildDownloadAppCard()` with actual store URLs
- [ ] **Google Maps API key restrictions** — re-add HTTP referrer restrictions for the web key (`AIzaSyBTuiQ9cH1GMZzWiWeM3dSi_8Ca3Jn_uu8`) once domain `ummaly.net` is purchased
- [ ] **Server-side scan quota** — add rate limiting middleware in `ummaly_backend` to enforce scan limits by Firebase UID (client-side `ScanQuotaService` is a UX guardrail only)

## Medium Priority
- [ ] **Remove API keys from git history** — keys are now gitignored but still in commit history; consider `git filter-repo` or rotating the keys
- [ ] **Consolidate HTTP libraries** — `ScanHistoryController` still uses `dio`; migrate to `package:http` for consistency
- [ ] **Remove `HttpClientBinding`** — thin wrapper only used in `restaurant_search_screen.dart`; replace with direct `http` calls
- [ ] **Add team emails to allowlist** — `lib/core/services/scan_quota_service.dart` has empty `_allowlistEmails` set
- [ ] **iOS notification permissions** — test on physical iPhone; may need `Info.plist` entries for notification usage description
- [ ] **Test prayer notifications on all platforms** — verify scheduling works on Android (exact alarms), iOS (UNNotification), and web (browser Notification API)

## Low Priority
- [ ] **Fix broken test** — `test/widget_test.dart` references non-existent `MyApp` class; update to `UmmalyApp`
- [ ] **Add unit/widget tests** — zero working tests currently
- [ ] **Gate `print()` statements** — `api_service.dart` (now deleted), `locale_manager.dart` still have bare prints not gated by `kDebugMode`
- [ ] **Offline fallback for scanning** — handle no-network gracefully
- [ ] **Consolidate state management** — GetX used for navigation, ChangeNotifier used for state; pick one pattern
