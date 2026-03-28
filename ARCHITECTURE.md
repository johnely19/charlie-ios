# Charlie iOS — Architecture

> The travel AI agent. Native iPhone experience. SwiftUI + MapKit + Apple Intelligence.

## What This Is

Charlie iOS is the **primary user experience** for the Charlie travel AI. It is a native iPhone app built with SwiftUI and MapKit that connects to the same Vercel Blob backend as Compass V2.

Compass V2 (web) becomes the admin layer — DevClaw's workspace, data management, owner dashboard.

## Strategic Position

**Charlie iOS is the product.**
- Map-first travel intelligence
- AI concierge in your pocket
- Apple Intelligence / Siri integration
- App Store distribution
- Works best where travel happens: on your phone, in the city, exploring

**Compass V2 is the tools layer.**
- Admin dashboard
- Data management (place cards, discoveries)
- DevClaw workspace
- Owner-only functionality

---

## Tech Stack

| Layer | Technology | Why |
|-------|-----------|-----|
| UI | SwiftUI | Apple-native, declarative, modern |
| Maps | MapKit (SwiftUI Map) | Apple Maps, iOS 17+ Map API |
| Networking | URLSession + AsyncSequence | Native Swift, streaming support |
| Storage | Keychain (auth) + UserDefaults (prefs) | Secure, native |
| AI Chat | Streaming via /api/chat | Same backend as Compass |
| Data | Codable structs mirroring Vercel Blob | Shared backend |
| AI Features | App Intents (iOS 17+) | Siri integration |
| Distribution | TestFlight → App Store | Apple ecosystem |

**iOS target: iOS 17.0+** (required for new Map SwiftUI API)

---

## App Architecture

```
CharlieApp
├── Core
│   ├── APIClient.swift          — All network calls to Vercel backend
│   ├── AuthManager.swift        — Token auth, Keychain storage
│   ├── Models/                  — Codable structs matching backend JSON
│   │   ├── Discovery.swift
│   │   ├── Context.swift
│   │   ├── PlaceCard.swift
│   │   ├── TriageState.swift
│   │   └── UserManifest.swift
│   └── Store/
│       ├── DiscoveryStore.swift  — @Observable discovery data
│       ├── TriageStore.swift     — Local + server triage sync
│       └── ContextStore.swift   — Active contexts
│
├── Map (primary screen)
│   ├── MapView.swift            — Main map with pins
│   ├── ContextSwitcher.swift    — Top bar: which trip/outing/radar
│   ├── PlacePinView.swift       — Custom map annotations
│   └── PlaceBottomSheet.swift   — Tap-to-reveal place card
│
├── PlaceCard
│   ├── PlaceCardView.swift      — Full place card detail
│   ├── PlaceCardHero.swift      — Hero image with overlay
│   ├── NarrativeView.swift      — Prose blocks (Space, Food, Vibe)
│   ├── MenuView.swift           — Formatted menu sections
│   ├── HoursView.swift          — Today's hours + open/closed
│   ├── PhotoGalleryView.swift   — Swipeable image gallery
│   └── TravelIntelView.swift    — Walk/transit from accommodation
│
├── Chat (Concierge)
│   ├── ChatView.swift           — Chat interface
│   ├── ChatMessage.swift        — Message bubble components
│   └── ConciergeBubble.swift    — Streaming response display
│
├── Trips
│   ├── TripView.swift           — Trip context header
│   ├── FlightCardView.swift     — Flight details
│   └── TripIntelView.swift      — People, schedule, anchors
│
├── Review
│   ├── ReviewListView.swift     — Needs Review / Saved / Dismissed
│   ├── NeighbourhoodSection.swift — Grouped by neighbourhood
│   └── TriageButtons.swift      — + / − with haptic feedback
│
└── Intents (Siri / Apple Intelligence)
    ├── GetRecommendationIntent.swift  — "What should I do tonight?"
    ├── SavePlaceIntent.swift          — "Save this to my NYC trip"
    └── CheckTrip Intent.swift         — "What's my NYC trip looking like?"
```

---

## Backend API Surface

Charlie iOS consumes the same Vercel backend as Compass V2. New endpoint needed:

### Token Auth (new — required for native app)
```
POST /api/auth/token
Body: { code: string }  (user's invite code)
Returns: { token: string, userId: string, name: string }
```

Token stored in iOS Keychain. Sent as `Authorization: Bearer {token}` header.

### Existing endpoints (already work)
```
GET  /api/user/discoveries     — All discoveries for user
GET  /api/user/manifest        — Contexts (trips, outings, radars)
POST /api/user/triage          — Save/dismiss triage state
GET  /api/user/triage          — Current triage state
POST /api/chat                 — Concierge chat (streaming)
GET  /api/admin/*              — Admin (owner only)
```

### New endpoints needed
```
GET  /api/user/preferences     — User taste profile (Layer 1)
POST /api/user/preferences     — Update preferences
GET  /api/placecards/{id}      — Full place card data (JSON)
POST /api/internal/discoveries — Disco push (already exists)
```

---

## Map Experience Design

### Primary Screen: The Map
```
┌─────────────────────────────────┐
│  [Charlie]  [NYC Trip ▾]  [💬]  │  ← context switcher + chat
├─────────────────────────────────┤
│                                 │
│        🗺️ Apple Maps            │
│                                 │
│  📍 Pin  📍 Pin                 │  ← color coded by type
│              📍 Pin             │     restaurant=orange, gallery=blue
│                                 │     saved=green, unreviewed=white
│                                 │
│                                 │
└────────────────┬────────────────┘
                 │ tap pin
                 ▼
┌─────────────────────────────────┐
│ [Hero Image]                    │
│ Cookshop ⭐ 4.5 (3,175) $$      │
│ 156 10th Ave · 25 min walk      │
│ [+ Save]  [− Skip]  [→ Details] │
└─────────────────────────────────┘
```

### Pin Colors by Type
- 🟠 Restaurant/Bar/Cafe
- 🔵 Gallery/Museum/Theatre
- 🟢 Saved places (any type)
- ⚪ Unreviewed
- 🟡 Resurfaced (needs re-review)
- 🏠 Accommodation base (Arnold's, cottage)

### MapKit Features to Use
- `Map { ForEach(...) { Marker(...) } }` — custom annotated pins
- `MapCameraPosition` — animate to neighbourhood on context switch
- `MapFeature` selection — system-provided POI tap
- `MKMapItemRequest` — resolve Place IDs to MKMapItem
- `MKLookAroundViewController` — Look Around (Apple's Street View) 
- `MKDirections` — walking/transit routes
- `MKLocalSearch` — search for new places to add

---

## Place Card Design (native)

The bottom sheet expands in two stages:
1. **Peek** (30% screen) — hero + name + vitals + triage
2. **Half sheet** (50%) — adds narrative prose
3. **Full sheet** (90%) — full card with map, photos, menu

This is the native `.presentationDetents([.height(300), .medium, .large])` pattern.

---

## Siri / App Intents

### Phase 1 Intents
```swift
struct GetRecommendationIntent: AppIntent {
    static var title: LocalizedStringResource = "Get a recommendation from Charlie"
    
    func perform() async throws -> some IntentResult {
        let recs = await APIClient.shared.getRecommendations(context: .tonight)
        return .result(value: recs.map { $0.name }.joined(separator: ", "))
    }
}
```

**"Hey Siri, ask Charlie what to do tonight"**
→ Charlie checks your active contexts, saved places, time of day
→ Returns top 3 recommendations by voice + card

### Phase 2 Intents
- "Add [place] to my NYC trip"
- "What's my NYC itinerary looking like?"
- "How far is [saved place] from Arnold's?"
- "Save the place I'm standing at"

---

## Phases

### Phase 1 — Foundation (now)
- [ ] Xcode project setup (CharlieApp)
- [ ] Models: Discovery, Context, PlaceCard, TriageState
- [ ] APIClient: auth, discoveries, manifest, triage
- [ ] Token auth endpoint in Compass V2 backend
- [ ] Basic map view with discovery pins
- [ ] Context switcher

### Phase 2 — Core Experience  
- [ ] Bottom sheet place cards
- [ ] Triage with haptics
- [ ] Photo gallery (native SwiftUI)
- [ ] Narrative blocks renderer
- [ ] Hours widget with open/closed
- [ ] Walk time from accommodation

### Phase 3 — Intelligence
- [ ] Chat with Concierge (streaming)
- [ ] Trip planning view (flights, accommodation, schedule)
- [ ] Neighbourhood grouping
- [ ] Look Around integration (Apple Street View)
- [ ] Route map overlay

### Phase 4 — Platform
- [ ] App Intents (Siri)
- [ ] Home screen widgets
- [ ] Lock screen widgets
- [ ] Push notifications (trip reminders, new discoveries)
- [ ] TestFlight distribution
- [ ] App Store submission

---

## Data Model (Swift)

```swift
// Discovery
struct Discovery: Codable, Identifiable {
    let id: String
    let name: String
    let type: DiscoveryType
    let contextKey: String
    let placeId: String?
    let heroImage: String?
    let address: String?
    let rating: Double?
    let lat: Double?
    let lng: Double?
    
    var coordinate: CLLocationCoordinate2D? {
        guard let lat, let lng else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
}

// Context (trip, outing, radar)
struct Context: Codable, Identifiable {
    let key: String
    let label: String
    let emoji: String
    let type: ContextType
    let city: String?
    let dates: String?
    let active: Bool
    
    var id: String { key }
}

// Triage
enum TriageState: String, Codable {
    case unreviewed, saved, dismissed, resurfaced
}

struct TriageEntry: Codable {
    let state: TriageState
    let updatedAt: Date
    let contextKey: String
}
```

---

## Development Approach

DevClaw builds this using Codex (ACP runtime, Swift/SwiftUI). Each issue is a focused feature that can be built, reviewed, and tested independently.

GitHub repo: `johnely19/charlie-ios`
Xcode project: `Charlie.xcodeproj`
Bundle ID: `com.charlie.travel`
Team: John's Apple Developer account

---

*Architecture finalized: 2026-03-28*
