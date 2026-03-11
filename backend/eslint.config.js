export default [
  {
    ignores: ['node_modules/', 'dist/', 'coverage/']
  },
  {
    files: ['src/**/*.js', 'server.js'],
    languageOptions: {
      ecmaVersion: 'latest',
      sourceType: 'module',
      globals: {
        process: 'readonly',
        console: 'readonly'
      }
    },
    rules: {
      'no-unused-vars': ['warn', { argsIgnorePattern: '^_' }],
      'no-console': ['warn', { allow: ['warn', 'error'] }],
      'eqeqeq': 'error'
    }
  }
]
