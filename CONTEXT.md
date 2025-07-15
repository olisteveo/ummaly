# Ummaly – Halal Lifestyle Mobile App

## Problem Statement

Muslims around the world often lack access to a reliable, centralised digital solution that helps them find halal food, products, and services. Existing tools are outdated, fragmented, or incomplete. This gap leaves users struggling to navigate halal compliance confidently in daily life.

## Solution

Ummaly is a mobile-first lifestyle app that enables users to:
- Look up halal-certified restaurants by location
- Scan food and product barcodes for halal status (first 5 scans are free)
- Access personalised prayer times based on geolocation
- View Islamic blog content
- Browse community events
- Submit or flag halal data for moderation
- Subscribe for full features via Stripe integration

## Tech Stack

- **Frontend**: Flutter (Dart), developed in Android Studio
- **Backend**: Node.js (Express), developed in VS Code
- **Database**: PostgreSQL or MongoDB (scalable, read-optimised)
- **Subscriptions**: Stripe API integration
- **Geolocation**: Google Maps API

## User Roles

| Role              | Description                                      |
|-------------------|--------------------------------------------------|
| Guest             | Unregistered user with limited read-only access |
| Member            | Registered user with full access (free or paid) |
| Admin             | Internal team handling moderation and data      |
| Payment Processor | External system handling subscriptions (Stripe) |

## Use Case Summary

### Guest
- Sign up
- Verify location
- Browse restaurants
- Access dashboard (read-only)

### Member
- Login/logout
- Manage subscription
- Scan product barcodes
- View scan history
- Search and view restaurants
- Submit reviews
- Submit product info or restaurant suggestions
- Flag incorrect product info
- View prayer times
- Read blog posts
- View community events

### Admin
- Validate or manage product and restaurant records
- Moderate reviews and flagged content
- Post blog articles and events

### Payment Processor
- Process subscription payments via Stripe
- Validate user subscription status

## ERD Summary

### Tables and Key Fields

**roles**
- `id` (PK)
- `role_name`

**users**
- `id` (PK)
- `name`, `email`, `password_hash`
- `latitude`, `longitude`, `location_address`
- `subscription_id` (FK), `role_id` (FK)
- `monthly_scan_count`, `last_scan_reset`
- `language_preference`, `stripe_customer_id`
- `created_at`, `updated_at`

**subscriptions**
- `id` (PK)
- `subscription_type`, `start_date`, `end_date`
- `price`, `status`, `platform`, `is_active`
- `last_payment_date`

**restaurants**
- `id` (PK)
- `name`, `location`, `halal_status`
- `website_url`, `certification_body`
- `created_at`, `updated_at`

**reviews**
- `id` (PK)
- `user_id` (FK), `restaurant_id` (FK)
- `rating`, `comment`, `created_at`

**products**
- `id` (PK)
- `barcode`, `product_name`, `description`
- `is_halal` (ENUM), `source`
- `created_at`, `updated_at`

**scan_history**
- `id` (PK)
- `user_id` (FK), `product_id` (FK)
- `location`, `scan_timestamp`

**product_flags**
- `id` (PK)
- `user_id` (FK), `product_id` (FK)
- `reason`, `created_at`

**blog_posts**
- `id` (PK)
- `user_id` (FK)
- `title`, `content`, `image`
- `created_at`, `updated_at`

**prayer_times**
- `id` (PK)
- `date`, `fajr`, `dhuhr`, `asr`, `maghrib`, `isha`
- `location`, `latitude`, `longitude`

**events**
- `id` (PK)
- `title`, `description`, `date`
- `location_address`, `location_lat`, `location_lng`
- `created_by` (FK), `created_at`

**notifications**
- `id` (PK)
- `user_id` (FK)
- `type` (ENUM), `title`, `message`, `is_read`
- `created_at`

**localisations**
- `id` (PK)
- `key`, `language_code`, `value`

## MoSCoW Prioritisation

### Must-Have Features (MVP Critical)
- User registration and login
- Halal restaurant lookup by location
- Restaurant detail view with reviews
- Barcode scanner with lookup (first 5 scans free)
- Scan history per user
- Subscription system with Stripe
- Product data (with halal status)
- Prayer times based on user location
- Backend API for all above features
- Basic admin role for data seeding

### Should-Have Features
- Product flagging/reporting
- Notifications (prayer reminders, scan alerts)
- Blog posts / educational content
- Multilingual UI (Arabic/English initially)
- User profile with scan usage tracker
- Event system

### Could-Have Features
- RSVP to events
- Likes/upvotes on reviews or posts
- Halal certification document upload
- Notification inbox
- Blog translations
- User profile images or bios

### Will-Not-Have (for v1)
- Social features (DMs, followers)
- User-submitted restaurant listings
- Food delivery or in-app bookings
- Offline scanning or caching
- In-app admin dashboard (external tool only)

## Functional Requirements Summary

| ID   | Requirement                                                        |
|------|--------------------------------------------------------------------|
| FR1  | User registration, login, and logout                              |
| FR2  | Halal restaurant search                                            |
| FR3  | Restaurant detail view and reviews                                |
| FR4  | Barcode scanning for halal status                                 |
| FR5  | First 5 scans free; rest behind paywall                           |
| FR6  | Track scan history by user with location/timestamp                |
| FR7  | Prayer times based on geolocation                                 |
| FR8  | Admins can manage product and restaurant info                     |
| FR9  | Product flagging and reporting                                     |
| FR10 | Notifications for key user events                                 |
| FR11 | Multilingual UI via localisation table                            |
| FR12 | Community event listings                                          |

## Non-Functional Requirements Summary

- API response time: 95% of requests < 300ms
- Scalability: 100,000+ users with read-heavy workload
- Availability: 99.9% uptime
- Security: Encrypted data in transit and at rest
- Privacy: GDPR-compliant data handling (EU focus)
- Maintainability: Modular Node.js backend architecture
- Portability: App runs on both Android and iOS
- Usability: Scan flow < 10 seconds on average
- Extensibility: Easily expandable to support food delivery, loyalty, social features
- Backup: Daily DB backups with 7-day retention

## Development Setup

- Frontend: Flutter, developed in Android Studio
- Backend: Node.js, developed in VS Code
- Version control: Git + GitHub
