import qs from 'qs'
import { env } from '../config/env.js'
import { spotifyApi } from '../config/spotify.js'
import axios from 'axios'
import { supabase } from '../config/supabase.js'

export const getSpotifyTokens = async (code, redirect_uri) => {
  const response = await axios.post(
    'https://accounts.spotify.com/api/token',
    qs.stringify({
      grant_type: 'authorization_code',
      code,
      redirect_uri
    }),
    {
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        Authorization: `Basic ${Buffer.from(`${env.SPOTIFY_CLIENT_ID}:${env.SPOTIFY_CLIENT_SECRET}`).toString(
          'base64'
        )}`
      }
    }
  )

  return response.data
}

export const refreshSpotifyToken = async (userId, refreshToken) => {
  try {
    const response = await axios.post(
      'https://accounts.spotify.com/api/token',
      qs.stringify({
        grant_type: 'refresh_token',
        refresh_token: refreshToken
      }),
      {
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          Authorization: `Basic ${Buffer.from(`${env.SPOTIFY_CLIENT_ID}:${env.SPOTIFY_CLIENT_SECRET}`).toString(
            'base64'
          )}`
        }
      }
    )

    const newAccessToken = response.data.access_token

    // Update the DB
    await supabase.from('users').update({ spotify_access_token: newAccessToken }).eq('id', userId)

    return newAccessToken
  } catch (error) {
    console.error(`Failed to refresh Spotify token for user ${userId}`, error.response?.data || error.message)
    throw error
  }
}

export const getValidAccessToken = async (user) => {
  // Simplification: In a production app you'd store the token expiry timestamp.
  // Here we just try to use the access token; if it fails, we try to refresh it.

  if (!user.spotify_access_token) {
    throw new Error('No Spotify access token available')
  }

  // To be perfectly robust, you should check expiry logic here, but for brevity:
  // we will just return it, and let the calling service catch a 401 and refresh.
  return user.spotify_access_token
}

export const fetchSpotifyPlaylists = async (accessToken) => {
  const { data } = await spotifyApi.get('/me/playlists', {
    headers: { Authorization: `Bearer ${accessToken}` },
    params: { limit: 50 }
  })

  return data.items
}
