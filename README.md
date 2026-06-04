# Wēixūn Zhī Dù · 53° YÚN

A premium native iOS app for high-proof Chinese baijiu (Light / Sauce / Strong aroma) — an all-in-one experience for **degree mixing · tasting · provenance**.
Visual tone: ink-black background, gilded gold strokes, serif Chinese display type — minimal, luxurious, restrained.

> This repository is scaffolded by the **foundation team (project setup + design system + App Store, lead)**. Each feature package is built by its owner inside its own Swift Package, then integrated into `main` by the lead.

## Tech Stack
Swift 5.9+ · SwiftUI · iOS 17 minimum · MVVM · local Swift Package modularization · Swift Charts · Canvas/ImageRenderer · SwiftData · URLSession + async/await · XCTest · SwiftLint.

## Quick Start
```bash
open YunApp/YunApp.xcodeproj      # Open the committed project; select the YunApp scheme → run on any iOS 17 simulator
# Or regenerate the project with XcodeGen:
#   brew install xcodegen && cd YunApp && xcodegen generate
make help                         # List common commands
```
> · The committed `YunApp.xcodeproj` uses Xcode 16's "file-system synchronized groups" format and requires **Xcode 16+** to open.
>   On Xcode 15, regenerate a compatible project with `cd YunApp && xcodegen generate`.
> · If this machine has only the Command Line Tools (no full Xcode), `swift build` can compile the pure-logic packages, but the iOS app and simulator / XCTest runs are not available.

## Project Structure
```
YunApp/                      Main app project
  YunApp.xcodeproj           Committed, opens directly
  project.yml                XcodeGen spec (optional, avoids pbxproj merge conflicts)
  YunApp/                    App sources (age gate / TabBar / Profile / assets)
Packages/
  DesignSystem/   Colors / typography / components + the YunModule entry protocol
  Engine/         Pure calculation engine + shared data models (used by everyone)
  Mixing/         Unit conversion / ice dilution / alcohol units
  Recipes/        Recipe menu + flavor radar
  ShareCard/      Tasting-card export + sharing
  DeepLink/       QR codes + deep-link ordering (incl. the shared DeepLinkRouter)
  Health/         BAC "gentle buzz" curve
  Cellar/         Membership / my cabinet
  Authenticity/   Anti-counterfeit provenance verification
  AICompanion/    AI bartender
```

## Five Tabs
Mixing · Recipes · My Cabinet (Cellar) · Verify (Authenticity) · Profile (the main-app page that aggregates the Health / AICompanion / ShareCard / DeepLink entries plus compliance notes).

## Shared Data Contract (defined in `Engine`, referenced by everyone)
`AromaType` · `Component` · `MixResult` · `Recipe` · `FlavorProfile`. See `Packages/Engine/README.md`. **Do not redefine these per package.**

## Module Entry Convention (`DesignSystem.YunModule`)
Each feature package exposes a type conforming to `YunModule`, providing `tab` (title + SF Symbol) and `rootView() -> AnyView`.
The main app composes entries solely through this protocol, so **a finished module integrates with zero changes** — just swap the placeholder `XXHomeView` for the real root view.

## Deep-Link Spec (shared by ShareCard & DeepLink, interface implemented in `DeepLink`)
- Custom scheme: `yun://recipe?c=<base64(recipe JSON)>` (encode/decode and restore implemented)
- Universal Link: `https://yun53.com/r/<id>` (parses the id; resolving a recipe by id is owned by the DeepLink owner)
- The app wires `onOpenURL` → `DeepLinkRouter().resolve(url)` → `AppState`.
- Universal Links require deploying `apple-app-site-association` on `yun53.com`, and keeping `applinks:yun53.com` in `YunApp.entitlements`.

## Compliance Guardrails (critical for App Store, followed by everyone)
- Age rating **17+** (frequent/intense alcohol references).
- **Age gate on launch**: no entry without confirming 18+ (`AppStorage("yun.ageVerified")`, implemented).
- "Please drink responsibly / Do not serve alcohol to minors" throughout (`ResponsibleDrinkingBanner`); no wording that encourages excessive drinking.
- **No alcohol sales transactions inside the app.**
- Privacy: local processing first by default; any upload (health/AI) must be declared in `PrivacyInfo.xcprivacy`.

## Delivery Requirements
MVVM within each package, exposing only a clean `public` interface and SwiftUI views; self-test passing before commit + a written README; core logic must have XCTest coverage.

## App Store Checklist (final phase, lead)
- [ ] Register Apple Developer; create the app in App Store Connect; set Bundle ID `com.yun53.weixundu`
- [ ] Set DEVELOPMENT_TEAM and automatic signing; enable the Associated Domains capability
- [ ] Replace placeholder app icon / launch logo with final visual assets
- [ ] Install and register Noto Serif SC / Cormorant Garamond (see DesignSystem/README)
- [ ] Answer the age-rating questionnaire as 17+ (frequent/intense alcohol)
- [ ] Complete the `PrivacyInfo.xcprivacy` data-collection declaration + App privacy "nutrition labels"
- [ ] Screenshots (6.7" / 6.5" / iPad) + previews
- [ ] TestFlight beta → submit for review

---

## Integration Status (all modules merged)
All 10 feature packages + the foundation are integrated into `main`. Authoritative source per package:

| Package | Source worktree | Package | Source worktree |
|---|---|---|---|
| Foundation / YunApp / DesignSystem | vivacious-technician | ShareCard | veil-join |
| Engine | pool-dibble | Cellar | sticky-scaffold |
| Mixing | sneaky-calf | Authenticity | noon-puppet |
| Recipes | living-comb | AICompanion | abalone-clam |
| DeepLink | material-amphibian | Health | intelligent-seatbelt |

Duplicate packages were de-duplicated to the most complete implementation; build artifacts (`.build/`) were excluded via `.gitignore`.
