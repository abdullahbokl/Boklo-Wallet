import { strict as assert } from "node:assert";
import { describe, it } from "node:test";
import {
  currenciesAreCompatible,
  formatMajor,
  hasMinorUnitsFlag,
  toMinorUnits,
} from "../src/utils/money";

describe("toMinorUnits", () => {
  it("converts major to minor units", () => {
    assert.equal(toMinorUnits(10.5), 1050);
    assert.equal(toMinorUnits(0.1 + 0.2), 30); // rounding kills float drift
    assert.equal(toMinorUnits(0), 0);
  });
});

describe("formatMajor", () => {
  it("renders minor units as fixed-2 major strings", () => {
    assert.equal(formatMajor(105050), "1050.50");
    assert.equal(formatMajor(5), "0.05");
    assert.equal(formatMajor(0), "0.00");
  });
});

describe("hasMinorUnitsFlag", () => {
  it("requires an explicit true marker", () => {
    assert.equal(hasMinorUnitsFlag({ minorUnits: true }), true);
    assert.equal(hasMinorUnitsFlag({}), false);
    assert.equal(hasMinorUnitsFlag(undefined), false);
  });
});

describe("currenciesAreCompatible", () => {
  it("accepts identical non-empty currencies", () => {
    assert.equal(currenciesAreCompatible("EGP", "EGP", "EGP"), true);
  });
  it("rejects mismatches and empty transfer currency", () => {
    assert.equal(currenciesAreCompatible("USD", "EGP", "EGP"), false);
    assert.equal(currenciesAreCompatible("", "EGP", "EGP"), false);
    assert.equal(currenciesAreCompatible(undefined, "EGP", "EGP"), false);
    assert.equal(currenciesAreCompatible("EGP", "EGP", "USD"), false);
  });
});
