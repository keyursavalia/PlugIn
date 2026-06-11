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
