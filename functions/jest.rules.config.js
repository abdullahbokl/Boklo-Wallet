/** @type {import('jest').Config} */
// Dedicated config for the Firestore rules tests (run via `npm run
// test:rules` inside the emulator); excluded from the default jest run.
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  testMatch: ['**/test/firestore.rules.test.ts'],
};
