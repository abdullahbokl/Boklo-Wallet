# Responsive Layout Guidelines

This document outlines the rules and best practices for building responsive and adaptive UIs in the Boklo application.

## 1. The Golden Rule: Use `ResponsiveBuilder`

All screen-level widgets or complex components that change layout based on device type **MUST** use the `ResponsiveBuilder` widget.

**Why?**

- It centralization breakpoint logic (Mobile < 600, Tablet < 900, Desktop >= 900).
- It provides a typed `ScreenInfo` object with useful getters (`isMobile`, `isTablet`).
- It handles orientation changes automatically.

### Example

```dart
@override
Widget build(BuildContext context) {
  return ResponsiveBuilder(
    mobile: (context, screenInfo) => MobileLayout(),
    tablet: (context, screenInfo) => TabletLayout(), // Optional fallback to mobile
    desktop: (context, screenInfo) => DesktopLayout(), // Optional fallback to tablet -> mobile
  );
}
```

## 2. No `MediaQuery` for Layout Logic

**Avoid** using `MediaQuery.of(context).size` directly within your widgets to determine layout.

**Why?**

- It makes widgets harder to test.
- It couples widgets to the valid screen size, not their parent constraints.
- It duplicates breakpoint logic scattered across the app.

**Exception**: You may use `MediaQuery` for determining keyboard visibility (`viewInsets`) or specific overlay calculations that must be screen-relative.

**Alternative**: Use `LayoutBuilder` or the `ScreenInfo` passed by `ResponsiveBuilder`.

## 3. No Hardcoded Dimensions

**Do not** use hardcoded pixel values for container sizes that should be fluid.

- **Bad**: `width: 375` (Assumes a specific mobile screen width).
- **Good**: `width: double.infinity`, `Flexible`, `Expanded`, or `FractionallySizedBox`.

## 4. Adaptive Layout Patterns

### Mobile (Width < 600)

- Single column layout.
- Bottom Navigation Bar.
- Full-screen dialogs or sheets.
- Drawer for extra navigation.

### Tablet (600 <= Width < 900)

- Two-column layouts where appropriate (e.g., List/Detail).
- Navigation Rail instead of Bottom Nav.
- Dialogs should be centered and sized appropriately (not full screen).

### Desktop (Width >= 900)

- Multi-column layouts (Grid, Masonry).
- Permanent side navigation (Drawer or Rail).
- Use tooltips and hover effects.
- Modals should be strictly sized popups.

## 5. Testing

- Always test your layout by resizing the window (on desktop/web) or rotating the device (on mobile).
- Ensure logical fallbacks exist (e.g., if you don't define a tablet layout, does the mobile layout look acceptable?).
