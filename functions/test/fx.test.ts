import { convertMinorWithRate, fxRateDocId } from "../src/fx";

jest.mock("firebase-admin", () => ({
  firestore: jest.fn(),
}));

describe("convertMinorWithRate", () => {
  it("converts with an exact rational rate (integer math only)", () => {
    // 1000 EGP minor (10.00 EGP) at 1 EGP = 32.5 USD minor -> 32500
    expect(convertMinorWithRate(1000, 325, 10)).toBe(32500);
  });

  it("rounds half-up to whole minor units", () => {
    // 1 * 5 / 2 = 2.5 -> 3
    expect(convertMinorWithRate(1, 5, 2)).toBe(3);
    // 1 * 7 / 2 = 3.5 -> 4
    expect(convertMinorWithRate(1, 7, 2)).toBe(4);
    // 3 * 1 / 2 = 1.5 -> 2
    expect(convertMinorWithRate(3, 1, 2)).toBe(2);
  });

  it("rounds down below the half threshold", () => {
    // 3 * 2 / 3 = 2.0
    expect(convertMinorWithRate(3, 2, 3)).toBe(2);
    // 1 * 1 / 3 = 0.333 -> 0
    expect(convertMinorWithRate(1, 1, 3)).toBe(0);
  });

  it("rejects invalid rates and amounts", () => {
    expect(() => convertMinorWithRate(100, 1, 0)).toThrow();
    expect(() => convertMinorWithRate(-1, 1, 2)).toThrow();
    expect(() => convertMinorWithRate(1.5, 1, 2)).toThrow();
  });
});

describe("fxRateDocId", () => {
  it("uppercases and pairs base/quote", () => {
    expect(fxRateDocId("egp", "usd")).toBe("EGP_USD");
  });
});
