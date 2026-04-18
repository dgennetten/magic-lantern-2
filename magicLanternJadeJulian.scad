// ==========================================
// MODULAR PROJECTION LANTERN GENERATOR
// ==========================================

// 1. Global Lantern Parameters
light_height = 70;
// Meaning depends on `light_height_is_to_rim` (floor at z = 0)
cyl_radius = 40;
// Outer radius of the lantern cylinder
wall_thickness = 2;      // Thickness of the cylinder wall
font_name = "Allerta Stencil"; 
// Windows default Stencil font
use <AllertaStencil-Regular.ttf>;
$fn = 120;               // Smoothness of 3D curves

// 2. LED Mounting Parameters
led_diameter = 72.5;
// Outer diameter of physical LED light fixture
led_recess = 24;
// Pocket depth from outside rim down toward the LED
tolerance = 0.25;
// Clearance for a snug friction fit

// false: `light_height` = floor → LED (rim = light_height + led_recess). true: `light_height` = floor → rim, LED = light_height - led_recess
light_height_is_to_rim = false;

function projection_led_height() = light_height_is_to_rim ? (light_height - led_recess) : light_height;
function lantern_rim_height() = light_height_is_to_rim ? light_height : (light_height + led_recess);

// 3. Visualization Toggle
show_light_rays = true;
// MUST BE FALSE for final F6 mesh export!

// ==========================================
// 4. RENDER MODE & SVG CONTROLS
// ==========================================
// Select: "PATTERNS", "SVG", or "CAL"
render_mode = "PATTERNS";
svg_filename = "my_pattern.svg"; 
svg_scale = 1.0;         
svg_x_offset = 0;        
svg_y_offset = 0;
// Pre-calculated physical arc widths for the ray cutouts
width_24 = (2 * PI * cyl_radius / 24) * 0.5;
width_12 = (2 * PI * cyl_radius / 12) * 0.5;
// REFACTORED: Calculates floor radius based on distance down from the LED
function get_floor_r(distance) = (projection_led_height() * cyl_radius) / distance;

// ==========================================
// 2D FLOOR PATTERN MODULES
// ==========================================
module project_text(distance, msg, t_size=8, kerning_deg=12, f_name=font_name, phase_shift=0, location="top") {
    floor_r = get_floor_r(distance);
    chars = len(msg);
    total_angle = (chars - 1) * kerning_deg;
    // Half-span so the midpoint between first and last glyph sits at noon (top) or 6 o'clock (bottom).
    start_angle = total_angle / 2;
    bottom = (location == "bottom");
    center_angle = bottom ? 180 : 0;
    // phase_shift=0: arc centered on center_angle. Nonzero: extra rotation in kerning_deg steps.
    angle_offset = kerning_deg * phase_shift;
    for (i = [0 : chars - 1]) {
        a = bottom
            ? (center_angle - start_angle + i * kerning_deg + angle_offset)
            : (center_angle + start_angle - i * kerning_deg + angle_offset);
        rotate(a)
            translate([0, floor_r])
                rotate(bottom ? 180 : 0)
                    text(msg[i], size=t_size, font=f_name, halign="center", valign="center");
    }
}

module project_rays(distance, bar_h, n, duty=0.5, phase_shift=0) {
    // A smaller distance is closer to the light source (higher up the cylinder)
    dist_top = distance - (bar_h / 2);
    dist_bottom = distance + (bar_h / 2);
    
    // The top of the ray projects further out onto the floor than the bottom
    r_outer = get_floor_r(dist_top);
    r_inner = get_floor_r(dist_bottom);
    
    angle_step = 360 / n;
    wedge_angle = angle_step * duty;
    angle_offset = angle_step * phase_shift;
    for (i = [0 : n - 1]) {
        rotate(i * angle_step + angle_offset)
            polygon([
                [ r_inner * tan(wedge_angle/2), r_inner ],
                [ r_outer * tan(wedge_angle/2), r_outer ],
                [-r_outer * tan(wedge_angle/2), r_outer ],
                [-r_inner * tan(wedge_angle/2), r_inner ]
            ]);
    }
}

module project_circles(distance, n, duty=0.5, phase_shift=0) {
    floor_r = get_floor_r(distance);
    angle_step = 360 / n;
    c_r = floor_r * sin((angle_step * duty) / 2);
    angle_offset = angle_step * phase_shift;
    for (i = [0 : n - 1]) {
        rotate(i * angle_step + angle_offset)
            translate([0, floor_r])
                circle(r = c_r);
    }
}

module project_polygon(distance, vertex, rot=0, n=24, duty=0.5, phase_shift=0) {
    floor_r = get_floor_r(distance);
    angle_step = 360 / n;
    p_r = floor_r * sin((angle_step * duty) / 2);
    angle_offset = angle_step * phase_shift;
    for (i = [0 : n - 1]) {
        rotate(i * angle_step + angle_offset)
            translate([0, floor_r])
                // +90 forces 1st vertex to 12 o'clock.
                // -rot applies clockwise offset.
                rotate(90 - rot)
                    circle(r = p_r, $fn = vertex);
    }
}

module project_cal_spiral(start_r=75, end_r=300, dots=37, dot_size=5) {
    // 37 dots guarantees exactly one dot every 10 degrees for a full 360 turn
    for (i = [0 : dots - 1]) {
        angle = i * (360 / (dots - 1));
        floor_r = start_r + i * ((end_r - start_r) / (dots - 1));
        rotate(angle)
            translate([0, floor_r])
                circle(d = dot_size);
    }
}

module all_2d_patterns() {
    if (render_mode == "PATTERNS") {
        // Diamonds (vertex=4, rot=0)
        project_polygon(distance = 55, vertex = 4, rot = 0, n = 20, duty = 0.5);
        // Diamonds (vertex=4, rot=0, phase_shift=.5)
        project_polygon(distance = 48, vertex = 4, rot = 0, n = 20, duty = 0.5, phase_shift = 0.5);
        // Distances recalculated from 130mm light_height to maintain exact visual placement
        project_text(distance = 34.5, msg = "JADE & JULIAN'S", t_size = 22, kerning_deg = 14, location = "top");
        project_text(distance = 34.5, msg = "BEDROOM", t_size = 22, kerning_deg = 14, location = "bottom");
        project_circles(distance = 25, n = 20, duty = 0.75);
        project_rays(distance = 20, bar_h = width_24 * 2, n = 20, duty = 0.75);
        project_circles(distance = 14.5, n = 20, duty = 0.75);

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

// ==========================================
// 3D LANTERN COMPONENTS
// ==========================================
module lantern_body() {
    fit_radius = (led_diameter / 2) + tolerance;
    // LED cavity starts slightly below light_height to avoid a coplanar face with the bore (preview/STL).
    merge_eps = 0.05;
    
    led_z = projection_led_height();
    total_height = lantern_rim_height();
    // Auto-shorten the cylinder by 50mm if doing a Calibration print
    cyl_bottom_z = (render_mode == "CAL") ? 50 : 0;

    // Scale math to avoid the tip singularity during extrusion
    extrude_h = led_z - 5;
    extrude_scale = (led_z - extrude_h) / led_z;

    union() {
        difference() {
            // 1. Solid Master Cylinder (Shortened for CAL mode)
            translate([0, 0, cyl_bottom_z])
                cylinder(h = total_height - cyl_bottom_z, r = cyl_radius);
            // 2. Main inner bore through full cylinder height (must reach past light_height: fit_radius
            //    is smaller than cyl_radius - wall_thickness, or a solid ring remains in the LED zone).
            translate([0, 0, cyl_bottom_z - 0.1]) 
                cylinder(h = total_height - cyl_bottom_z + 0.1, r = cyl_radius - wall_thickness);
            // 3. The LED Cavity (starts slightly below LED plane to merge booleans with void)
            translate([0, 0, led_z - merge_eps])
                cylinder(h = led_recess + 0.1 + merge_eps, r = fit_radius);
            // 4. Chamfer for easy LED insertion
            translate([0, 0, total_height - 2])
                cylinder(h = 2.1, r1 = fit_radius, r2 = fit_radius + 1.5);
            // 5. Extrude the 2D patterns
            linear_extrude(height = extrude_h, scale = extrude_scale) {
                all_2d_patterns();
            }
        }
        
        // 6. Mounting Tabs (Flush with the bottom edge)
        tab_r = 10;
        hole_r = 2.5;
        tab_h = 3;
        
        // Moved the center inward by 10mm total from outer radius (y=30 instead of y=35)
        offset_y = 30;
        translate([0, 0, cyl_bottom_z]) {
            difference() {
                // Solid tabs, intersected with outer cylinder so the straight lines end cleanly
                intersection() {
                    union() {
                        // 12 o'clock U-shape
                        translate([0, offset_y, 0]) cylinder(h = tab_h, r = tab_r);
                        translate([-tab_r, offset_y, 0]) cube([tab_r * 2, cyl_radius - offset_y, tab_h]);
                        // 6 o'clock U-shape
                        translate([0, -offset_y, 0]) cylinder(h = tab_h, r = tab_r);
                        translate([-tab_r, -cyl_radius, 0]) cube([tab_r * 2, cyl_radius - offset_y, tab_h]);
                    }
                    cylinder(h = tab_h, r = cyl_radius);
                }
                // 5mm concentric screw holes
                translate([0, offset_y, -0.1]) cylinder(h = tab_h + 0.2, r = hole_r);
                translate([0, -offset_y, -0.1]) cylinder(h = tab_h + 0.2, r = hole_r);
            }
        }
    }
}

// ==========================================
// FINAL RENDER
// ==========================================
color("DarkSlateGray") {
    lantern_body();
}

if (show_light_rays) {
    color("Gold", 0.8)
        translate([0, 0, -0.5]) 
        linear_extrude(height = 0.5)
            all_2d_patterns();
    color("Yellow", 0.2)
        linear_extrude(height = projection_led_height() - 5, scale = 5 / projection_led_height())
            all_2d_patterns();
}