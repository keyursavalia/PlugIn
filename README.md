<h1 align="center">PlugIn</h1>

<p align="center">
  A native iOS marketplace that connects EV drivers with charger hosts — map-first, real-time, and built around a peer-to-peer credit economy.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-iOS%2016%2B-black?style=flat-square" />
  &nbsp;
  <img src="https://img.shields.io/badge/language-Swift-orange?style=flat-square" />
  &nbsp;
  <img src="https://img.shields.io/badge/backend-Firebase-yellow?style=flat-square" />
  &nbsp;
  <img src="https://img.shields.io/badge/maps-MapKit-blue?style=flat-square" />
  &nbsp;
  <img src="https://img.shields.io/badge/license-MIT-brightgreen?style=flat-square" />
</p>

<p align="center">
  <a href="https://youtu.be/Xc5KtwcJPWE">
    <img src="https://ytcards.demolab.com/?id=Xc5KtwcJPWE&title=PlugIn+App+Demo&lang=en&background_color=%230d1117&title_color=%23ffffff&stats_color=%23dedede&max_title_lines=1&width=560&border_radius=5" alt="Watch PlugIn Demo on YouTube" />
  </a>
</p>

---

## The Problem

Public EV charging infrastructure has not kept pace with adoption. In many neighborhoods, a driver's only realistic options are a distant commercial station or a long wait. Meanwhile, homeowners with Level 2 chargers sitting in their garages use them a few hours a week at most.

The gap is not hardware. It is access. Millions of chargers exist — they are just locked behind the wrong door.

PlugIn is the key. Hosts list their chargers, set their availability, and earn green credits when drivers book time on them. Drivers open a map, find a nearby charger that fits their car, and request a session. Everything else — notifications, confirmation, session tracking, credit accounting — happens inside the app in real time.

---

## What It Is

PlugIn is a two-sided marketplace for EV charging. Every user is both a potential driver and a potential host — you can discover chargers on the map, and when you are ready, register your own charger and start hosting from the same account.

**As a driver**, you open the map, see nearby chargers color-coded as live pins, and filter them by charger type, connector standard, credits per hour, and real-time availability. Tap a pin to see the charger's specs, the host's rating, and their weekly schedule. Tap *Request Charge*, pick a duration, and submit. The host gets a real-time notification and accepts or declines from their dashboard.

**As a host**, you register one or more chargers with their hardware specs and weekly availability schedule. Incoming booking requests appear as a notification badge on your dashboard. Accept with one tap and the session begins. Credits are credited to your account automatically when the session ends.

The green credits economy keeps both sides engaged: drivers buy credits in tiered packages, hosts earn credits per session, and every exchange happens without a traditional payment flow at the point of charging.

No account required beyond email. No subscriptions. Everything persists in the cloud via Firestore and is fully real-time across devices.

---

## Features

### For Drivers

- **Live Map Discovery** — MapKit map populated with real-time charger pins; each pin displays the host's credits-per-hour rate at a glance
- **Advanced Filtering** — filter by charger type (Level 1 / Level 2 / DC Fast Charging), connector standard (Tesla / CCS / CHAdeMO / J1772), maximum credits per hour, and live availability based on the host's weekly schedule
- **Charger Detail Sheet** — hardware specs, max charging speed, host rating, access instructions, and a map thumbnail in a single bottom sheet
- **Booking Request Flow** — pick an estimated duration, confirm the credit cost, and submit; request status updates in real time
- **Green Credits Wallet** — purchase credits in tiered packages (10 / 30 / 65 / 130 credits); current balance visible on the profile tab at all times
- **Booking History** — all past requests grouped by date with full status tracking (pending → accepted → active → completed / cancelled)
- **Charger Ratings** — rate sessions after completion; ratings aggregate on the host's charger card
- **Profile Management** — upload a photo, update account details, manage privacy settings, and control location sharing

### For Hosts

- **Charger Registration** — register a charger with type, connector, max speed, cable type, access instructions, and a pin-drop or GPS-snap location picker
- **Availability Scheduling** — set per-day start and end hours for each day of the week; disable specific days with a single toggle
- **Host Dashboard** — overview of all registered chargers with live availability toggles, booking counts, credits earned, and quick edit and delete controls
- **Incoming Requests Sheet** — real-time notification badge; one-tap accept or decline directly from the sheet without leaving the dashboard
- **Pricing Control** — set a custom credits-per-hour rate independently for each charger
- **Host Verification Badge** — verified hosts display a badge on their charger cards to build trust with drivers

### Core Platform Features

- **Firebase Authentication** — email and password sign-up and sign-in with persistent session state across app launches
- **Real-time Firestore Sync** — snapshot listeners in repositories and services propagate changes to both parties the moment they happen
- **Photo Storage** — Firebase Storage for profile photos and future charger images, with async upload progress and graceful error handling
- **Dual-role Accounts** — a single account can hold both the driver and host roles; adding a first charger promotes the account to host automatically; the tab bar adapts to show the driver map or host dashboard depending on which role is active
- **Portrait Lock** — consistent portrait-only orientation enforced via `AppDelegate` across both iPhone and iPad

---

## How the Booking Flow Works

A booking in PlugIn moves through a five-state lifecycle: **pending → accepted → active → completed** (or **cancelled** at any stage). Here is what happens at each step.

1. **Request** — the driver taps *Request Charge* on a charger detail sheet, picks an estimated session duration, reviews the credit cost, and confirms. A `Booking` document is written to Firestore with `status: pending` and a `requestedAt` timestamp. The driver's credit balance is not deducted yet.

2. **Notification** — Firestore's real-time listener on the host's dashboard surfaces the incoming request immediately. A bell icon on the Host Dashboard badge-counts unreviewed requests without requiring a push notification infrastructure.

3. **Accept or Decline** — the host opens the Incoming Requests sheet and taps accept or decline. Accepting sets `status: accepted` and writes an `acceptedAt` timestamp. Declining sets `status: cancelled`. Both state changes propagate to the driver's booking history in real time.

4. **Active Session** — once accepted, the booking transitions to `active` when the session starts. The `isActive` computed property (`status == .accepted || status == .active`) gates UI that should only be visible during a live session.

5. **Completion & Credits** — when the session ends, `status` becomes `completed`, an `endedAt` timestamp is written, `creditsUsed` is recorded, and both parties are prompted to rate each other. Credit deduction from the driver and credit award to the host happen at this step.

**Availability enforcement** runs before step 1. The `Charger.isAvailable(at:)` method checks the host's weekly schedule in `availabilitySchedule` and the charger's `status` field. Chargers that fail this check are excluded from the driver's map by `DriverMapViewModel.applyFilters()` before any pin is rendered, so drivers can never request a booking on an unavailable charger.

---

## Tech Stack

| | |
|---|---|
| **Language** | Swift |
| **UI Framework** | SwiftUI — `@Published` / `@ObservedObject` throughout |
| **Maps** | MapKit — `Map`, custom pin annotations via `ChargerPinView` |
| **Backend** | Firebase — Auth, Firestore, Storage |
| **Real-time Sync** | Firestore snapshot listeners in `ChargerRepository` and `BookingRepository` |
| **Location** | CoreLocation — live GPS for distance calculation and charger placement |
| **Concurrency** | Combine — reactive data binding; `@MainActor` dispatch for UI-safe Firestore callbacks |
| **Architecture** | Clean Architecture — MVVM + Repository + Coordinator + Service layers |
| **State** | `@StateObject` / `@EnvironmentObject` for `AuthService`, `LocationService`, `AppCoordinator` |
| **Navigation** | `AppCoordinator` with type-safe `NavigationDestination` enum |
| **Image Storage** | `FirebaseStorageService` — async upload/download with progress state |
| **Deployment Target** | iOS 16+ |
| **Dependencies** | Firebase iOS SDK (Swift Package Manager) |

---

## Project Structure

```
PlugIn/
├── App/
│   ├── PlugInApp.swift              ← @main, Firebase setup, environment object injection
│   └── AppDelegate.swift            ← Portrait orientation lock for iPhone and iPad
│
├── Configuration/
│   └── Config.swift                 ← Firebase project config and environment constants
│
├── Core/
│   ├── Navigation/
│   │   ├── AppCoordinator.swift     ← @ObservableObject: centralized navigation and sheet routing
│   │   └── NavigationDestination.swift  ← Type-safe enum of all navigable screens
│   │
│   ├── Services/
│   │   ├── Firebase/
│   │   │   ├── AuthService.swift           ← Persistent auth state listener, role promotion
│   │   │   ├── FirestoreService.swift      ← Centralized Firestore read/write operations
│   │   │   └── FirebaseStorageService.swift ← Async image upload and download
│   │   └── Location/
│   │       └── LocationService.swift       ← CoreLocation wrapper, distance filtering
│   │
│   ├── Components/
│   │   └── ImagePicker.swift        ← UIViewRepresentable photo library picker
│   │
│   └── Utilities/
│       ├── Extensions/              ← String, View, Date, Color, Double, TimeInterval
│       ├── Helpers/
│       │   ├── ValidationHelper.swift     ← Form field validation logic
│       │   └── FormattingHelper.swift     ← Credit and distance formatting
│       ├── Constants.swift
│       └── ErrorHandling.swift
│
├── Domain/
│   ├── Models/
│   │   ├── User.swift               ← Roles array, greenCredits, host verification flags
│   │   ├── Charger.swift            ← Hardware specs, availability schedule, isAvailable(at:)
│   │   └── Booking.swift            ← Five-state lifecycle, timestamps, credit tracking
│   │
│   ├── Enums/
│   │   ├── UserRole.swift           ← .driver / .host
│   │   ├── ChargerType.swift        ← Level1 / Level2 / DCFastCharging
│   │   ├── ConnectorType.swift      ← Tesla / CCS / CHAdeMO / J1772
│   │   ├── ChargerStatus.swift      ← Active / Inactive / Maintenance
│   │   └── BookingStatus.swift      ← Pending / Accepted / Active / Completed / Cancelled
│   │
│   └── Repositories/
│       ├── ChargerRepository.swift  ← Firestore CRUD + snapshot listener for charger list
│       └── BookingRepository.swift  ← Firestore CRUD + snapshot listener for booking updates
│
├── ViewModel/
│   ├── Authentication/
│   │   └── AuthViewModel.swift
│   ├── Driver/
│   │   └── DriverMapViewModel.swift ← Live charger list, applyFilters(), distance sort
│   ├── Booking/
│   │   └── BookingViewModel.swift   ← Request creation, state transitions
│   ├── HostDashboard/
│   │   └── HostDashboardViewModel.swift ← Charger management, request counts
│   ├── Request/
│   │   └── RequestViewModel.swift   ← Accept/decline, real-time request list
│   └── AddCharger/
│       └── AddChargerViewModel.swift ← Multi-step charger registration, location picker
│
└── Views/
    ├── Root/
    │   ├── RootView.swift           ← Auth gate → MainTabView
    │   └── MainTabView.swift        ← Driver map tab or Host dashboard tab based on active role
    ├── Authentication/              ← Sign-up and sign-in flows
    ├── Driver/
    │   ├── DriverMapView.swift      ← MapKit map with ChargerPinView annotations
    │   ├── ChargerDetailSheet.swift ← Bottom sheet with specs and Request Charge button
    │   ├── FilterSheet.swift        ← Multi-criteria filter panel
    │   └── SearchBar.swift
    ├── Booking/                     ← BookingRequestView, confirmation, request-sent states
    ├── AddCharger/                  ← Multi-step registration: type → location → schedule → price
    ├── HostDashboard/
    │   └── HostDashboardView.swift  ← Charger list cards with analytics and incoming request bell
    ├── Request/
    │   └── IncomingRequestSheet.swift ← Real-time accept/decline sheet
    ├── Profile/
    │   ├── ProfileView.swift        ← Photo, credits balance, booking history link
    │   ├── AddCreditsView.swift     ← Tiered credit packages with purchase flow
    │   ├── PastRequestsView.swift   ← Booking history grouped by date
    │   ├── AccountSettingsView.swift
    │   ├── PrivacySettingsView.swift
    │   └── AboutView.swift
    └── Common/Components/           ← PrimaryButton, SecondaryButton, DestructiveButton,
                                       CustomTextField, CustomDropdown, StatusBadge,
                                       VerifiedBadge, ChargerCard, StatsCard,
                                       LoadingView, SkeletonView, ErrorView, EmptyStateView
```

---

## Getting Started

**Requirements:** Xcode 15+, an iOS 16 simulator or device, and a Firebase project with Auth, Firestore, and Storage enabled.

```bash
git clone https://github.com/keyursavalia/PlugIn.git
cd PlugIn
open PlugIn/PlugIn.xcworkspace
```

**Firebase setup:**

1. Create a project at [console.firebase.google.com](https://console.firebase.google.com).
2. Enable **Email/Password** under Authentication → Sign-in method.
3. Create a **Firestore** database in test mode.
4. Enable **Firebase Storage**.
5. Download the `GoogleService-Info.plist` and drag it into the `PlugIn/PlugIn/` folder in Xcode — do not add it to source control.

The Firebase iOS SDK is managed via Swift Package Manager and resolves automatically when you open the workspace. Press `Cmd R` to build and run. Both the driver map and host dashboard are accessible from a single account — add a charger to activate the host role.

**Firestore collections used:**

| Collection | Purpose |
|---|---|
| `users` | User profiles, roles array, green credits balance |
| `chargers` | Charger documents with GeoPoint, specs, and availability schedule |
| `bookings` | Booking lifecycle documents with status and timestamps |

---

## What's Next

- **Push notifications** — APNs integration so hosts receive a lock-screen alert the moment a booking request arrives, not just an in-app badge
- **In-app messaging** — a lightweight chat thread between driver and host tied to a booking, for access instructions and coordination
- **Payment integration** — Stripe or Apple Pay to replace the demo credit-purchase flow with a real transaction layer
- **Review system with photos** — allow both parties to leave a written review and attach a photo alongside the star rating
- **Charger availability calendar** — a weekly calendar view for hosts to manage schedule exceptions (holidays, temporary unavailability) without editing the base schedule
- **Offline mode** — local cache for the charger list so drivers can browse previously loaded pins when connectivity drops
- **Unit and UI tests** — XCTest suite covering the booking state machine, filter logic, and credit calculation; UI tests for the critical driver and host flows
- **Dark mode** — full dark-mode pass across the SwiftUI component library
- **CI/CD pipeline** — GitHub Actions workflow for build verification and test runs on every pull request

---

## Contributing

Fork the repo, branch from `main`, one fix or feature per PR. Commit prefixes: `init:` / `add:` / `update:` / `fix:`. Bug reports and ideas are welcome as GitHub issues.

---

## License

[MIT](LICENSE) · © 2026 Keyur Savalia
