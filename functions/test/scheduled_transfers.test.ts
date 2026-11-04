import { nextRunAfter } from "../src/scheduled_transfers";

jest.mock("firebase-admin", () => ({
  firestore: jest.fn(),
}));

describe("nextRunAfter", () => {
  it("advances daily by one UTC day", () => {
    const from = new Date("2026-01-15T09:00:00Z");
    expect(nextRunAfter(from, "daily").toISOString()).toBe(
      "2026-01-16T09:00:00.000Z",
    );
  });

  it("advances weekly by seven UTC days", () => {
    const from = new Date("2026-01-15T09:00:00Z");
    expect(nextRunAfter(from, "weekly").toISOString()).toBe(
      "2026-01-22T09:00:00.000Z",
    );
  });

  it("advances monthly across short months without drift", () => {
    // Jan 31 + 1 month must clamp to Feb 28 (2026 is not a leap year).
    const from = new Date("2026-01-31T12:00:00Z");
    expect(nextRunAfter(from, "monthly").toISOString()).toBe(
      "2026-02-28T12:00:00.000Z",
    );
  });

  it("advances monthly across a normal month boundary", () => {
    const from = new Date("2026-03-15T08:00:00Z");
    expect(nextRunAfter(from, "monthly").toISOString()).toBe(
      "2026-04-15T08:00:00.000Z",
    );
  });
});
