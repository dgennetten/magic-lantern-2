# Modular Projection Lantern Generator

![Sun illustration](Screensjot.jpg)
A parametric OpenSCAD project for generating 3D-printable projection lanterns. This generator calculates the precise extrusion angles required to cast undistorted 2D patterns, shapes, and text onto a floor or surface from an elevated point light source.

## Features

* **Parametric LED Mounting:** Easily adjust variables to friction-fit any standard LED puck or light fixture.
* **Distortion-Corrected Projection:** Uses dynamic scaling to ensure patterns projecting further out maintain their intended visual proportions.
* **Multiple Render Modes**: 
  * `PATTERNS`: Generates a fully customizable array of text, geometric shapes, and rays.
  * `SVG`: Extrudes a custom vector file.
  * `CAL`: Generates a 360-degree dot spiral to test projection accuracy at different radii.
* **Integrated Mounting Tabs:** Includes base tabs for securing the lantern to a ceiling or mounting bracket.

## Prerequisites

1. **OpenSCAD:** Download the latest version from [openscad.org](https://openscad.org/). For best results, download the Nightly Build version, not the 'current' 2021 version.
2. **Allerta Stencil Font:** The `PATTERNS` mode relies on this specific font to ensure physical text cutouts don't result in floating, unprintable islands. 
   * Download the `AllertaStencil-Regular.ttf` file and place it in the same directory as `magicLantern.scad`.
   * *Note: The script references the logical font name `"Allerta Stencil"`. Ensure it is properly installed on your system or placed in the local working directory.*

## Quick Start Guide

### 1. Configure Your Light Source
Open `magicLantern.scad` and locate the **Global Lantern Parameters** and **LED Mounting Parameters**. Measure your specific LED fixture and update the following:
* `light_height`: The distance from the bottom of the lantern to the actual light-emitting diode.
* `led_diameter`: The outer diameter of your physical LED fixture.
* `led_recess`: How far down inside the top cylinder the LED sits.
* `tolerance`: Adjust the clearance (default `0.25`) for a snug friction fit.

### 2. Choose Your Render Mode
Locate the `render_mode` variable and set it to one of the following strings:

* `"PATTERNS"`: Uses the built-in geometric and text modules.
* `"SVG"`: Extrudes a custom 2D vector file. Make sure to update `svg_filename`, `svg_scale`, and the offset coordinates.
* `"CAL"`: Creates a shortened test lantern with a spiral of dots to verify your light height and projection focus.

### 3. Customize Patterns (Optional)
If using `PATTERNS` mode, scroll down to the `all_2d_patterns()` module. You can mix and match the included projection functions. The vertical placement of each cut is driven by the `distance` parameter—a smaller number places the cutout closer to the light source, projecting it further out onto the floor.

**Pattern Module Parameters:**

**Universal Parameters**
* **`distance`** *(Required)*: Determines the vertical placement of the pattern cut.
* **`phase_shift`** *(Optional, default: 0)*: Applies a rotational offset to the entire pattern ring. Useful for staggering elements between rows.

**`project_text()`**
* **`msg`** *(Required)*: The string of text to project.
* **`t_size`** *(Optional, default: 8)*: The physical font size of the characters on the cylinder.
* **`kerning_deg`** *(Optional, default: 12)*: The degrees of rotation between each individual character.
* **`f_name`** *(Optional, default: font_name)*: Overrides the global font choice for a specific text ring.

**`project_polygon()`**
* **`vertex`** *(Required)*: The number of sides for the shape (e.g., `4` for squares/diamonds).
* **`rot`** *(Optional, default: 0)*: Applies a clockwise rotational offset to the individual shapes.
* **`n`** *(Optional, default: 24)*: The total number of repeating shapes around the 360-degree ring.
* **`duty`** *(Optional, default: 0.5)*: A ratio between 0.0 and 1.0 that dictates how much of the angular step the shape occupies.

**`project_circles()`**
* **`n`** *(Required)*: The total number of repeating circles around the cylinder.
* **`duty`** *(Optional, default: 0.5)*: Controls the diameter of the circles relative to their horizontal spacing.

**`project_rays()`**
* **`bar_h`** *(Required)*: The physical vertical height of the ray cutout on the cylinder wall. 
* **`n`** *(Required)*: The total number of repeating rays.
* **`duty`** *(Optional, default: 0.5)*: Controls the width of the ray cutouts relative to the solid wall spacing.

### 4. Preview and Export
1. Press **F5** to preview your design.
2. *Important:* Ensure `show_light_rays = false;` before exporting, or the visualization rays will be added to your printable mesh!
3. Press **F6** to render the final geometry.
4. Go to **File > Export > Export as STL** (or 3MF).

## Slicing & Printing Recommendations

* **Resolution:** The script is set to `$fn = 120` for smooth cylindrical curves. OrcaSlicer handles this high-resolution mesh perfectly and allows for excellent seam painting to hide the Z-seam along one of the mounting tabs.
* **Material:** Standard PLA is great for initial test prints or the `CAL` mode calibration ring. However, if your LED fixture generates noticeable heat, printing the final lantern in PETG is highly recommended to prevent warping over time.
* **Hardware:** Tested successfully on enclosed Core-XY machines like the FlashForge AD5X.
* **Orientation:** Print the lantern vertically (LED cavity pointing up). No supports are required for the standard pattern cutouts.
