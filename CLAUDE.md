# STUDIO - Social Event App

## Project Vision
A social event app with **Pixel Afterdark** aesthetic - 8-bit retro nightlife, pixel art typography, pure black backgrounds. Inspired by Basel Afterdark event flyers. Each event is a collaborative space where up to 5 hosts can invite guests, share media, vote on polls, and update statuses.

---

## Tech Stack
| Component | Version | Notes |
|-----------|---------|-------|
| iOS | 26.1 | Unified versioning (jumped from 18→26) |
| Xcode | 26.2 | - |
| Swift | 6.2 | Strict concurrency |
| Supabase Swift | 2.x | Auth, Database, Storage, Realtime |
| Design | Pixel Afterdark | 8-bit retro, pixel font, pure black |

**Supabase Project**: `bhtexrnnrrymbhqonxfw`
**Secrets**: Stored in `Secrets.plist` (SUPABASE_URL, SUPABASE_ANON_KEY)

---

## Design System: Pixel Afterdark

### Design Philosophy
```
8-bit Retro × Nightlife × Pixel Art
Basel Afterdark flyer aesthetic

- Pure black (#000000) backgrounds only
- Pixel font (Press Start 2P) for everything
- ALL CAPS text with wide letter spacing
- Sharp pixel borders (Rectangle, never rounded)
- Monochromatic grayscale palette
- Disco ball imagery for placeholders
```

### Font
**VT323** - Google Fonts pixel/terminal typeface (more readable than Press Start 2P)
- Location: `Resources/Fonts/VT323-Regular.ttf`
- Registered in: `Info-Custom.plist` under `UIAppFonts`
- Font name constant: `"VT323"`

### Color System
| Name | Hex | Usage |
|------|-----|-------|
| studioBlack | #000000 | Primary background (PURE BLACK) |
| studioSurface | #0A0A0A | Cards, elevated surfaces |
| studioDeepBlack | #050505 | Deep surfaces |
| studioPrimary | #E0E0E0 | Primary text (off-white) |
| studioSecondary | #B0B0B0 | Secondary text |
| studioMuted | #707070 | Muted text, hints |
| studioChrome | #D0D0D0 | Accent, CTAs |
| studioLine | #2A2A2A | Borders, dividers |
| studioError | #FF6B6B | Error states |

### Typography Rules
```
ALL TEXT:
- VT323 pixel font (more readable than Press Start 2P)
- ALL CAPS for headlines and labels
- Wide letter spacing (1-5pt tracking)
- Larger sizes allowed (VT323 has taller glyphs)

SIZE GUIDE:
- Display: 36-48pt (hero text)
- Headlines: 20-28pt (page titles)
- Body: 14-18pt (content)
- Labels: 12-16pt (buttons, captions)
```

### Typography Modifiers
```swift
// Display styles - hero text (splash screens)
Text("AFTERDARK").studioDisplayLarge()   // 48pt
Text("PRIVATE EVENT").studioDisplayMedium()  // 36pt

// Headlines - page/section titles
Text("PAGE TITLE").studioHeadlineLarge()   // 24pt
Text("SECTION").studioHeadlineMedium()     // 20pt

// Body - content text
Text("Content").studioBodyLarge()    // 16pt
Text("Description").studioBodyMedium()  // 14pt

// Labels - buttons, captions
Text("BUTTON").studioLabelLarge()    // 16pt
Text("CAPTION").studioLabelSmall()   // 12pt
```

### Component Styles

**Buttons** - Pixel borders, pixel font
```swift
Button("ENTER") { }
    .buttonStyle(.studioPrimary)    // Filled pixel button

Button("CANCEL") { }
    .buttonStyle(.studioSecondary)  // Bordered pixel button

Button("LINK") { }
    .buttonStyle(.studioTertiary)   // Text only

Button("ENTER THE PARTY") { }
    .buttonStyle(.studioHero)       // Large splash button

Button("TAG") { }
    .buttonStyle(StudioPillButtonStyle(isSelected: true))
```

**Input Fields** - Pixel borders, pixel font
```swift
StudioTextField(
    title: "EMAIL",
    text: $email,
    placeholder: "enter your email",
    isRequired: true
)

StudioSearchField(text: $search, placeholder: "SEARCH")

StudioTextEditor(
    title: "BIO",
    text: $bio,
    maxLength: 150
)

StudioPicker(title: "CATEGORY", selection: $selected, options: options) { $0 }

StudioToggle(title: "NOTIFICATIONS", isOn: $enabled, subtitle: "receive updates")
```

**Cards** - Sharp pixel borders
```swift
StudioCard {
    // Content with pixel border
}

PixelBorderCard {
    // Double pixel border effect
}

EventCard(
    title: "BASEL AFTERDARK",
    subtitle: "Private event at undisclosed location",
    date: "DEC 4, 2025 | 10 PM - 5 AM",
    isPrivate: true
)

StatCard(title: "GUESTS", value: "24", icon: "person.2", trend: .up)

UserRowCard(name: "AFTERDARK", username: "afterdark", avatarUrl: nil, subtitle: "HOST")

PerformerBox(label: "PERFORMANCE BY", names: ["DJ NAME", "ARTIST NAME"])
```

**Avatars** - Square pixel style
```swift
AvatarView(url: avatarUrl, size: .large)           // Square with pixel border
AvatarView(url: url, size: .medium, showBorder: true)
PixelAvatarView(url: url, size: .large)            // Double pixel border
AvatarWithStatus(url: url, status: .online)        // Square status indicator
AvatarStackView(urls: [nil, nil, nil], maxDisplay: 3)  // Overlapping squares
```

**Empty States & Loading**
```swift
EmptyStateView.emptyFeed        // "NO EVENTS" with pixel styling
EmptyStateView.noSearchResults  // "NO RESULTS"
EmptyStateView.emptyNotifications
ErrorView(error: error, retryAction: { await retry() })
PixelLoadingIndicator()         // Animated pixel squares
```

### View Modifiers
```swift
// Pixel card styling
view.studioCard(padding: 16)

// Pixel borders
view.pixelBorder(color: .studioLine, lineWidth: 2)
view.doublePixelBorder(color: .studioLine)

// Full screen background
view.pixelBackground()

// Loading overlay
view.loadingOverlay(isLoading)

// Animations
view.scaleIn(from: 0.9, duration: 0.2)
view.slideUp(offset: 30, duration: 0.25)
view.pixelPulse()
view.staggeredAppearance(index: 0, baseDelay: 0.05)
view.pixelShimmer()
```

### Layout Rules
```
- Pure black backgrounds (#000000)
- Generous padding (20-32pt)
- Symmetrical compositions
- Strong vertical rhythm with pixel dividers
- Rectangle() for all borders (never rounded)
- Line dividers: 1pt height, studioLine color
```

### Icon Style
- SF Symbols with `.ultraLight` or `.light` weight
- Size: 10-40pt depending on context
- Color: `.studioMuted` for decorative, `.studioChrome` for interactive
- Use `.system(size:weight:)` for consistency

---

## Project Structure

```
STUDIO/
├── App/
│   ├── STUDIOApp.swift
│   ├── RootView.swift
│   └── Routes.swift
├── Core/
│   ├── Supabase/
│   │   ├── SupabaseConfig.swift
│   │   └── SupabaseClient.swift
│   ├── Services/
│   │   ├── AuthService.swift
│   │   ├── StorageService.swift
│   │   └── NotificationService.swift
│   └── Managers/
│       ├── CameraManager.swift
│       ├── HapticManager.swift
│       └── SoundManager.swift
├── Models/
│   ├── User.swift
│   └── Party.swift
├── Features/
│   ├── Auth/
│   ├── Feed/
│   ├── Party/
│   ├── Media/
│   ├── Social/
│   ├── Profile/
│   └── Settings/
├── Components/
│   ├── Buttons/StudioButton.swift
│   ├── Inputs/StudioTextField.swift
│   ├── Cards/StudioCard.swift
│   ├── Media/AvatarView.swift
│   └── Feedback/LoadingView.swift, EmptyStateView.swift
├── Extensions/
│   ├── Color+Extensions.swift
│   ├── Typography+Extensions.swift
│   └── View+Extensions.swift
├── Resources/
│   └── Fonts/
│       └── VT323-Regular.ttf
└── Info.plist (registers UIAppFonts)
```

---

## Data Models

### User
```swift
struct User: Codable, Identifiable, Sendable, Hashable {
    let id: UUID
    var username: String
    var displayName: String?
    var avatarUrl: String?
    var bio: String?
    let createdAt: Date
    var updatedAt: Date
}
```

### Party
```swift
struct Party: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    var title: String
    var description: String?
    var coverImageUrl: String?
    var partyDate: Date?
    var isActive: Bool
    var isPublic: Bool
    var hosts: [PartyHost]?
    var guests: [PartyGuest]?
}
```

### Key Enums
- `GuestStatus`: pending, accepted, declined, maybe
- `PollType`: partyMVP, bestDressed, bestMoment, custom
- `StatusType`: drunkMeter, vibeCheck, energy
- `MediaType`: photo, video
- `VibeLevel`: 1-5 (grayscale intensity)

---

## Swift Patterns (CRITICAL)

### State Management
```swift
@Observable
class ViewModel {
    var items: [Item] = []
}

struct ContentView: View {
    @State private var vm = ViewModel()
}
```

### Navigation
```swift
NavigationStack(path: $path) {
    List(items) { item in
        NavigationLink(value: item) { ItemRow(item: item) }
    }
    .navigationDestination(for: Item.self) { DetailView(item: $0) }
}
```

### Supabase Queries
```swift
// SELECT with joins
let parties: [Party] = try await supabase
    .from("parties")
    .select("*, hosts:party_hosts(*, user:profiles(*))")
    .execute()
    .value

// INSERT
try await supabase.from("items").insert(newItem).execute()

// UPDATE
try await supabase.from("items")
    .update(["field": value])
    .eq("id", value: id.uuidString)
    .execute()
```

### Async Data Loading
```swift
.task {
    await vm.loadData()  // Auto-cancels on view disappear
}
```

---

## NEVER USE (Deprecated)
```swift
// ❌ NavigationView { }              → Use NavigationStack
// ❌ NavigationLink(destination:)    → Use .navigationDestination(for:)
// ❌ class VM: ObservableObject { }  → Use @Observable
// ❌ @Published var x                → Not needed with @Observable
// ❌ @StateObject var vm             → Use @State with @Observable
// ❌ supabase.database.from()        → Use supabase.from()
// ❌ .cornerRadius()                 → Use sharp edges (Rectangle)
// ❌ RoundedRectangle                → Use Rectangle for Basel Afterdark
// ❌ .onAppear { Task { } }          → Use .task { }
// ❌ AVAsset(url:)                   → Use AVURLAsset(url:)
```

---

## Supabase Backend

### Database Tables (12)
profiles, parties, party_hosts, party_guests, party_media, party_comments, party_polls, poll_options, poll_votes, party_statuses, follows, notifications

### Storage Buckets
- `avatars` (public, 5MB limit)
- `party-media` (private with RLS, 100MB limit)

### RLS Pattern
```sql
-- Always use (SELECT auth.uid()) for performance
CREATE POLICY "policy_name" ON table_name
FOR SELECT TO authenticated
USING ((SELECT auth.uid()) = user_id);

-- INSERT policies use WITH CHECK
CREATE POLICY "insert_policy" ON table_name
FOR INSERT TO authenticated
WITH CHECK ((SELECT auth.uid()) = user_id);
```

### Realtime Enabled
party_comments, party_statuses, poll_votes, party_guests, notifications

---

## Supabase Security & Best Practices

### Storage Security (CRITICAL)

**party-media Bucket RLS**:
```sql
-- ✅ SECURE: Only party members can upload
CREATE POLICY "Party members can upload party media" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (
    bucket_id = 'party-media'
    AND (SELECT auth.uid()) IS NOT NULL
    AND (
        EXISTS (
            SELECT 1 FROM party_hosts ph
            WHERE ph.party_id::text = (storage.foldername(name))[1]
            AND ph.user_id = (SELECT auth.uid())
        )
        OR EXISTS (
            SELECT 1 FROM party_guests pg
            WHERE pg.party_id::text = (storage.foldername(name))[1]
            AND pg.user_id = (SELECT auth.uid())
            AND pg.status = 'accepted'
        )
    )
);
```

**Signed URL Expiry**:
```swift
// ✅ CORRECT: 24-hour expiry
.createSignedURL(path: fileName, expiresIn: 86400) // 24 hours

// ❌ WRONG: 7-day expiry (security risk)
.createSignedURL(path: fileName, expiresIn: 3600 * 24 * 7)
```

**Storage Path Pattern**:
```swift
// ✅ CORRECT: {partyId}/{mediaId}.jpg
let fileName = "\(partyId.uuidString)/\(UUID().uuidString).jpg"

// ❌ WRONG: Arbitrary paths or missing party validation
let fileName = "uploads/\(UUID().uuidString).jpg"
```

### Realtime Subscriptions

**Poll Vote Filtering** (IMPORTANT):
```swift
// Realtime subscriptions to poll_votes receive ALL votes (not just this party's)
// MUST filter client-side:

private func handlePollVoteUpdate(_ vote: PollVote, action: ChangeAction) {
    // ✅ Filter by party's polls
    guard polls.contains(where: { $0.id == vote.pollId }) else {
        return // Ignore votes from other parties
    }

    // Process vote...
}
```

**Subscription Pattern**:
```swift
// ✅ Filter by party_id where possible
let commentsChanges = await channel.postgresChange(
    AnyAction.self,
    schema: "public",
    table: "party_comments",
    filter: "party_id=eq.\(partyId.uuidString)"
)

// ⚠️ Can't filter poll_votes by party (no direct party_id)
// Must filter client-side in handler
```

### RLS Policy Patterns

**Avoid Infinite Recursion**:
```sql
-- ❌ WRONG: Causes infinite recursion
CREATE POLICY "View parties" ON parties
FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM party_guests pg
        WHERE pg.party_id = parties.id  -- ← Queries parties from parties policy
    )
);

-- ✅ CORRECT: Use separate policies
CREATE POLICY "View own parties" ON parties
FOR SELECT USING (created_by = (SELECT auth.uid()));

CREATE POLICY "View invited parties" ON parties
FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM party_guests pg
        WHERE pg.party_id = parties.id
        AND pg.user_id = (SELECT auth.uid())
    )
);
```

**Performance Optimization**:
```sql
-- ✅ Wrap auth.uid() in SELECT for caching
WHERE user_id = (SELECT auth.uid())

-- ❌ Don't call auth.uid() directly multiple times
WHERE auth.uid() = user_id
```

### Security Checklist

**Before Deploying Storage Features**:
- [ ] Storage RLS policies validate party membership
- [ ] Signed URLs use 24-hour expiry (86400 seconds)
- [ ] Upload paths follow `{partyId}/{mediaId}.ext` pattern
- [ ] File size limits enforced (5MB avatars, 100MB party-media)

**Before Deploying Realtime Features**:
- [ ] Subscriptions filter by party_id where possible
- [ ] Client-side filtering for cross-party data (poll_votes)
- [ ] RLS policies don't cause infinite recursion
- [ ] Handlers validate data belongs to current context

**Before Deploying Database Features**:
- [ ] INSERT policies use WITH CHECK (not USING)
- [ ] RLS policies use (SELECT auth.uid()) for performance
- [ ] No circular dependencies in RLS policies
- [ ] Indexes exist on frequently joined columns

### Common Pitfalls

**Silent RLS Failures**:
```swift
// ⚠️ RLS blocks return empty arrays, not errors
let guests: [PartyGuest] = try await supabase
    .from("party_guests")
    .select()
    .execute()
    .value  // Returns [] if RLS blocks (no error thrown)

// ✅ Add explicit permission checks for better UX
guard try await canViewParty(partyId) else {
    throw AppError.accessDenied
}
```

**Storage Path Manipulation**:
```swift
// ❌ WRONG: User could manipulate partyId
func uploadMedia(userProvidedPath: String) {
    // User sends: "../other-party/malicious.jpg"
}

// ✅ CORRECT: Always construct paths server-side
func uploadMedia(partyId: UUID, image: UIImage) {
    let fileName = "\(partyId.uuidString)/\(UUID().uuidString).jpg"
}
```

---

## Quick Reference
- **iOS 26.1** | **Xcode 26.2** | **Swift 6.2** | **Supabase Swift 2.x**
- **Supabase Project**: bhtexrnnrrymbhqonxfw
- **Secrets**: Secrets.plist
- **Design**: Pixel Afterdark - 8-bit retro, pure black, pixel borders
- **Font**: VT323 (`"VT323"`) - readable pixel font
- **Typography**: VT323 pixel font, ALL CAPS, wide tracking (1-5pt)
- **Colors**: Pure black #000000, off-white #E0E0E0, gray #2A2A2A borders
- **Shapes**: Sharp pixel edges (Rectangle), never rounded
- **Context7**: `use library /supabase/supabase` for docs

---

## Workflow Rules

### Git Workflow (MANDATORY)
**Always commit changes immediately after making them.** Do not wait or ask - just commit.

1. After ANY file edit, create, or delete → commit immediately
2. Use descriptive commit messages following conventional commits
3. Push to origin after each commit

### Commit Format
```
feat: Add [feature description]
fix: Fix [bug description]
refactor: Refactor [component]
docs: Update [documentation]
style: Update styling/formatting
chore: Update build/config
```

### Example Workflow
```
1. Make changes to files
2. git add .
3. git commit -m "feat: Add party creation flow"
4. git push origin main
```
