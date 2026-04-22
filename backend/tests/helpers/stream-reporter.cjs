/**
 * Minimal Jest reporter that streams per-test pass/fail lines to stdout.
 * Written as CommonJS (.cjs) so Jest can load it in ESM projects.
 */
class StreamReporter {
  constructor(_globalConfig, _options, _context) {}

  onTestResult(_test, testResult) {
    for (const r of testResult.testResults) {
      const icon = r.status === 'passed' ? '✓' : '✗'
      process.stdout.write(`  ${icon} ${r.fullName}\n`)
    }
  }

  onRunComplete() {}
}

module.exports = StreamReporter
