# SwapTunes — AI Song Builder

## Feature Replacement Doc

> **Replaces:** AI Song Concept Generator (v1)  
> **Feature name:** AI Song Builder  
> **Role scope:** Creator only  
> **AI Provider:** Google Gemini (via existing `ai.service.js`)  
> **Document Version:** 1.0 — April 2026

---

## Table of Contents

1. [What Changed and Why](#1-what-changed-and-why)
2. [Feature Overview](#2-feature-overview)
3. [User Flows](#3-user-flows)
4. [Frontend — File Changes](#4-frontend--file-changes)
5. [Frontend — Screen Specs](#5-frontend--screen-specs)
6. [Frontend — ViewModel](#6-frontend--viewmodel)
7. [Frontend — Repository](#7-frontend--repository)
8. [Frontend — Models](#8-frontend--models)
9. [Backend — Changes](#9-backend--changes)
10. [Backend — AI Prompt Logic](#10-backend--ai-prompt-logic)
11. [Backend — Validation](#11-backend--validation)
12. [Result Screen UI Spec](#12-result-screen-ui-spec)
13. [Viva Talking Points](#13-viva-talking-points)

---

## 1. What Changed and Why

### Old Feature (Song Concept Generator) — Problems

- Input was too abstract: genre + mood chips + keywords
- Output felt like a document — formal, wordy, not creative
- No connection to the user's actual ideas or existing lyrics
- Output was the same structure regardless of genre
- A creator couldn't actually use it to make music

### New Feature (Song Builder) — What's Different

- User brings their **own raw idea** in free text — any language, any vibe
- User can paste **partial lyrics they already wrote** — AI builds on them
- User selects whether it's **vocal or instrumental**
- AI output **adapts based on genre** — EDM gets a drop map, vocal songs get lyric directions per section, instrumental gets arrangement guidance
- Output is a **creative brief**, not a report — punchy, actionable, inspiring

---

## 2. Feature Overview

The AI Song Builder takes a creator's raw idea — a sentence, a feeling, a half-written verse — and turns it into a complete, actionable song plan.

**Inputs:**

- Free text idea (required) — any language, any length
- Genre (required) — dropdown
- Partial lyrics (optional) — multiline text field
- Type: Vocal or Instrumental (required)

**Output adapts by genre and type:**

| Input type                    | What AI focuses on                                    |
| ----------------------------- | ----------------------------------------------------- |
| Vocal song, no lyrics         | Full structure + what to write in each section        |
| Vocal song, partial lyrics    | Fits user lyrics into structure + completes the rest  |
| EDM / Electronic instrumental | Drop map with timestamps + sound design direction     |
| Other instrumental            | Arrangement breakdown + instrument roles              |
| Sinhala / local genre         | Writes section directions in Sinhala cultural context |

**Entry points:** Collab Tab (top area) + Creator Profile tab (same as before)

---

## 3. User Flows

### 3.1 Flow A — Raw Idea Only (Vocal)

```
Creator taps "Song Builder"
  → SongBuilderInputScreen
    → types: "Smoky garage song about the language I dream in"
    → selects genre: Hip Hop
    → leaves lyrics field empty
    → selects: Vocal
    → taps "Build My Song"
      → SongBuilderViewModel.build()
        → POST /api/v1/creator/song-builder
          → loading → SongBuilderLoadingScreen
            → success → SongBuilderResultScreen
              → title, BPM, key, structure with per-section directions
              → instruments list
              → [Regenerate] [Send via Message]
            → error → inline error with retry
```

---

### 3.2 Flow B — User Has Partial Lyrics

```
Creator taps "Song Builder"
  → SongBuilderInputScreen
    → types idea: "About feeling invisible at a party"
    → pastes lyrics:
        "Everyone's laughing but I'm watching from the wall
         They call my name but I don't feel it at all"
    → selects genre: R&B
    → selects: Vocal
    → taps "Build My Song"
      → AI detects lyrics → fits them as Verse 1
        → returns completed structure:
            Verse 1: user's lyrics (shown as-is)
            Hook: AI suggested hook
            Verse 2: direction for what to write
            Bridge: direction for the turning point
      → SongBuilderResultScreen shows
          "Your lyrics → Verse 1" clearly labelled
```

---

### 3.3 Flow C — EDM Instrumental

```
Creator taps "Song Builder"
  → types: "Dark underground rave, feels like 3am tunnel"
  → selects genre: EDM
  → selects: Instrumental
  → taps "Build My Song"
    → AI returns drop map:
        0:00 Intro — minimal kick, atmospheric synth
        0:30 Buildup 1 — filter sweep, rising tension
        1:00 DROP 1 — distorted bass, full kick in
        1:30 Breakdown — pads only, melodic moment
        2:00 Buildup 2 — harder than buildup 1
        2:20 DROP 2 — extra layer, peak energy
        3:00 Outro — gradual fade
    → Sounds needed section
    → BPM + Key
```

---

### 3.4 Flow D — Sinhala Song

```
Creator taps "Song Builder"
  → types: "හිතේ තිබෙන දේ කියන්න බෑ වගේ feeling"
  → selects genre: Sinhala Pop
  → selects: Vocal
  → taps "Build My Song"
    → AI returns structure with section directions
      written in Sinhala cultural and lyrical context
    → Instruments appropriate for Sinhala pop
    → Hook direction in Sinhala feel
```

---

### 3.5 Send via Message Flow (unchanged from v1)

```
SongBuilderResultScreen
  → taps "Send via Message"
    → MessageRecipientSheet opens
      → auto-suggests matched creators from CollabMatchViewModel cache
      → user selects recipient
      → song plan formatted as message
      → opens existing ChatScreen
```

---

## 4. Frontend — File Changes

### Files to DELETE (old feature)

```
mobile/lib/features/creator/screens/
  song_concept_input_screen.dart        ← DELETE
  song_concept_result_screen.dart       ← DELETE
  song_concept_generating_screen.dart   ← DELETE

mobile/lib/features/creator/viewmodels/
  song_concept_viewmodel.dart           ← DELETE

mobile/lib/features/creator/repositories/
  song_concept_repository.dart          ← DELETE

mobile/lib/features/creator/models/
  song_concept_model.dart               ← DELETE

mobile/lib/features/creator/widgets/
  concept_card.dart                     ← DELETE
  concept_section_tile.dart             ← DELETE
```

### Files to CREATE (new feature)

```
mobile/lib/features/creator/screens/
  song_builder_input_screen.dart        ← NEW
  song_builder_result_screen.dart       ← NEW
  song_builder_loading_screen.dart      ← NEW

mobile/lib/features/creator/viewmodels/
  song_builder_viewmodel.dart           ← NEW

mobile/lib/features/creator/repositories/
  song_builder_repository.dart          ← NEW

mobile/lib/features/creator/models/
  song_builder_model.dart               ← NEW

mobile/lib/features/creator/widgets/
  song_section_card.dart                ← NEW
  drop_map_card.dart                    ← NEW (EDM only)
  instrument_chip_row.dart              ← NEW
```

### Files to MODIFY

| File                           | Change                                                       |
| ------------------------------ | ------------------------------------------------------------ |
| `app_router.dart`              | Replace old song concept routes with new song builder routes |
| `collab_tab.dart`              | Update entry point button label to "Song Builder"            |
| `creator_profile_tab.dart`     | Update entry point button label to "Song Builder"            |
| `message_recipient_sheet.dart` | No change — reuse as-is                                      |

---

## 5. Frontend — Screen Specs

### 5.1 `SongBuilderInputScreen`

**AppBar:** "Song Builder"

**Body (scrollable, comfortable padding):**

```
── Header banner ──────────────────────────────
  Icon: ✨ (sparkle)
  Title: "Build your song"
  Subtitle: "Describe your idea and AI will create
             a complete song plan for you"
  Style: subtle tinted container, primary green tint

── Section: Your Idea ─────────────────────────
  Label: "What's your idea?"
  Input: multiline TextField
    placeholder: "e.g. Smoky garage song about the
                  language I dream in..."
    minLines: 3, maxLines: 6
    maxLength: 300
  Note: "Any language works — Sinhala, English, anything"

── Section: Genre ──────────────────────────────
  Label: "Genre"
  Input: Dropdown
    Options: Hip Hop, R&B, Pop, Rock, EDM, Electronic,
             Trap, Afrobeats, Jazz, Classical, Reggae,
             Sinhala Pop, Sinhala Baila, Other
  Note: EDM/Electronic unlocks drop map output

── Section: Got lyrics? ────────────────────────
  Label: "Got some lyrics already? (optional)"
  Input: multiline TextField
    placeholder: "Paste what you have so far...
                  AI will build the rest around it"
    minLines: 3, maxLines: 8
    maxLength: 500

── Section: Type ───────────────────────────────
  Label: "Type"
  Input: segmented toggle row
    [🎤 Vocal]   [🎹 Instrumental]
  Style: selected = filled primary green,
         unselected = outlined

── Bottom ──────────────────────────────────────
  Button: "✨ Build My Song"
  Full width, primary green
  Disabled state: when idea field is empty or genre not selected
```

---

### 5.2 `SongBuilderLoadingScreen`

**Purpose:** Shown while AI is processing. Full screen, replaces the old generating screen.

```
Full screen, dark background:

  Center column:
    - Animated waveform or pulsing music note
      (simple custom animation, no heavy library needed)
    - Text: "Building your song plan..."
    - Subtext: "This usually takes a few seconds"

  Style: match app dark theme, primary green accent on animation
```

---

### 5.3 `SongBuilderResultScreen`

**AppBar:**

- Title: song title returned by AI (dynamic)
- Leading: back button
- Actions: refresh/regenerate icon button (top right)

**Body (scrollable):**

```
── Hero section ────────────────────────────────
  Row:
    - Genre chip (e.g. "Hip Hop")
    - BPM chip (e.g. "78 BPM")
    - Key chip (e.g. "C Minor")
  Style: small outlined chips, secondary color

── Sample Hook / Hook Line ─────────────────────
  (shown only for vocal songs)
  Container with left green border accent:
    Italic text: the hook line AI generated
  Style: subtle background tint, green left border 4px
  This is the FIRST content section — most emotional, shown early

── Song Structure ──────────────────────────────
  Label: "SONG STRUCTURE"  (small caps, secondary color)

  FOR VOCAL SONGS:
    List of SongSectionCards:
      Each card shows:
        - Section name (VERSE 1, HOOK, BRIDGE etc)
        - If this section uses USER'S LYRICS:
            Green "Your lyrics" badge
            User's lyrics in slightly tinted block
        - Direction text: what to write / feel for this section
        - Timestamp suggestion if available (e.g. "0:15 →")

  FOR EDM/ELECTRONIC INSTRUMENTAL:
    DropMapCard:
      Timeline style layout:
        Each row: timestamp | section name | description
        DROP sections highlighted with green accent
        e.g.
          0:00  Intro       minimal kick, atmospheric synth
          0:30  Buildup 1   filter sweep rising
          1:00  DROP 1 🔥   distorted bass hits, full kick
          1:30  Breakdown   pads only, melodic moment
          2:20  DROP 2 🔥🔥  heavier mix, extra layer
          3:00  Outro       gradual fade

  FOR OTHER INSTRUMENTAL:
    List of SongSectionCards (same as vocal but no lyric fields)
    Focus on dynamics, arrangement notes per section

── Instruments ─────────────────────────────────
  Label: "INSTRUMENTS"
  InstrumentChipRow:
    Wrap of chips — short instrument names only
    e.g. "808s" "Warm bass" "Lo-fi drums" "Piano"

── Vibe / Mood ──────────────────────────────────
  Label: "VIBE"
  Single line text — short, punchy mood description
  e.g. "Dusty, introspective, late night energy"

── Bottom action bar ───────────────────────────
  Row:
    [🔄 Regenerate]       outlined button, half width
    [💬 Send via Message] filled primary button, half width
```

---

## 6. Frontend — ViewModel

### `SongBuilderViewModel`

```dart
enum SongBuilderState { idle, loading, loaded, error }

class SongBuilderViewModel extends ChangeNotifier {
  SongBuilderState _state = SongBuilderState.idle;
  SongBuilderResult? _result;
  String? _errorMessage;

  // Store last inputs for regenerate
  String? _lastIdea;
  String? _lastGenre;
  String? _lastLyrics;
  String? _lastType; // 'vocal' or 'instrumental'

  SongBuilderState get state => _state;
  SongBuilderResult? get result => _result;
  String? get errorMessage => _errorMessage;

  Future<void> build({
    required String idea,
    required String genre,
    String? lyrics,
    required String type,
  }) async {
    _lastIdea = idea;
    _lastGenre = genre;
    _lastLyrics = lyrics;
    _lastType = type;

    _state = SongBuilderState.loading;
    notifyListeners();

    try {
      _result = await _repository.buildSong(
        idea: idea,
        genre: genre,
        lyrics: lyrics,
        type: type,
      );
      _state = SongBuilderState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _state = SongBuilderState.error;
    }

    notifyListeners();
  }

  Future<void> regenerate() async {
    if (_lastIdea == null) return;
    await build(
      idea: _lastIdea!,
      genre: _lastGenre!,
      lyrics: _lastLyrics,
      type: _lastType!,
    );
  }

  void reset() {
    _state = SongBuilderState.idle;
    _result = null;
    _errorMessage = null;
    notifyListeners();
  }
}
```

---

## 7. Frontend — Repository

### `SongBuilderRepository`

```dart
class SongBuilderRepository {
  final ApiClient _api;

  Future<SongBuilderResult> buildSong({
    required String idea,
    required String genre,
    String? lyrics,
    required String type,
  }) async {
    final response = await _api.post(
      '/creator/song-builder',
      body: {
        'idea': idea,
        'genre': genre,
        if (lyrics != null && lyrics.isNotEmpty) 'lyrics': lyrics,
        'type': type,
      },
    );
    return SongBuilderResult.fromJson(response['data']);
  }
}
```

---

## 8. Frontend — Models

### `SongBuilderResult`

```dart
class SongBuilderResult {
  final String title;
  final String vibe;
  final String bpm;
  final String key;
  final String genre;
  final String type;           // 'vocal' or 'instrumental'
  final String? sampleHook;    // null for instrumental
  final List<SongSection> sections;
  final List<String> instruments;
  final bool hasUserLyrics;    // true if user provided partial lyrics

  SongBuilderResult.fromJson(Map<String, dynamic> json)
      : title = json['title'],
        vibe = json['vibe'],
        bpm = json['bpm'],
        key = json['key'],
        genre = json['genre'],
        type = json['type'],
        sampleHook = json['sampleHook'],
        sections = (json['sections'] as List)
            .map((s) => SongSection.fromJson(s))
            .toList(),
        instruments = List<String>.from(json['instruments']),
        hasUserLyrics = json['hasUserLyrics'] ?? false;
}

class SongSection {
  final String name;           // e.g. "Verse 1", "DROP 1", "Hook"
  final String? timestamp;     // e.g. "1:00" — EDM only
  final String direction;      // what to write / feel / do here
  final String? userLyrics;    // populated if user's lyrics fit here
  final bool isUserLyrics;     // true = this section uses user's text
  final bool isDrop;           // true = highlight as drop (EDM)

  SongSection.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        timestamp = json['timestamp'],
        direction = json['direction'],
        userLyrics = json['userLyrics'],
        isUserLyrics = json['isUserLyrics'] ?? false,
        isDrop = json['isDrop'] ?? false;
}
```

---

## 9. Backend — Changes

### File to MODIFY: `creator.service.js`

- Remove `createSongConcept`
- Add `buildSong`

### File to MODIFY: `creator.controller.js`

- Remove `songConcept` handler
- Add `songBuilder` handler

### File to MODIFY: `creator.routes.js`

- Remove `POST /song-concept`
- Add `POST /song-builder`

### File to MODIFY: `creator.validator.js`

- Remove `songConceptSchema`
- Add `songBuilderSchema`

### File to MODIFY: `ai.service.js`

- Remove `generateSongConcept`
- Add `buildSongPlan` (with adaptive prompt logic by genre + type)

---

## 10. Backend — AI Prompt Logic

### `ai.service.js` — replace `generateSongConcept` with:

```javascript
export const buildSongPlan = async ({ idea, genre, lyrics, type }) => {
  const isEDM = ["EDM", "Electronic"].includes(genre);
  const isInstrumental = type === "instrumental";
  const hasLyrics = lyrics && lyrics.trim().length > 0;

  let prompt;

  if (isEDM && isInstrumental) {
    // EDM Drop Map prompt
    prompt = `
You are a professional music producer assistant on SwapTunes.

A creator wants to make an EDM track with this idea:
"${idea}"

Genre: ${genre}
Type: Instrumental

Create a complete EDM production plan.

Respond with valid JSON only, no markdown:
{
  "title": "Creative track title",
  "vibe": "Short punchy vibe description (max 8 words)",
  "bpm": "138",
  "key": "A Minor",
  "genre": "${genre}",
  "type": "instrumental",
  "sampleHook": null,
  "hasUserLyrics": false,
  "sections": [
    {
      "name": "Intro",
      "timestamp": "0:00",
      "direction": "What sounds and energy happen here",
      "userLyrics": null,
      "isUserLyrics": false,
      "isDrop": false
    },
    {
      "name": "Buildup 1",
      "timestamp": "0:30",
      "direction": "Filter sweep, rising tension, snare rolls at 0:50",
      "userLyrics": null,
      "isUserLyrics": false,
      "isDrop": false
    },
    {
      "name": "DROP 1",
      "timestamp": "1:00",
      "direction": "Full energy hits — describe the main drop elements",
      "userLyrics": null,
      "isUserLyrics": false,
      "isDrop": true
    }
  ],
  "instruments": ["808 kick", "Supersaw lead", "White noise sweep", "Atmospheric pad"]
}

Include: Intro, Buildup 1, Drop 1, Breakdown, Buildup 2, Drop 2, Outro.
Mark all drop sections with isDrop: true.
Keep directions short and production-practical (1-2 sentences each).
    `.trim();
  } else if (isInstrumental) {
    // Non-EDM instrumental prompt
    prompt = `
You are a professional music producer assistant on SwapTunes.

A creator wants to make an instrumental track:
"${idea}"

Genre: ${genre}
Type: Instrumental

Create a complete arrangement plan.

Respond with valid JSON only, no markdown:
{
  "title": "Creative track title",
  "vibe": "Short punchy vibe (max 8 words)",
  "bpm": "90",
  "key": "D Major",
  "genre": "${genre}",
  "type": "instrumental",
  "sampleHook": null,
  "hasUserLyrics": false,
  "sections": [
    {
      "name": "Intro",
      "timestamp": "0:00",
      "direction": "What instruments enter, what's the energy",
      "userLyrics": null,
      "isUserLyrics": false,
      "isDrop": false
    }
  ],
  "instruments": ["instrument1", "instrument2", "instrument3"]
}

Include 5-7 sections. Focus on dynamics, instrument roles, and emotional arc.
    `.trim();
  } else if (hasLyrics) {
    // Vocal with partial lyrics
    prompt = `
You are a professional songwriting assistant on SwapTunes.

A creator has a song idea and some lyrics they've already written:

Idea: "${idea}"
Genre: ${genre}
Their lyrics so far:
"""
${lyrics}
"""

Your job:
1. Identify where their lyrics best fit in the song structure (most likely Verse 1)
2. Build a complete song structure around them
3. Suggest what to write for the remaining sections
4. Generate a strong hook/chorus if they haven't written one

Respond with valid JSON only, no markdown:
{
  "title": "Suggested song title",
  "vibe": "Short punchy vibe (max 8 words)",
  "bpm": "90",
  "key": "C Minor",
  "genre": "${genre}",
  "type": "vocal",
  "sampleHook": "A strong hook line for the chorus",
  "hasUserLyrics": true,
  "sections": [
    {
      "name": "Verse 1",
      "timestamp": null,
      "direction": "Sets the scene — personal and specific",
      "userLyrics": "paste the user lyrics here exactly as they wrote",
      "isUserLyrics": true,
      "isDrop": false
    },
    {
      "name": "Hook",
      "timestamp": null,
      "direction": "The emotional core — most memorable moment",
      "userLyrics": null,
      "isUserLyrics": false,
      "isDrop": false
    }
  ],
  "instruments": ["instrument1", "instrument2", "instrument3"]
}

Include 5-7 sections. Keep directions inspiring and practical (1-2 sentences each).
Only one section should have isUserLyrics: true.
    `.trim();
  } else {
    // Vocal, no lyrics
    prompt = `
You are a professional songwriting assistant on SwapTunes.

A creator has this song idea:
"${idea}"

Genre: ${genre}
Type: Vocal song

Create a complete song writing plan — structure, what to write in each section, hook suggestion.

Respond with valid JSON only, no markdown:
{
  "title": "Suggested song title",
  "vibe": "Short punchy vibe (max 8 words)",
  "bpm": "85",
  "key": "A Minor",
  "genre": "${genre}",
  "type": "vocal",
  "sampleHook": "A strong hook/chorus line",
  "hasUserLyrics": false,
  "sections": [
    {
      "name": "Verse 1",
      "timestamp": null,
      "direction": "What to write here — specific, inspiring, 1-2 sentences",
      "userLyrics": null,
      "isUserLyrics": false,
      "isDrop": false
    }
  ],
  "instruments": ["instrument1", "instrument2", "instrument3"]
}

Include 5-7 sections (Verse 1, Pre-Hook, Hook, Verse 2, Bridge, Hook, Outro).
Make directions feel like a creative brief, not a report.
Keep each direction short, punchy and inspiring.
    `.trim();
  }

  try {
    const result = await model.generateContent(prompt);
    return parseJsonResponse(result.response.text());
  } catch (err) {
    if (err.statusCode) throw err;
    const msg = err.message ?? "";
    if (msg.includes("429") || msg.includes("quota")) {
      throw {
        statusCode: 429,
        code: "AI_QUOTA_EXCEEDED",
        message:
          "AI is temporarily unavailable due to rate limits. Please try again in a few minutes.",
      };
    }
    throw {
      statusCode: 502,
      code: "AI_BUILD_FAILED",
      message: "Song Builder is currently unavailable. Please try again.",
    };
  }
};
```

---

## 11. Backend — Validation

### `creator.validator.js` — replace `songConceptSchema` with:

```javascript
export const songBuilderSchema = z.object({
  idea: z.string().min(5, "Please describe your idea").max(300),
  genre: z.string().min(1, "Genre is required"),
  lyrics: z.string().max(500).optional(),
  type: z.enum(["vocal", "instrumental"], {
    required_error: "Please select vocal or instrumental",
  }),
});
```

### `creator.controller.js`

```javascript
export const songBuilder = async (req, res, next) => {
  try {
    const { idea, genre, lyrics, type } = req.body;
    const result = await buildSong({ idea, genre, lyrics, type });
    res.json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
};
```

### `creator.service.js`

```javascript
export const buildSong = async ({ idea, genre, lyrics, type }) => {
  return await buildSongPlan({ idea, genre, lyrics, type });
};
```

### `creator.routes.js`

```javascript
// Remove:
// router.post('/song-concept', ...)

// Add:
router.post(
  "/song-builder",
  requireAuth,
  requireCreator,
  validate(songBuilderSchema),
  songBuilder,
);
```

---

## 12. Result Screen UI Spec

### Design Principles

- **Hook line first** — the most emotionally powerful thing at the top
- **Short labels, big content** — section names small caps, content readable
- **User lyrics clearly marked** — green badge so creator sees their work respected
- **EDM drop map feels like a timeline** — not a list, a visual sequence
- **Chips for instruments** — scannable at a glance, not a wall of text
- **Two actions only** — Regenerate + Send via Message, nothing else

### Color Usage (existing design system)

- Primary green `#10b981` → active chips, drop highlights, left border accents, badges
- Section labels → secondary text color (existing)
- User lyrics block → subtle green tint background
- Drop sections → green left border + slightly brighter text
- Instrument chips → outlined, secondary color

### Typography

- Song title → largest text, bold, Manrope
- Section names → small caps, secondary, letter-spaced
- Direction text → body size, primary text color, readable line height
- Hook line → italic, slightly larger than body
- Timestamps → monospace or slightly muted, EDM only

---

## 13. Viva Talking Points

### On Replacing the Old Feature

> "The original Song Concept Generator was too abstract — it produced a document, not a creative tool. We replaced it with the Song Builder which takes the creator's own idea or existing lyrics as input and returns an actionable plan they can actually use to make music."

### On Adaptive Output

> "The AI output adapts based on genre and type. An EDM track returns a timestamp-based drop map. A vocal song with partial lyrics receives a structure where their existing work is placed and completed. This is not a one-size-fits-all generator — it responds to what the creator brings."

### On the Lyrics Completion Flow

> "When a creator pastes partial lyrics, the AI identifies where they fit in the song structure and builds the rest around them. This is a genuine creative collaboration — the platform meets the creator where they are."

### On Sinhala Support

> "Because the input is free text and the AI prompt instructs it to respect the cultural context of the genre, Sinhala language input works naturally. A creator can type their idea in Sinhala, select a Sinhala genre, and receive section directions appropriate to Sinhala songwriting conventions."

### On the Connection to Collab Match

> "The Song Builder connects to the AI Collab Match feature. After building a song plan, the creator can send it via message — and the platform auto-suggests their already-matched collaborators as recipients. The song idea reaches the right person without the creator having to search for them."

---

_Document Version: 1.0_  
_Last Updated: April 2026_  
_Project: SwapTunes — AI Song Builder_  
_Replaces: AI Song Concept Generator v1_
