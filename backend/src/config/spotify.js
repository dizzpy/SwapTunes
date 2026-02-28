import axios from 'axios'
import dotenv from 'dotenv'

dotenv.config()

export const spotifyApi = axios.create({
  baseURL: 'https://api.spotify.com/v1',
})
