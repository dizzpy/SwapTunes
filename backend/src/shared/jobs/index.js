import { startSpotifyTokenRefreshJob } from './spotify-token-refresh.job.js'
import { logger } from '../utils/logger.js'

export const initializeJobs = () => {
  startSpotifyTokenRefreshJob()

  logger.info('⏰ Background jobs initialized')
}
