/** @type {import('jest').Config} */
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  testMatch: ['**/test/**/*.test.ts'],
  // rules tests need the firestore emulator; run via `npm run test:rules`
  testPathIgnorePatterns: ['/node_modules/', 'test/firestore.rules.test.ts'],
};
