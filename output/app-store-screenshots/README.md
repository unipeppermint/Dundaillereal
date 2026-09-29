# Dice Workshop — App Store screenshots

Created on 2026-09-22. English marketing copy with the six user-provided screenshots, preserved as real app imagery and proportionally resized inside a decorative frame. No app UI text, scores, or game states have been fabricated.

## Upload

Upload the six PNG files in `en-US/iphone-6.9/`, in filename order, to the English iPhone 6.9-inch screenshot set in App Store Connect. Each image is 1260 × 2736 pixels, opaque RGB PNG. `overview.png` is for review only; do not upload it. The ZIP contains only the six final screenshots.

Apple's dimensions reference, checked 2026-09-22:
https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications

These are static screenshots. An App Preview is a separate video asset and is not included. Files have not been uploaded to App Store Connect.

## Order

1. Discover — Small games. Big moments.
2. Roll — Roll the dice. Find your stop.
3. Together — Your turn. Then theirs.
4. Rules — A little game. Ready to go.
5. Create — Your idea. Your rules.
6. Collection — Keep the games you love.

The Workshop and Collection screenshots intentionally retain their supplied empty states.

## Editable source

`render.swift` uses native AppKit to lay out precise text and the real screenshots. Run from the repository root:

```sh
swift -module-cache-path /tmp/dice-marketing-swift-cache output/app-store-screenshots/render.swift
```

The original screenshots are in `design-assets/screenshots/`. Decorative dice are in `design-assets/dice-variations.png`, created using the built-in imagegen tool (not the fallback CLI). Only decorative artwork was generated; app screenshots were not regenerated.

## Final artwork prompt

Create an illustration asset sheet for a refined cozy tabletop dice game's App Store marketing. Transparent background PNG. Six separate isolated small still-life groups in a precisely spaced 2-column by 3-row grid, equal sized cells, NO overlapping across cells, generous blank margins in every cell. All six groups have soft painterly watercolor-meets-clay style, warm ivory rounded six-sided dice with correct dark navy circular pips and subtle realistic soft shading, accents coral orange and sage green. Top left: two ivory dice, one upright front five and another tilted front three, small sage leaf. Top right: one tumbling ivory die front six and a smaller coral die front two, playful varying rotation. Middle left: two ivory dice front four and front one with a curving tiny sage ribbon. Middle right: an ivory die front three beside a coral die front five, one small sprig. Bottom left: three small dice stacked loosely, ivory sage and coral, believable gravity, varied dots. Bottom right: two ivory dice front two and six with one little four-leaf clover. Each group large readable coherent three dimensional shapes. Consistent soft studio lighting, editorial board-game illustration. No lettering, no numbers, no logos, no frames, no backdrop, no phones, no shadows extending beyond each cell. Transparent background. Wide asset sheet aspect 2:3.

## Validation

- All six exports checked: 1260 × 2736, no alpha channel.
- Reviewed the full set together and the gameplay slide at large scale for text, borders and image placement.
- No application source, icon, launch image or publishing settings changed for this task.
