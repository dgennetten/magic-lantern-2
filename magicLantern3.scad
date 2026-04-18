// ==========================================
// Modular projection lantern — data-first layout
// Compose cutout layers in pattern_spec (top of file, after a short helper block).
// ==========================================

// ---------------------------------------------------------------------------
// 1. Lantern & LED (physical)
// ---------------------------------------------------------------------------
// LED / shell (inch → mm): inner Ø 2.4"; LED emit plane 0.95" below outside rim.
inch = 25.4;
led_inner_d_in = 2.4;        // required inner Ø (LED friction bore = main shell inner Ø)
led_depth_from_rim_in = 0.95;   // rim → LED; pattern taper ends at `extrude_tip_clearance_mm` below LED plane

light_height = 60;           // See `light_height_is_to_rim` below (floor → LED emit plane)
wall_thickness = 2;
cyl_radius = (led_inner_d_in * inch) / 2 + wall_thickness;   // inner Ø = led_inner_d_in × inch
font_name = "Boston Traffic";
use <boston_traffic.ttf>;
//font_name = "Allerta Stencil";
//use <AllertaStencil-Regular.ttf>;
$fn = 120;

led_diameter = led_inner_d_in * inch;
led_recess = led_depth_from_rim_in * inch;   // pocket depth (rim → LED emit plane)
tolerance = 0.25;
// Wall cutouts / taper end this far below the LED plane (stay under the lid / recess zone).
extrude_tip_clearance_mm = 5;

// How `light_height` is measured (floor at z = 0):
// - false (default): floor → LED emit plane. Rim height = light_height + led_recess. Recess only sizes the lid.
// - true: floor → outside rim. LED emit plane = light_height - led_recess (recess enters projection math).
light_height_is_to_rim = false;

function projection_led_height() = light_height_is_to_rim ? (light_height - led_recess) : light_height;
function lantern_rim_height() = light_height_is_to_rim ? light_height : (light_height + led_recess);

// Mount style: "tabs" (two interior screw tabs) or "flange" (full disc, 1" centre hole)
mount_style = "flange";

// ---------------------------------------------------------------------------
// 2. What to render on the floor plane
//    "PATTERNS" → pattern_spec  |  "SVG" → import  |  "CAL" → calibration spiral
// ---------------------------------------------------------------------------
render_mode = "PATTERNS";
svg_filename = "my_pattern.svg";
svg_scale = 1.0;
svg_x_offset = 0;
svg_y_offset = 0;

// ---------------------------------------------------------------------------
// 3. Declarative layer builders (needed before pattern_spec in OpenSCAD)
// ---------------------------------------------------------------------------
function layer_text(distance, msg, t_size = 8, kerning_deg = 12, phase_shift = 0, location = "top") =
    ["text", distance, msg, t_size, kerning_deg, phase_shift, location];

function layer_rays(distance, bar_h, n, duty = 0.5, phase_shift = 0, count = 0) =
    ["rays", distance, bar_h, n, duty, phase_shift, count];

function layer_circles(distance, n, duty = 0.5, phase_shift = 0, count = 0) =
    ["circles", distance, n, duty, phase_shift, count];

function layer_polygon(distance, vertex, rot = 0, n = 24, duty = 0.5, phase_shift = 0, count = 0) =
    ["polygon", distance, vertex, rot, n, duty, phase_shift, count];

// ---------------------------------------------------------------------------
// 4. Pattern stack — main customization: reorder or edit entries here
// ---------------------------------------------------------------------------
_ray_bar_w = (2 * PI * cyl_radius / 24) * 0.5;

pattern_spec = [
        layer_text(24, "BREATHE THE AIR", t_size = 22, kerning_deg = 13, location = "top", phase_shift=-7),
 
    layer_circles(38, n = 20, duty = 0.65, count = 11),
    layer_rays(12, bar_h = _ray_bar_w * 3.0, n = 20, duty = 0.65, count = 11),
    layer_circles(6, n = 20, duty = 0.65, count = 11),
];

// ---------------------------------------------------------------------------
// 5. Preview
// ---------------------------------------------------------------------------
show_light_rays = true;   // set false for F6 export

// ---------------------------------------------------------------------------
// 6. Projection math & 2D primitives
// ---------------------------------------------------------------------------
function get_floor_r(distance) = (projection_led_height() * cyl_radius) / distance;

module project_text(distance, msg, t_size = 8, kerning_deg = 12, f_name = font_name, phase_shift = 0, location = "top") {
    floor_r = get_floor_r(distance);
    chars = len(msg);
    total_angle = (chars - 1) * kerning_deg;
    start_angle = total_angle / 2;
    bottom = (location == "bottom");
    center_angle = bottom ? 180 : 0;
    angle_offset = kerning_deg * phase_shift;
    for (i = [0 : chars - 1]) {
        a = bottom
            ? (center_angle - start_angle + i * kerning_deg + angle_offset)
            : (center_angle + start_angle - i * kerning_deg + angle_offset);
        rotate(a)
            translate([0, floor_r])
                rotate(bottom ? 180 : 0)
                    text(msg[i], size = t_size, font = f_name, halign = "center", valign = "center");
    }
}

module project_rays(distance, bar_h, n, duty = 0.5, phase_shift = 0, count = 0) {
    dist_top = distance - (bar_h / 2);
    dist_bottom = distance + (bar_h / 2);
    r_outer = get_floor_r(dist_top);
    r_inner = get_floor_r(dist_bottom);
    angle_step = 360 / n;
    wedge_angle = angle_step * duty;
    angle_offset = angle_step * phase_shift;
    actual_count = (count > 0 && count <= n) ? count : n;
    rot_sign = (count > 0) ? -1 : 1;
    for (i = [0 : actual_count - 1]) {
        rotate(rot_sign * i * angle_step + angle_offset)
            polygon([
                [ r_inner * tan(wedge_angle / 2), r_inner ],
                [ r_outer * tan(wedge_angle / 2), r_outer ],
                [-r_outer * tan(wedge_angle / 2), r_outer ],
                [-r_inner * tan(wedge_angle / 2), r_inner ]
            ]);
    }
}

module project_circles(distance, n, duty = 0.5, phase_shift = 0, count = 0) {
    floor_r = get_floor_r(distance);
    angle_step = 360 / n;
    c_r = floor_r * sin((angle_step * duty) / 2);
    angle_offset = angle_step * phase_shift;
    actual_count = (count > 0 && count <= n) ? count : n;
    rot_sign = (count > 0) ? -1 : 1;
    for (i = [0 : actual_count - 1]) {
        rotate(rot_sign * i * angle_step + angle_offset)
            translate([0, floor_r])
                circle(r = c_r);
    }
}

module project_polygon(distance, vertex, rot = 0, n = 24, duty = 0.5, phase_shift = 0, count = 0) {
    floor_r = get_floor_r(distance);
    angle_step = 360 / n;
    p_r = floor_r * sin((angle_step * duty) / 2);
    angle_offset = angle_step * phase_shift;
    actual_count = (count > 0 && count <= n) ? count : n;
    rot_sign = (count > 0) ? -1 : 1;
    for (i = [0 : actual_count - 1]) {
        rotate(rot_sign * i * angle_step + angle_offset)
            translate([0, floor_r])
                rotate(90 - rot)
                    circle(r = p_r, $fn = vertex);
    }
}

module project_cal_spiral(start_r = 75, end_r = 300, dots = 37, dot_size = 5) {
    for (i = [0 : dots - 1]) {
        angle = i * (360 / (dots - 1));
        floor_r = start_r + i * ((end_r - start_r) / (dots - 1));
        rotate(angle)
            translate([0, floor_r])
                circle(d = dot_size);
    }
}

module apply_pattern_entry(entry) {
    kind = entry[0];
    if (kind == "text") {
        project_text(
            distance = entry[1],
            msg = entry[2],
            t_size = entry[3],
            kerning_deg = entry[4],
            phase_shift = entry[5],
            location = entry[6]
        );
    } else if (kind == "rays") {
        project_rays(
            distance = entry[1],
            bar_h = entry[2],
            n = entry[3],
            duty = entry[4],
            phase_shift = entry[5],
            count = entry[6]
        );
    } else if (kind == "circles") {
        project_circles(
            distance = entry[1],
            n = entry[2],
            duty = entry[3],
            phase_shift = entry[4],
            count = entry[5]
        );
    } else if (kind == "polygon") {
        project_polygon(
            distance = entry[1],
            vertex = entry[2],
            rot = entry[3],
            n = entry[4],
            duty = entry[5],
            phase_shift = entry[6],
            count = entry[7]
        );
    } else {
        echo("Unknown pattern entry kind: ", kind);
    }
}

module all_2d_patterns() {
    if (render_mode == "PATTERNS") {
        for (entry = pattern_spec)
            apply_pattern_entry(entry);
    } else if (render_mode == "SVG") {
        translate([svg_x_offset, svg_y_offset])
            scale([svg_scale, svg_scale])
                import(svg_filename);
    } else if (render_mode == "CAL") {
        project_cal_spiral();
    } else {
        echo("ERROR: render_mode must be 'PATTERNS', 'SVG', or 'CAL'");
    }
}

// ---------------------------------------------------------------------------
// 7. 3D body
// ---------------------------------------------------------------------------
module lantern_body() {
    fit_radius = (led_diameter / 2) + tolerance;
    merge_eps = 0.05;
    led_z = projection_led_height();
    total_height = lantern_rim_height();
    cyl_bottom_z = (render_mode == "CAL") ? 50 : 0;
    extrude_h = led_z - extrude_tip_clearance_mm;
    extrude_scale = extrude_tip_clearance_mm / led_z;

    union() {
        difference() {
            translate([0, 0, cyl_bottom_z])
                cylinder(h = total_height - cyl_bottom_z, r = cyl_radius);
            translate([0, 0, cyl_bottom_z - 0.1])
                cylinder(h = total_height - cyl_bottom_z + 0.1, r = cyl_radius - wall_thickness);
            translate([0, 0, led_z - merge_eps])
                cylinder(h = led_recess + 0.1 + merge_eps, r = fit_radius);
            translate([0, 0, total_height - 2])
                cylinder(h = 2.1, r1 = fit_radius, r2 = fit_radius + 1.5);
            linear_extrude(height = extrude_h, scale = extrude_scale)
                all_2d_patterns();
        }

        tab_h = 3;
        translate([0, 0, cyl_bottom_z]) {
            if (mount_style == "flange") {
                flange_hole_r = inch / 2;   // 1" centre hole (match mount_style comment)
                difference() {
                    cylinder(h = tab_h, r = cyl_radius);
                    translate([0, 0, -0.1])
                        cylinder(h = tab_h + 0.2, r = flange_hole_r);
                }
            } else {
                // Default: two interior screw tabs
                tab_r   = 10;
                hole_r  = 2.5;
                offset_y = 30;
                difference() {
                    intersection() {
                        union() {
                            translate([0, offset_y, 0]) cylinder(h = tab_h, r = tab_r);
                            translate([-tab_r, offset_y, 0]) cube([tab_r * 2, cyl_radius - offset_y, tab_h]);
                            translate([0, -offset_y, 0]) cylinder(h = tab_h, r = tab_r);
                            translate([-tab_r, -cyl_radius, 0]) cube([tab_r * 2, cyl_radius - offset_y, tab_h]);
                        }
                        cylinder(h = tab_h, r = cyl_radius);
                    }
                    translate([0, offset_y, -0.1]) cylinder(h = tab_h + 0.2, r = hole_r);
                    translate([0, -offset_y, -0.1]) cylinder(h = tab_h + 0.2, r = hole_r);
                }
            }
        }
    }
}

// ---------------------------------------------------------------------------
// 8. Render
// ---------------------------------------------------------------------------
color("DarkSlateGray")
    lantern_body();

if (show_light_rays) {
    color("Gold", 0.8)
        translate([0, 0, -0.5])
            linear_extrude(height = 0.5)
                all_2d_patterns();
    color("Yellow", 0.2)
        linear_extrude(height = projection_led_height() - extrude_tip_clearance_mm, scale = extrude_tip_clearance_mm / projection_led_height())
            all_2d_patterns();
}
