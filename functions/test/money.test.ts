import {
  currenciesAreCompatible,
  formatMajor,
  hasMinorUnitsFlag,
  toMinorUnits,
} from "../src/utils/money";

describe("toMinorUnits", () => {
  it("converts major to minor units", () => {
    expect(toMinorUnits(10.5)).toBe(1050);
    expect(toMinorUnits(0.1 + 0.2)).toBe(30); // rounding kills float drift
    expect(toMinorUnits(0)).toBe(0);
  });
});

describe("formatMajor", () => {
  it("renders minor units as fixed-2 major strings", () => {
    expect(formatMajor(105050)).toBe("1050.50");
    expect(formatMajor(5)).toBe("0.05");
    expect(formatMajor(0)).toBe("0.00");
  });
});

describe("hasMinorUnitsFlag", () => {
  it("requires an explicit true marker", () => {
    expect(hasMinorUnitsFlag({ minorUnits: true })).toBe(true);
    expect(hasMinorUnitsFlag({})).toBe(false);
    expect(hasMinorUnitsFlag(undefined)).toBe(false);
  });
});

describe("currenciesAreCompatible", () => {
  it("accepts identical non-empty currencies", () => {
    expect(currenciesAreCompatible("EGP", "EGP", "EGP")).toBe(true);
  });
  it("rejects mismatches and empty transfer currency", () => {
    expect(currenciesAreCompatible("USD", "EGP", "EGP")).toBe(false);
    expect(currenciesAreCompatible("", "EGP", "EGP")).toBe(false);
    expect(currenciesAreCompatible(undefined, "EGP", "EGP")).toBe(false);
    expect(currenciesAreCompatible("EGP", "EGP", "USD")).toBe(false);
  });
});
