// ==========================================
// MODULAR PROJECTION LANTERN GENERATOR
// ==========================================

// 1. Global Lantern Parameters
light_height = 130;      // Height of the LED point light source (Z axis origin of rays)
cyl_radius = 35;         // Outer radius of the lantern cylinder
wall_thickness = 2;      // Thickness of the cylinder wall
font_name = "Stencil";   // Windows default Stencil font
$fn = 120;               // Smoothness of 3D curves

// 2. LED Mounting Parameters
led_diameter = 72.5;       // Outer diameter of physical LED light fixture
led_recess = 24;         // How far down inside the cylinder top the LED sits
tolerance = 0.25;        // Clearance for a snug friction fit

// 3. Visualization Toggle
show_light_rays = true; // MUST BE FALSE for final F6 mesh export!

// ==========================================
// 4. RENDER MODE & SVG CONTROLS
// ==========================================
render_mode = "PATTERNS";     // Change to "PATTERNS" to use the built-in modules

svg_filename = "my_pattern.svg"; // Must be in the same folder as this .scad file
svg_scale = 1.0;         // Tweak this since OpenSCAD cannot auto-scale
svg_x_offset = 0;        // Nudge the SVG if it didn't import perfectly centered
svg_y_offset = 0;

// Pre-calculated physical arc widths for the ray cutouts
width_24 = (2 * PI * cyl_radius / 24) * 0.5;
width_12 = (2 * PI * cyl_radius / 12) * 0.5;

function get_floor_r(z) = (light_height * cyl_radius) / (light_height - z);

// ==========================================
// 2D FLOOR PATTERN MODULES
// ==========================================
module project_text(z_height, msg, t_size=8, kerning_deg=12, f_name=font_name) {
    floor_r = get_floor_r(z_height);
    chars = len(msg);
    total_angle = (chars - 1) * kerning_deg;
    start_angle = total_angle / 2;

    for (i = [0 : chars - 1]) {
        rotate(start_angle - i * kerning_deg)
            translate([0, floor_r])
                text(msg[i], size=t_size, font=f_name, halign="center", valign="center");
    }
}

module project_rays(z_height, bar_h, n, duty=0.5) {
    z_bottom = z_height - (bar_h / 2);
    z_top = z_height + (bar_h / 2);
    
    r_outer = get_floor_r(z_top);
    r_inner = get_floor_r(z_bottom);
    
    angle_step = 360 / n;
    wedge_angle = angle_step * duty;

    for (i = [0 : n - 1]) {
        rotate(i * angle_step)
            polygon([
                [ r_inner * tan(wedge_angle/2), r_inner ],
                [ r_outer * tan(wedge_angle/2), r_outer ],
                [-r_outer * tan(wedge_angle/2), r_outer ],
                [-r_inner * tan(wedge_angle/2), r_inner ]
            ]);
    }
}

module project_circles(z_height, n, duty=0.5) {
    floor_r = get_floor_r(z_height);
    angle_step = 360 / n;
    c_r = floor_r * sin((angle_step * duty) / 2);
    
    for (i = [0 : n - 1]) {
        rotate(i * angle_step)
            translate([0, floor_r])
                circle(r = c_r);
    }
}

module all_2d_patterns() {
    if (render_mode == "PATTERNS") {
        project_rays(z_height = 15, bar_h = width_24 * 4, n = 24, duty = 0.5);
        project_circles(z_height = 35, n = 24, duty = 0.5);
        project_text(z_height = 55, msg = "ONLY THE SUN KNOWS TRUE TIME", t_size = 5.5, kerning_deg = 11);
        project_rays(z_height = 75, bar_h = width_12, n = 12, duty = 0.5);
        project_circles(z_height = 90, n = 24, duty = 0.5);
        project_rays(z_height = 105, bar_h = width_24 * 4, n = 24, duty = 0.5);
    } else if (render_mode == "SVG") {
        translate([svg_x_offset, svg_y_offset])
            scale([svg_scale, svg_scale])
                import(svg_filename);
    } else {
        echo("ERROR: render_mode must be 'PATTERNS' or 'SVG'");
    }
}

// ==========================================
// 3D LANTERN COMPONENTS
// ==========================================
module lantern_body() {
    fit_radius = (led_diameter / 2) + tolerance;
    lip_thickness = 3; 
    lip_width = 4;
    
    // The physical top of the lantern is the light origin PLUS the recess depth
    total_height = light_height + led_recess;

    // Scale math to avoid the tip singularity during extrusion
    extrude_h = light_height - 5;
    extrude_scale = (light_height - extrude_h) / light_height;

    difference() {
        // 1. Solid Master Cylinder
        cylinder(h = total_height, r = cyl_radius);
        
        // 2. Main Inner Lantern Void (Stops just below the LED lip)
        translate([0, 0, -0.1]) 
            cylinder(h = light_height - lip_thickness + 0.1, r = cyl_radius - wall_thickness);

        // 3. The LED Cavity (Starts at light_height, goes to the top)
        translate([0, 0, light_height])
            cylinder(h = led_recess + 0.1, r = fit_radius);
            
        // 4. The Lip Aperture (Hole connecting the LED to the void)
        translate([0, 0, light_height - lip_thickness - 0.1])
            cylinder(h = lip_thickness + 0.2, r = fit_radius - lip_width);
            
        // 5. Chamfer for easy LED insertion at the very top
        translate([0, 0, total_height - 2])
            cylinder(h = 2.1, r1 = fit_radius, r2 = fit_radius + 1.5);

        // 6. Extrude the 2D patterns
        linear_extrude(height = extrude_h, scale = extrude_scale) {
            all_2d_patterns();
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
        linear_extrude(height = light_height - 5, scale = 5/130)
            all_2d_patterns();
}