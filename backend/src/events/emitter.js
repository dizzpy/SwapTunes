import { EventEmitter } from 'events'
import { logger } from '../utils/logger.js'

class AppEmitter extends EventEmitter {}

export const emitter = new AppEmitter()

// Optional: Log all emitted events in development
if (process.env.NODE_ENV !== 'production') {
  const originalEmit = emitter.emit
  emitter.emit = function (eventName, ...args) {
    logger.debug({ eventName, args }, 'Event emitted')
    return originalEmit.apply(this, [eventName, ...args])
  }
}
