module.exports = {
  testEnvironment: 'jsdom',
  testMatch: ['<rootDir>/test/javascript/**/*.test.ts?(x)'],
  transform: { '^.+\\.[tj]sx?$': 'babel-jest' },
  setupFilesAfterEnv: ['<rootDir>/test/javascript/setup.ts'],
  moduleNameMapper: { '\\.(css)$': '<rootDir>/test/javascript/style_mock.cjs' },
}