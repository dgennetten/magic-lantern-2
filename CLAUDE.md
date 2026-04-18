# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A parametric OpenSCAD project that generates 3D-printable projection lanterns. The lantern casts undistorted 2D patterns (text, shapes, rays) onto a floor from an elevated point light source. Mathematical distortion correction is the core challenge: since light projects from a point, shapes must be pre-distorted on the cylinder wall so they appear undistorted on the floor.

## Workflow (no build system)

This is a CAD project — there are no compile/test/lint commands. The workflow is:
1. Edit a `.scad` file
2. **F5** in OpenSCAD to preview
3. Set `show_light_rays = false` before exporting
4. **F6** to full render, then **File → Export** as `.stl` or `.3mf`

Requires: OpenSCAD (nightly build recommended) + `AllertaStencil-Regular.ttf` in the same folder as the `.scad` file.

## File Selection

| File | When to use |
|------|-------------|
| `magicLantern2.scad` | **Start here.** Data-driven `pattern_spec` list; easiest to customize |
| `magicLantern.scad` | Original; edit `all_2d_patterns()` module directly |
| `magicLanternJadeJulian.scad` | Named variant of the original style |

## Architecture

### Core Math

`get_floor_r(distance)` is the projection formula used everywhere (numerator is `projection_led_height()`, equal to `light_height` when `light_height_is_to_rim` is false):
```
floor_radius = (projection_led_height * cyl_radius) / distance
```
`distance` is the vertical position of a cut on the cylinder wall (measured from the top/LED). Smaller distance = higher on wall = projects **farther** from center on the floor. This similar-triangles calculation is what makes the projection geometrically correct.

### Pattern Pipeline (`magicLantern2.scad`)

1. **`pattern_spec`** — a list of `layer_*()` calls (the customization point)
2. **`apply_pattern_entry()`** — dispatches each list entry to the correct `project_*` module
3. **`project_text/rays/circles/polygon()`** — 2D modules that use `get_floor_r()` to compute scaled shapes at the correct height
4. **`linear_extrude()` with `scale`** — pulls 2D cuts upward from floor plane to the cylinder wall, tapering to avoid singularity at the light source
5. **`lantern_body()`** — unions pattern cutouts with the cylinder shell and mounting tabs

### Render Modes

Controlled by `render_mode` variable:
- `"PATTERNS"` — normal use; applies the full pattern stack
- `"SVG"` — extrudes an external vector file (`svg_filename`)
- `"CAL"` — shorter cylinder + calibration dot spiral to test projection accuracy

### Key Parameters

```
light_height           — floor (z=0) reference height; default mode: floor → LED (drives projection). See light_height_is_to_rim
light_height_is_to_rim — false: rim = light_height + led_recess. true: light_height is floor → rim; projection uses light_height - led_recess
cyl_radius             — outer radius of cylinder
wall_thickness         — shell thickness
led_diameter           — friction-fit bore for LED puck
led_recess             — pocket depth from rim toward LED
tolerance              — dimensional tolerance for fit
$fn                    — smoothness (120 for print-ready)
show_light_rays        — set false before STL export
```

### Adding New Pattern Primitives

1. Create a `project_newtype()` 2D module using `get_floor_r()` for sizing
2. Add a `layer_newtype()` function that returns a tagged list (match the `["type", ...]` convention)
3. Handle the new tag in `apply_pattern_entry()`
4. Add entries to `pattern_spec`

### `phase_shift` Semantics

- For `rays`, `circles`, `polygon`: rotates by `phase_shift × (360/n)` degrees
- For `text`: rotates by `phase_shift × kerning_deg` degrees
