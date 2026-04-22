import { jest } from '@jest/globals'

const generateContentMock = jest.fn()
const getGenerativeModelMock = jest.fn(() => ({
  generateContent: generateContentMock
}))

const GoogleGenerativeAIMock = jest.fn(() => ({
  getGenerativeModel: getGenerativeModelMock
}))

jest.unstable_mockModule('@google/generative-ai', () => ({
  GoogleGenerativeAI: GoogleGenerativeAIMock
}))

const aiService = await import('../../../src/shared/services/ai.service.js')

describe('ai service', () => {
  const originalKey = process.env.GEMINI_API_KEY

  beforeEach(() => {
    jest.clearAllMocks()
    process.env.GEMINI_API_KEY = 'test-key'
  })

  afterAll(() => {
    process.env.GEMINI_API_KEY = originalKey
  })

  test('matchCreatorsForCollab returns parsed JSON matches', async () => {
    generateContentMock.mockResolvedValueOnce({
      response: {
        text: () => JSON.stringify({ matches: [{ userId: 'u1', matchScore: 90, reason: 'great fit' }] })
      }
    })

    const result = await aiService.matchCreatorsForCollab(
      {
        title: 'Need singer',
        looking_for: ['vocalist'],
        genre_style: ['rock'],
        description: 'collab'
      },
      [{ user_id: 'u1' }]
    )

    expect(result.matches).toHaveLength(1)
    expect(GoogleGenerativeAIMock).toHaveBeenCalledWith('test-key')
    expect(getGenerativeModelMock).toHaveBeenCalledWith({ model: 'gemini-3-flash-preview' })
  })

  test('buildSongPlan throws AI_NOT_CONFIGURED without key', async () => {
    delete process.env.GEMINI_API_KEY

    await expect(
      aiService.buildSongPlan({ idea: 'song idea', genre: 'EDM', type: 'instrumental' })
    ).rejects.toMatchObject({
      code: 'AI_NOT_CONFIGURED'
    })
  })

  test('buildSongPlan maps quota errors to AI_QUOTA_EXCEEDED', async () => {
    generateContentMock.mockRejectedValueOnce(new Error('429 Too Many Requests'))

    await expect(
      aiService.buildSongPlan({ idea: 'song idea', genre: 'Rock', lyrics: '', type: 'vocal' })
    ).rejects.toMatchObject({ code: 'AI_QUOTA_EXCEEDED' })
  })
})
