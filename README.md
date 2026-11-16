# Hisaab

Expense tracker: log spends, split bills, settle up over UPI, track cash you
can't get from an SMS. Built with Expo (React Native).

## First-time setup (on your computer)

1. Install [Node.js](https://nodejs.org) (LTS version) if you don't have it.
2. Clone your repo, then inside the project folder:
   ```
   npm install
   ```
3. Install **Expo Go** on your phone from the Play Store / App Store.
4. Start the dev server:
   ```
   npm start
   ```
   This prints a QR code in your terminal.
5. Open Expo Go on your phone and scan the QR code. The app opens live on
   your device. Any time you edit a file and save, the app on your phone
   updates automatically — no rebuild needed.

## What's real vs. what's a stub right now

- **Expenses, splits, balances, budget, cash** — fully working, saved to
  your phone's local storage (`@react-native-async-storage/async-storage`).
  Close the app, reopen it, your data is still there.
- **UPI payment (`Pay` screen)** — fires a real `upi://pay` deep link via
  `Linking`, so it will open whatever UPI apps you have installed (GPay,
  PhonePe, Paytm, etc.) with the amount and payee pre-filled. This only
  works on a real device with a UPI app installed — it will not do anything
  useful in a simulator.
- **Settlement confirmation** — Android/iOS do not reliably tell an app
  whether a UPI payment actually succeeded, so after handing off to the UPI
  app, Hisaab asks *you* to confirm it went through before marking it
  settled. Auto-confirming from your bank's SMS (like the original design
  concept) is possible but needs Android SMS-read permission and a
  background listener — a good "v2" feature, intentionally left out for now
  since it's sensitive to get right (SMS access requires justifying to Google
  Play, and only works on Android).
- **Goals / vessel savings goals** — from the prototype, not yet built into
  this version. Next feature to add.

## Project structure

```
App.js                     entry point
src/
  Navigation.js             stack navigator (root)
  Tabs.js                   bottom tabs: Home / People / Settings
  theme/                    design tokens ported from the HTML prototype
  lib/
    storage.js               AsyncStorage persistence
    AppState.js               global app state + split/settle logic
    upi.js                    real UPI intent builder
    format.js                 currency formatting
  screens/                  one file per screen
  components/               shared UI (Glass panel, etc.)
```

## Suggested next steps

- Add the goals/vessel savings screen from the prototype
- Add editable split shares (currently splits evenly only)
- Add expense editing/deleting from the Home list
- Android SMS-based auto-settlement (v2, Android-only)
- App icon + splash screen assets
