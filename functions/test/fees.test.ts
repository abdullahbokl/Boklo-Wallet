import { computeFeeMinor, getFeeSchedule } from "../src/fees";
import * as admin from "firebase-admin";

jest.mock("firebase-admin", () => ({
  remoteConfig: jest.fn(),
  firestore: Object.assign(jest.fn(), {
    FieldValue: { serverTimestamp: jest.fn() },
  }),
}));

describe("computeFeeMinor", () => {
  it("returns zero when the schedule is disabled (0 bps)", () => {
    expect(computeFeeMinor(100_000, 0, 0)).toBe(0);
  });

  it("applies basis points, rounding half-up to whole minor units", () => {
    // 150 bps = 1.5% of 100000 = 1500
    expect(computeFeeMinor(100_000, 150, 0)).toBe(1500);
    // 1.5% of 12345 = 185.175 -> rounds to 185
    expect(computeFeeMinor(12_345, 150, 0)).toBe(185);
    // 1.5% of 12350 = 185.25 -> rounds to 185
    expect(computeFeeMinor(12_350, 150, 0)).toBe(185);
    // 1.5% of 12367 = 185.505 -> rounds to 186
    expect(computeFeeMinor(12_367, 150, 0)).toBe(186);
  });

  it("always waives the fee at or below the free threshold", () => {
    expect(computeFeeMinor(500, 150, 500)).toBe(0);
    expect(computeFeeMinor(499, 150, 500)).toBe(0);
    expect(computeFeeMinor(501, 150, 500)).toBe(8);
  });
});

describe("getFeeSchedule", () => {
  it("falls back to defaults when Remote Config has no params", async () => {
    (admin.remoteConfig as jest.Mock).mockReturnValue({
      getTemplate: async () => ({ parameters: {} }),
    });
    const schedule = await getFeeSchedule();
    expect(schedule).toEqual({ feeBps: 0, freeBelowMinor: 0 });
  });

  it("reads configured values from Remote Config", async () => {
    (admin.remoteConfig as jest.Mock).mockReturnValue({
      getTemplate: async () => ({
        parameters: {
          transfer_fee_bps: { defaultValue: { value: "250" } },
          transfer_fee_free_below_minor: {
            defaultValue: { value: "10000" },
          },
        },
      }),
    });
    const schedule = await getFeeSchedule();
    expect(schedule).toEqual({ feeBps: 250, freeBelowMinor: 10000 });
  });

  it("falls back to defaults when Remote Config fails", async () => {
    (admin.remoteConfig as jest.Mock).mockReturnValue({
      getTemplate: async () => {
        throw new Error("rc down");
      },
    });
    const schedule = await getFeeSchedule();
    expect(schedule).toEqual({ feeBps: 0, freeBelowMinor: 0 });
  });
});
