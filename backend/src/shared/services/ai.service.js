import { GoogleGenerativeAI } from '@google/generative-ai'
// `fetch` is available globally in Node 18+; no extra import needed.

const MODEL = 'gemini-3-flash-preview'

const parseJsonResponse = (text) => {
  const clean = text.replace(/```json|```/g, '').trim()
  return JSON.parse(clean)
}

// Ordered, de-duplicated, non-empty list of keys to try.
// Priority: env primary → env backup → manual app override (last resort).
const getApiKeys = (overrideKey) => {
  const candidates = [
    { label: 'env-primary', key: process.env.GEMINI_API_KEY },
    { label: 'env-backup', key: process.env.GEMINI_API_KEY_BACKUP_ONE },
    { label: 'app-manual', key: overrideKey }
  ]
  const seen = new Set()
  return candidates.filter(({ key }) => {
    if (!key || typeof key !== 'string' || key.trim().length === 0) return false
    if (seen.has(key)) return false
    seen.add(key)
    return true
  })
}

const isKeyFailure = (err) => {
  const msg = err?.message ?? ''
  return (
    msg.includes('429') ||
    msg.includes('Too Many Requests') ||
    msg.includes('quota') ||
    msg.includes('403') ||
    msg.includes('API_KEY') ||
    msg.includes('invalid')
  )
}

// Tries each available key until one succeeds. If a key fails with a
// rate-limit / auth-style error, falls through to the next one. Any other
// error short-circuits and is rethrown immediately.
const generateContentWithFallback = async (prompt, overrideKey) => {
  const keys = getApiKeys(overrideKey)
  if (keys.length === 0) {
    throw { statusCode: 503, code: 'AI_NOT_CONFIGURED', message: 'AI service is not configured. Set GEMINI_API_KEY.' }
  }

  let lastErr
  for (const { label, key } of keys) {
    try {
      const genAI = new GoogleGenerativeAI(key)
      const model = genAI.getGenerativeModel({ model: MODEL })
      const result = await model.generateContent(prompt)
      return { text: result.response.text(), keyUsed: label }
    } catch (err) {
      lastErr = err
      if (!isKeyFailure(err)) throw err
    }
  }
  throw lastErr
}

// Lightweight per-key probe used by GET /health/ai.
// Uses a models-list GET — validates the key without generating any content,
// so it costs zero generation credits.
export const checkGeminiKeys = async (overrideKey) => {
  const keys = getApiKeys(overrideKey)
  if (keys.length === 0) return []

  return Promise.all(
    keys.map(async ({ label, key }) => {
      try {
        const res = await fetch(
          `https://generativelanguage.googleapis.com/v1beta/models?key=${key}&pageSize=1`
        )
        if (!res.ok) {
          const body = await res.json().catch(() => ({}))
          const msg = body?.error?.message ?? `HTTP ${res.status}`
          return { label, ok: false, error: msg }
        }
        return { label, ok: true }
      } catch (err) {
        return { label, ok: false, error: err?.message ?? 'unknown error' }
      }
    })
  )
}

// ─── Feature: Collab Match ─────────────────────────────────────────────────

export const matchCreatorsForCollab = async (collab, creators, overrideKey) => {
  const prompt = `
You are a music collaboration assistant for a platform called SwapTunes.

A creator posted this collaboration listing:
- Title: ${collab.title}
- Roles needed: ${collab.looking_for.join(', ')}
- Genres: ${(collab.genre_style ?? []).join(', ')}
- Description: ${collab.description}

Here are active creators available on the platform:
${JSON.stringify(creators, null, 2)}

Analyze each creator's specializations, role_title, and description context against the listing.
Return the top 5 best matches ranked by compatibility score.

Respond with valid JSON only, no extra text, no markdown:
{
  "matches": [
    {
      "userId": "string (the user_id field from the creator data)",
      "matchScore": 92,
      "reason": "One to two sentence explanation of why they match"
    }
  ]
}
  `.trim()

  try {
    const { text } = await generateContentWithFallback(prompt, overrideKey)
    return parseJsonResponse(text)
  } catch (err) {
    if (err.statusCode) throw err
    const msg = err.message ?? ''
    if (msg.includes('429') || msg.includes('Too Many Requests') || msg.includes('quota')) {
      throw {
        statusCode: 429,
        code: 'AI_QUOTA_EXCEEDED',
        message: 'AI matching is temporarily unavailable due to rate limits. Please try again in a few minutes.'
      }
    }
    if (msg.includes('403') || msg.includes('API_KEY') || msg.includes('invalid')) {
      throw {
        statusCode: 503,
        code: 'AI_NOT_CONFIGURED',
        message: 'AI service is not properly configured. Contact support.'
      }
    }
    throw {
      statusCode: 502,
      code: 'AI_MATCH_FAILED',
      message: 'AI matching is currently unavailable. Please try again.'
    }
  }
}

// ─── Feature: AI Song Builder ──────────────────────────────────────────────

export const buildSongPlan = async ({ idea, genre, lyrics, type }, overrideKey) => {
  const isEDM = ['EDM', 'Electronic'].includes(genre)
  const isInstrumental = type === 'instrumental'
  const hasLyrics = lyrics && lyrics.trim().length > 0

  let prompt

  if (isEDM && isInstrumental) {
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
    { "name": "Intro", "timestamp": "0:00", "direction": "What sounds and energy happen here", "userLyrics": null, "isUserLyrics": false, "isDrop": false },
    { "name": "Buildup 1", "timestamp": "0:30", "direction": "Filter sweep, rising tension, snare rolls at 0:50", "userLyrics": null, "isUserLyrics": false, "isDrop": false },
    { "name": "DROP 1", "timestamp": "1:00", "direction": "Full energy hits — describe the main drop elements", "userLyrics": null, "isUserLyrics": false, "isDrop": true }
  ],
  "instruments": ["808 kick", "Supersaw lead", "White noise sweep", "Atmospheric pad"]
}

Include: Intro, Buildup 1, Drop 1, Breakdown, Buildup 2, Drop 2, Outro.
Mark all drop sections with isDrop: true.
Keep directions short and production-practical (1-2 sentences each).
    `.trim()
  } else if (isInstrumental) {
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
    { "name": "Intro", "timestamp": "0:00", "direction": "What instruments enter, what's the energy", "userLyrics": null, "isUserLyrics": false, "isDrop": false }
  ],
  "instruments": ["instrument1", "instrument2", "instrument3"]
}

Include 5-7 sections. Focus on dynamics, instrument roles, and emotional arc.
Always set isDrop: false for every section — isDrop is only for EDM tracks.
    `.trim()
  } else if (hasLyrics) {
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
    { "name": "Verse 1", "timestamp": null, "direction": "Sets the scene — personal and specific", "userLyrics": "paste the user lyrics here exactly as they wrote", "isUserLyrics": true, "isDrop": false },
    { "name": "Hook", "timestamp": null, "direction": "The emotional core — most memorable moment", "userLyrics": null, "isUserLyrics": false, "isDrop": false }
  ],
  "instruments": ["instrument1", "instrument2", "instrument3"]
}

Include 5-7 sections. Keep directions inspiring and practical (1-2 sentences each).
Only one section should have isUserLyrics: true.
Always set isDrop: false for every section — isDrop is only used in EDM tracks.
    `.trim()
  } else {
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
    { "name": "Verse 1", "timestamp": null, "direction": "What to write here — specific, inspiring, 1-2 sentences", "userLyrics": null, "isUserLyrics": false, "isDrop": false }
  ],
  "instruments": ["instrument1", "instrument2", "instrument3"]
}

Include 5-7 sections (Verse 1, Pre-Hook, Hook, Verse 2, Bridge, Hook, Outro).
Make directions feel like a creative brief, not a report.
Keep each direction short, punchy and inspiring.
Always set isDrop: false for every section — isDrop is only used in EDM tracks.
    `.trim()
  }

  try {
    const { text } = await generateContentWithFallback(prompt, overrideKey)
    return parseJsonResponse(text)
  } catch (err) {
    if (err.statusCode) throw err
    const msg = err.message ?? ''
    if (msg.includes('429') || msg.includes('Too Many Requests') || msg.includes('quota')) {
      throw {
        statusCode: 429,
        code: 'AI_QUOTA_EXCEEDED',
        message: 'AI is temporarily unavailable due to rate limits. Please try again in a few minutes.'
      }
    }
    if (msg.includes('403') || msg.includes('API_KEY') || msg.includes('invalid')) {
      throw {
        statusCode: 503,
        code: 'AI_NOT_CONFIGURED',
        message: 'AI service is not properly configured. Contact support.'
      }
    }
    throw {
      statusCode: 502,
      code: 'AI_BUILD_FAILED',
      message: 'Song Builder is currently unavailable. Please try again.'
    }
  }
}
