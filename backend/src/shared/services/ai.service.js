import { GoogleGenerativeAI } from '@google/generative-ai'

const parseJsonResponse = (text) => {
  const clean = text.replace(/```json|```/g, '').trim()
  return JSON.parse(clean)
}

const getModel = () => {
  if (!process.env.GEMINI_API_KEY) {
    throw { statusCode: 503, code: 'AI_NOT_CONFIGURED', message: 'AI service is not configured. Set GEMINI_API_KEY.' }
  }
  const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY)
  return genAI.getGenerativeModel({ model: 'gemini-3-flash-preview' })
}

// ─── Feature: Collab Match ─────────────────────────────────────────────────

export const matchCreatorsForCollab = async (collab, creators) => {
  const model = getModel()

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
    const result = await model.generateContent(prompt)
    return parseJsonResponse(result.response.text())
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
