# Card ribbon wallpaper design

## Goal

Make each identity card feel like an Apple-style wallpaper: broad pastel ribbons
flow across the card, with visible card-to-card variation through direction,
width, and crossing height. The result remains a deterministic representation of
the same profile input.

## Chosen direction

Adopt the selected B direction at its widest demonstrated variation: two broad
diagonal ribbons may run in opposing directions and cross within the card. The
visual is a liquid color field, not a stripe graphic. It contains no texture,
noise, image asset, or animation beyond the existing user-triggered stir.

## Rendering model

`CardVisual(seed:)` remains the sole seed-to-visual boundary.

1. Generate the existing four adjacent-hue anchors using the current ranges.
2. Generate deterministic ribbon parameters from the same `SplitMix64` stream:
   two diagonal directions, widths, center offsets, and crossing height.
3. For every fixed 5×5 control point, combine the existing corner-anchor blend
   with the two ribbon weights. A ribbon weight is a smooth falloff from its
   diagonal centerline; the two weights are normalized with the base blend so
   no point can become a hard band or a color discontinuity.
4. Apply the existing ink-contrast correction to each resulting control point.
5. Keep the same `controlPoints` for CardView, CardBackView, previews, and the
   Gyeop moment dominant color.

## Invariants

- Mesh dimension stays 5×5 and every card has exactly 25 control points.
- Hue remains in 0...1; hue anchors retain their current adjacent sweep.
- Saturation and brightness retain the F56 ranges and contrast ceiling.
- Every generated control point meets at least 4.5:1 contrast against the
  fixed ink color.
- Same seed produces equal `CardVisual`; different seeds yield at least two
  distinct ribbon parameter sets across the fixed test sample.
- No DesignSystem token, app navigation, card size, or animation timing changes.

## Error prevention and verification

The implementation adds unit coverage for deterministic ribbon parameters,
four-way variation across known seeds, 5×5 control-point count, 100-seed pastel
range and contrast checks, and preview-to-generated-card equality. It then runs
the required iPhone 17 Pro build, package suite, and screenshot accessibility
flow; exported screenshots are reviewed at card reveal, received-card grid,
detail, and card-back states. This reduces regression risk but does not claim
that a visual rendering change can guarantee the absence of every future issue.

## Non-goals

- No new palette token, font, texture, blur asset, or card layout change.
- No passive looping motion or new animation.
- No App Clip or TestFlight release configuration change in this design pass.
