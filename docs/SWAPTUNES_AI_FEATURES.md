# SwapTunes — AI Features Master Document

> **Features:** AI Collab Match + AI Song Concept Generator  
> **Role scope:** Creator only  
> **AI Provider:** Google Gemini 2.0 Flash (provider-agnostic by design)  
> **Document Version:** 1.0 — April 2026

---

## Table of Contents

1. [Feature Overview](#1-feature-overview)
2. [User Flows](#2-user-flows)
3. [Frontend — File Structure](#3-frontend--file-structure)
4. [Frontend — Screen Specs](#4-frontend--screen-specs)
5. [Frontend — ViewModels](#5-frontend--viewmodels)
6. [Frontend — Repositories](#6-frontend--repositories)
7. [Frontend — Models](#7-frontend--models)
8. [Backend — File Structure](#8-backend--file-structure)
9. [Backend — AI Service](#9-backend--ai-service)
10. [Backend — Collab Match](#10-backend--collab-match)
11. [Backend — Song Concept](#11-backend--song-concept)
12. [Backend — Validation](#12-backend--validation)
13. [Backend — Routes](#13-backend--routes)
14. [Environment Variables](#14-environment-variables)
15. [Feature Connection — The Full Story](#15-feature-connection--the-full-story)
16. [Viva Talking Points](#16-viva-talking-points)

---

## 1. Feature Overview

### 1.1 AI Collab Match

A creator opens one of their collab listings and taps **"Find Matching Creators"**. The backend fetches all active creator profiles from the platform, sends them alongside the collab listing to Gemini, and returns the top 5 most compatible creators ranked by match score with a human-readable reason.

**Why it matters:**  
Currently creators post a listing and wait passively. This feature makes discovery active — the platform does the matching work for you.

---

### 1.2 AI Song Concept Generator

A creator inputs a genre, mood, and theme keywords. The backend sends this to Gemini and returns a fully structured song concept card: title, mood, lyrical direction, suggested instruments, BPM range, song structure, and a sample hook line.

Entry points: **Collab Tab (top area)** and **Creator Profile tab**.

The result screen includes a **"Send via Message"** button that auto-suggests the matched creators from Collab Match as recipients — directly connecting both features.

**Why it matters:**  
Gives creators a creative starting point and immediately connects that idea to the right collaborators on the platform.

---

### 1.3 How the Two Features Connect

```
Creator posts collab listing
  → Find Matching Creators (AI Collab Match)
    → sees top 5 matched creators
      → opens Song Concept Generator
        → generates concept card
          → Send via Message
            → matched creators are auto-suggested as recipients
              → conversation opens with concept card as first message
```

This is a continuous AI-powered creator workflow, end to end, native to SwapTunes.

---

## 2. User Flows

### 2.1 AI Collab Match Flow

```
CollabDetailScreen (creator viewing own collab)
  → "Find Matching Creators" button (creator only, shown via role check)
    → CollabMatchViewModel.fetchMatches(collabId)
      → loading state → full screen shimmer
        → POST /api/v1/collabs/:collabId/match
          → success → CollabMatchScreen
            → match cards (avatar, username, score %, reason)
              → "View Profile" → existing UserProfileScreen
              → "Message" → existing ChatScreen (new conversation)
          → error → inline error with retry button
```

---

### 2.2 AI Song Concept Flow

```
Entry Point A: Collab Tab top area button
Entry Point B: Creator Profile tab button
  → SongConceptInputScreen
    → genre (dropdown from existing genre list)
    → mood (text input or chips)
    → theme keywords (chip input, max 5)
      → "Generate Concept" button
        → SongConceptViewModel.generate()
          → loading state → animated generating screen
            → POST /api/v1/creator/song-concept
              → success → SongConceptResultScreen
                → concept card (title, mood, themes, instruments, BPM, structure, hook)
                → "Regenerate" → calls generate() again with same inputs
                → "Send via Message" → MessageRecipientSheet
                    → auto-suggests matched creators (from CollabMatchViewModel cache)
                    → user selects recipient
                    → concept card sent as formatted message
                    → navigates to ChatScreen
              → error → inline error with retry
```

---

## 3. Frontend — File Structure

```
mobile/
  lib/
    features/
      collab/
        screens/
          collab_match_screen.dart              ← NEW
        viewmodels/
          collab_match_viewmodel.dart           ← NEW
        repositories/
          collab_match_repository.dart          ← NEW
        widgets/
          match_card.dart                       ← NEW
          match_card_shimmer.dart               ← NEW

      creator/
        screens/
          song_concept_input_screen.dart        ← NEW
          song_concept_result_screen.dart       ← NEW
          song_concept_generating_screen.dart   ← NEW
        viewmodels/
          song_concept_viewmodel.dart           ← NEW
        repositories/
          song_concept_repository.dart          ← NEW
        models/
          song_concept_model.dart               ← NEW
        widgets/
          concept_card.dart                     ← NEW
          concept_section_tile.dart             ← NEW
          message_recipient_sheet.dart          ← NEW

    core/
      services/
        (ai.service.js lives on backend only)
```

**Existing files that need modification:**

| File | Change |
|---|---|
| `collab_detail_screen.dart` | Add "Find Matching Creators" button (creator only) |
| `collab_tab.dart` | Add "Song Concept" entry point button at top |
| `creator_profile_tab.dart` | Add "Song Concept" entry point button |
| `app_router.dart` | Register 4 new routes |

---

## 4. Frontend — Screen Specs

### 4.1 `CollabMatchScreen`

**Purpose:** Displays AI-returned creator matches for a collab listing.

**UI Structure:**
```
AppBar: "Matched Creators" + collab title subtitle
Body:
  Header section:
    - "AI found X creators that match your collab" subtext
    - collab listing chip (role + genre)
  
  List of MatchCards:
    Each card:
      - Creator avatar (CircleAvatar)
      - Username + role title
      - Match score badge (e.g. "92% Match") — primary green color
      - Reason text (1-2 lines, secondary color)
      - Row: [View Profile] [Message] buttons
  
  Empty state:
    - Icon + "No matching creators found right now"
    - "Try again later" subtext
  
  Error state:
    - Error message + Retry button
  
  Loading state:
    - 3x MatchCardShimmer placeholders
```

**Navigation args:**
```dart
// Receives
final String collabId;
final String collabTitle;
```

---

### 4.2 `SongConceptInputScreen`

**Purpose:** Form for creator to describe their song idea.

**UI Structure:**
```
AppBar: "Song Concept Generator"
Body (scrollable):
  Section: Genre
    - Dropdown using existing genre list from platform
  
  Section: Mood
    - Wrap of selectable chips: Melancholic, Energetic, 
      Dark, Uplifting, Chill, Aggressive, Romantic, 
      Mysterious, Nostalgic, Raw
    - Max 3 selectable
  
  Section: Theme Keywords
    - Chip input field (type + press enter to add)
    - Max 5 keywords
    - Shows added chips with remove X
  
  Bottom:
    - "✨ Generate Concept" full-width button
    - Disabled until genre + at least 1 mood selected
```

---

### 4.3 `SongConceptGeneratingScreen`

**Purpose:** Shown while AI is processing. Improves perceived experience.

**UI Structure:**
```
Full screen centered:
  - Animated music note / waveform animation (Lottie or custom)
  - "Generating your concept..." text
  - Subtle "This usually takes a few seconds" subtext
```

---

### 4.4 `SongConceptResultScreen`

**Purpose:** Displays the AI-generated song concept card.

**UI Structure:**
```
AppBar: "Your Song Concept" + Regenerate icon button (top right)
Body (scrollable):
  
  Hero section:
    - Generated title (large, bold)
    - Genre chip + BPM range chip (row)
  
  ConceptSectionTile: "Mood"
    - mood string
  
  ConceptSectionTile: "Themes"
    - theme chips (wrap)
  
  ConceptSectionTile: "Lyrical Direction"
    - lyricalDirection paragraph text
  
  ConceptSectionTile: "Suggested Instruments"
    - instrument chips (wrap)
  
  ConceptSectionTile: "Song Structure"
    - structure string (e.g. "Verse / Pre-Hook / Hook / Bridge / Hook")
  
  ConceptSectionTile: "Sample Hook"
    - sampleHook in italic styled container (card with left border accent)
  
  Bottom action bar:
    - [🔄 Regenerate] outlined button
    - [💬 Send via Message] filled primary button
```

---

### 4.5 `MessageRecipientSheet` (bottom sheet)

**Purpose:** Shown when creator taps "Send via Message" on concept result.

**UI Structure:**
```
Bottom sheet:
  Title: "Send Concept To"
  
  Section: "Suggested — Your Collab Matches"
    - List of matched creators from CollabMatchViewModel cache
    - Each row: avatar + username + role + "Send" button
  
  Divider: "Or search all creators"
  
  Search field → filters all creator users
  
  On tap Send:
    - Formats concept card as structured message text
    - Opens existing ChatScreen with pre-filled message
```

---

## 5. Frontend — ViewModels

### 5.1 `CollabMatchViewModel`

```dart
enum CollabMatchState { idle, loading, loaded, error }

class CollabMatchViewModel extends ChangeNotifier {
  CollabMatchState _state = CollabMatchState.idle;
  List<CollabMatchResult> _matches = [];
  String? _errorMessage;

  CollabMatchState get state => _state;
  List<CollabMatchResult> get matches => _matches;
  String? get errorMessage => _errorMessage;

  // Called from CollabDetailScreen button
  Future<void> fetchMatches(String collabId) async {
    _state = CollabMatchState.loading;
    _matches = [];
    notifyListeners();

    try {
      _matches = await _repository.getMatches(collabId);
      _state = CollabMatchState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _state = CollabMatchState.error;
    }

    notifyListeners();
  }

  void reset() {
    _state = CollabMatchState.idle;
    _matches = [];
    _errorMessage = null;
    notifyListeners();
  }
}
```

**Important:** `_matches` is kept in memory after load so `MessageRecipientSheet` can read it for auto-suggestions. Do not reset until user leaves the collab detail context.

---

### 5.2 `SongConceptViewModel`

```dart
enum SongConceptState { idle, loading, loaded, error }

class SongConceptViewModel extends ChangeNotifier {
  SongConceptState _state = SongConceptState.idle;
  SongConceptModel? _concept;
  String? _errorMessage;

  // Last used inputs (for regenerate)
  String? _lastGenre;
  List<String> _lastMoods = [];
  List<String> _lastThemes = [];

  SongConceptState get state => _state;
  SongConceptModel? get concept => _concept;
  String? get errorMessage => _errorMessage;

  Future<void> generate({
    required String genre,
    required List<String> moods,
    required List<String> themes,
  }) async {
    _lastGenre = genre;
    _lastMoods = moods;
    _lastThemes = themes;

    _state = SongConceptState.loading;
    notifyListeners();

    try {
      _concept = await _repository.generateConcept(
        genre: genre,
        mood: moods.join(", "),
        themes: themes,
      );
      _state = SongConceptState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _state = SongConceptState.error;
    }

    notifyListeners();
  }

  // Regenerate uses last inputs
  Future<void> regenerate() async {
    if (_lastGenre == null) return;
    await generate(
      genre: _lastGenre!,
      moods: _lastMoods,
      themes: _lastThemes,
    );
  }

  void reset() {
    _state = SongConceptState.idle;
    _concept = null;
    _errorMessage = null;
    notifyListeners();
  }
}
```

---

## 6. Frontend — Repositories

### 6.1 `CollabMatchRepository`

```dart
class CollabMatchRepository {
  final ApiClient _api;

  Future<List<CollabMatchResult>> getMatches(String collabId) async {
    final response = await _api.post(
      '/collabs/$collabId/match',
    );
    final List data = response['data'];
    return data.map((e) => CollabMatchResult.fromJson(e)).toList();
  }
}
```

---

### 6.2 `SongConceptRepository`

```dart
class SongConceptRepository {
  final ApiClient _api;

  Future<SongConceptModel> generateConcept({
    required String genre,
    required String mood,
    required List<String> themes,
  }) async {
    final response = await _api.post(
      '/creator/song-concept',
      body: {
        'genre': genre,
        'mood': mood,
        'themes': themes,
      },
    );
    return SongConceptModel.fromJson(response['data']);
  }
}
```

---

## 7. Frontend — Models

### 7.1 `CollabMatchResult`

```dart
class CollabMatchResult {
  final String userId;
  final int matchScore;
  final String reason;
  final MatchedCreatorProfile profile;

  CollabMatchResult.fromJson(Map<String, dynamic> json)
      : userId = json['userId'],
        matchScore = json['matchScore'],
        reason = json['reason'],
        profile = MatchedCreatorProfile.fromJson(json['profile']);
}

class MatchedCreatorProfile {
  final String username;
  final String? avatarUrl;
  final String role;
  final List<String> specializations;

  MatchedCreatorProfile.fromJson(Map<String, dynamic> json)
      : username = json['users']['username'],
        avatarUrl = json['users']['avatar_url'],
        role = json['role'],
        specializations = List<String>.from(json['specializations'] ?? []);
}
```

---

### 7.2 `SongConceptModel`

```dart
class SongConceptModel {
  final String title;
  final String mood;
  final List<String> themes;
  final String lyricalDirection;
  final List<String> suggestedInstruments;
  final String bpmRange;
  final String structure;
  final String sampleHook;

  SongConceptModel.fromJson(Map<String, dynamic> json)
      : title = json['title'],
        mood = json['mood'],
        themes = List<String>.from(json['themes']),
        lyricalDirection = json['lyricalDirection'],
        suggestedInstruments = List<String>.from(json['suggestedInstruments']),
        bpmRange = json['bpmRange'],
        structure = json['structure'],
        sampleHook = json['sampleHook'];
}
```

---

## 8. Backend — File Structure

```
backend/
  src/
    services/
      ai.service.js                    ← NEW (provider-agnostic AI layer)
    
    features/
      collab/
        collab.controller.js           ← MODIFIED (add getCollabMatches handler)
        collab.service.js              ← MODIFIED (add findCollabMatches)
        collab.repository.js           ← MODIFIED (add getCreatorsForMatching)
        collab.routes.js               ← MODIFIED (add match route)
        collab.validator.js            ← no change needed
      
      creator/
        creator.controller.js          ← MODIFIED (add songConcept handler)
        creator.service.js             ← MODIFIED (add createSongConcept)
        creator.routes.js              ← MODIFIED (add song-concept route)
        creator.validator.js           ← MODIFIED (add songConceptSchema)
```

**Only one truly new file:** `ai.service.js`

---

## 9. Backend — AI Service

**`src/services/ai.service.js`**

This is the only file that knows about Gemini. Switching AI providers later means changing only this file.

```javascript
import { GoogleGenerativeAI } from "@google/generative-ai";

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
const model = genAI.getGenerativeModel({ model: "gemini-2.0-flash" });

const parseJsonResponse = (text) => {
  const clean = text.replace(/```json|```/g, "").trim();
  return JSON.parse(clean);
};

// ─── Feature 1: Collab Match ───────────────────────────────────────────────

export const matchCreatorsForCollab = async (collab, creators) => {
  const prompt = `
    You are a music collaboration assistant for a platform called SwapTunes.
    
    A creator posted this collaboration listing:
    - Role needed: ${collab.role}
    - Genre: ${collab.genre}
    - Description: ${collab.description}
    - Mood/Theme: ${collab.mood ?? "not specified"}
    
    Here are active creators available on the platform:
    ${JSON.stringify(creators, null, 2)}
    
    Analyze each creator's specializations, genres, and role against the listing.
    Return the top 5 best matches ranked by compatibility.
    
    Respond with valid JSON only, no extra text, no markdown:
    {
      "matches": [
        {
          "userId": "string",
          "matchScore": 92,
          "reason": "One to two sentence explanation of why they match"
        }
      ]
    }
  `;

  const result = await model.generateContent(prompt);
  return parseJsonResponse(result.response.text());
};

// ─── Feature 2: Song Concept ───────────────────────────────────────────────

export const generateSongConcept = async (genre, mood, themes) => {
  const prompt = `
    You are a creative music assistant for a platform called SwapTunes.
    
    Generate a detailed song concept for a music creator based on:
    - Genre: ${genre}
    - Mood: ${mood}
    - Themes: ${themes.join(", ")}
    
    Be creative, specific, and practical for a real music production context.
    
    Respond with valid JSON only, no extra text, no markdown:
    {
      "title": "Creative song title",
      "mood": "Expanded mood description",
      "themes": ["theme1", "theme2", "theme3"],
      "lyricalDirection": "2-3 sentence description of lyrical approach and narrative",
      "suggestedInstruments": ["instrument1", "instrument2", "instrument3"],
      "bpmRange": "70-85",
      "structure": "Verse / Pre-Hook / Hook / Verse / Bridge / Hook",
      "sampleHook": "A sample hook line that fits the concept"
    }
  `;

  const result = await model.generateContent(prompt);
  return parseJsonResponse(result.response.text());
};
```

**To switch provider later (e.g. Anthropic):**
- Replace the import and client initialization
- Keep `matchCreatorsForCollab` and `generateSongConcept` function signatures identical
- Everything else in the codebase stays the same

---

## 10. Backend — Collab Match

### `collab.repository.js` — add

```javascript
export const getCreatorsForMatching = async (excludeUserId) => {
  const { data, error } = await supabase
    .from("creator_profiles")
    .select(`
      user_id,
      role,
      specializations,
      users (
        username,
        avatar_url,
        bio,
        user_genres ( genre )
      )
    `)
    .neq("user_id", excludeUserId)
    .eq("is_active", true);

  if (error) throw new AppError(error.message, 500);
  return data;
};
```

---

### `collab.service.js` — add

```javascript
export const findCollabMatches = async (collabId, requestingUserId) => {
  // 1. Fetch the collab listing
  const collab = await getCollabById(collabId);
  if (!collab) throw new AppError("Collab not found", 404);

  // 2. Fetch all other active creators
  const creators = await getCreatorsForMatching(requestingUserId);
  if (!creators.length) return [];

  // 3. Send to AI
  const aiResult = await matchCreatorsForCollab(collab, creators);

  // 4. Enrich matches with full profile data
  const enriched = aiResult.matches.map((match) => {
    const creator = creators.find((c) => c.user_id === match.userId);
    return {
      userId: match.userId,
      matchScore: match.matchScore,
      reason: match.reason,
      profile: creator ?? null,
    };
  }).filter((m) => m.profile !== null);

  return enriched;
};
```

---

### `collab.controller.js` — add

```javascript
export const getCollabMatches = async (req, res, next) => {
  try {
    const { collabId } = req.params;
    const userId = req.user.id;
    const matches = await findCollabMatches(collabId, userId);
    res.json({ success: true, data: matches });
  } catch (err) {
    next(err);
  }
};
```

---

## 11. Backend — Song Concept

### `creator.service.js` — add

```javascript
export const createSongConcept = async ({ genre, mood, themes }) => {
  const concept = await generateSongConcept(genre, mood, themes);
  return concept;
};
```

---

### `creator.controller.js` — add

```javascript
export const songConcept = async (req, res, next) => {
  try {
    const { genre, mood, themes } = req.body;
    const concept = await createSongConcept({ genre, mood, themes });
    res.json({ success: true, data: concept });
  } catch (err) {
    next(err);
  }
};
```

---

## 12. Backend — Validation

### `creator.validator.js` — add

```javascript
export const songConceptSchema = z.object({
  genre: z.string().min(1, "Genre is required"),
  mood: z.string().min(1, "Mood is required"),
  themes: z
    .array(z.string().min(1))
    .min(1, "At least one theme is required")
    .max(5, "Maximum 5 themes allowed"),
});
```

No new validation needed for collab match — `collabId` comes from route params and is validated by the existing collab param validator.

---

## 13. Backend — Routes

### `collab.routes.js` — add

```javascript
// POST /api/v1/collabs/:collabId/match
router.post(
  "/:collabId/match",
  requireAuth,
  requireCreator,
  getCollabMatches
);
```

---

### `creator.routes.js` — add

```javascript
// POST /api/v1/creator/song-concept
router.post(
  "/song-concept",
  requireAuth,
  requireCreator,
  validate(songConceptSchema),
  songConcept
);
```

---

## 14. Environment Variables

### `backend/.env` — add

```env
GEMINI_API_KEY=your_gemini_api_key_here
```

### Install new dependency

```bash
cd backend
npm install @google/generative-ai
```

No frontend environment changes needed — AI calls happen entirely on the backend.

---

## 15. Feature Connection — The Full Story

This is the key architectural point for your viva.

Both features are independent but designed to connect:

```
Step 1 — Creator posts a collab listing
Step 2 — Taps "Find Matching Creators"
           → AI Collab Match runs
           → CollabMatchViewModel caches the results in memory

Step 3 — Creator opens Song Concept Generator
           → fills genre/mood/themes
           → AI generates concept card

Step 4 — Creator taps "Send via Message"
           → MessageRecipientSheet opens
           → auto-suggests creators from CollabMatchViewModel cache
           → creator selects recipient
           → concept card is formatted and sent as a message
           → existing ChatScreen opens
```

**The `CollabMatchViewModel` is the bridge.** It is scoped to the creator session and its `_matches` list is read by `MessageRecipientSheet` without a second API call.

This means:
- No redundant API calls
- The two AI features feel like one coherent workflow
- The existing messaging feature becomes the delivery mechanism

---

## 16. Viva Talking Points

### On Architecture
> "The AI provider is abstracted behind a single service file — `ai.service.js`. Switching from Gemini to Anthropic or any other provider requires changing only that file with zero impact on controllers, services, routes, or the Flutter app."

### On Why No Model Training
> "We use retrieval-augmented prompting — live platform data (creator profiles, specializations, genres) is passed as context to the LLM at inference time. This is more practical and maintainable than fine-tuning for this use case, and reflects current industry practice."

### On Feature Design
> "Both AI features are native to the platform — they use data that only exists within SwapTunes. The Collab Match feature cannot exist without our creator profiles and collab listings. The Song Concept Generator connects directly to our messaging feature for delivery. Neither is a generic AI tool bolted on."

### On the Feature Connection
> "The two features share state through the CollabMatchViewModel. When a creator generates a song concept and chooses to send it, the system auto-suggests their already-matched collaborators — eliminating a redundant discovery step and making the workflow feel cohesive."

### On Cost and Scalability
> "At current scale, the Gemini 2.0 Flash model costs approximately $0.001 per request. The provider-agnostic service layer means we can migrate to a cheaper or more capable model as the platform grows without architectural changes."

---

_Document Version: 1.0_  
_Last Updated: April 2026_  
_Project: SwapTunes — AI Features_  
_Features: AI Collab Match + AI Song Concept Generator_
