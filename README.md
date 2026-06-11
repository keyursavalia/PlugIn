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
