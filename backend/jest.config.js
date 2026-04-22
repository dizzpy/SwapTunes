export default {
  testEnvironment: 'node',
  transform: {},
  testMatch: ['**/tests/**/*.test.js'],
  reporters: ['default', './tests/helpers/stream-reporter.cjs'],
  collectCoverageFrom: ['src/**/*.js', '!src/server.js', '!src/app.js'],
  coverageThreshold: {
    global: {
      lines: 50,
      functions: 50,
      branches: 50,
      statements: 50
    }
  }
}
