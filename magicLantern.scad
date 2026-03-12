// ==========================================
// MODULAR PROJECTION LANTERN GENERATOR
// ==========================================

// 1. Global Lantern Parameters
light_height = 90;      // Height of the LED point light source (Z axis origin)
cyl_radius = 40;         // INCREASED TO 40mm to support the 72.5mm LED!
wall_thickness = 2;      // Thickness of the cylinder wall
font_name = "Stencil";   // Windows default Stencil font
$fn = 120;               // Smoothness of 3D curves

// 2. LED Mounting Parameters
led_diameter = 72.5;     // Outer diameter of physical LED light fixture
led_recess = 24;         // How far down inside the cylinder top the LED sits
tolerance = 0.25;        // Clearance for a snug friction fit

// 3. Visualization Toggle
show_light_rays = true; // MUST BE FALSE for final F6 mesh export!

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
function get_floor_r(distance) = (light_height * cyl_radius) / distance;

// ==========================================
// 2D FLOOR PATTERN MODULES
// ==========================================
module project_text(distance, msg, t_size=8, kerning_deg=12, f_name=font_name, phase_shift=0) {
    floor_r = get_floor_r(distance);
    chars = len(msg);
    total_angle = (chars - 1) * kerning_deg;
    start_angle = total_angle / 2;
    
    // Phase shift moves the text block by multiples of the kerning spacing
    angle_offset = kerning_deg * phase_shift;

    for (i = [0 : chars - 1]) {
        rotate(start_angle - i * kerning_deg + angle_offset)
            translate([0, floor_r])
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
                // +90 forces 1st vertex to 12 o'clock. -rot applies clockwise offset.
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

        // Distances recalculated from 130mm light_height to maintain exact visual placement
        project_text(distance = 65, msg = "ONLY THE SUN KNOWS TRUE TIME", t_size = 12, kerning_deg = 11, phase_shift = -5);
        
        // Diamonds (vertex=4, rot=0)
        project_polygon(distance = 44, vertex = 4, rot = 0, n = 24, duty = 0.5);
        
        // Diamonds (vertex=4, rot=0, phase_shift=.5)
        project_polygon(distance = 49, vertex = 4, rot = 0, n = 24, duty = 0.5, phase_shift = 0.5);
        
        project_circles(distance = 35, n = 24, duty = 0.75);
        project_rays(distance = 25, bar_h = width_24 * 4, n = 24, duty = 0.75);
        project_circles(distance = 14.5, n = 24, duty = 0.75);

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
    lip_thickness = 3; 
    lip_width = 4;
    
    total_height = light_height + led_recess;
    
    // Auto-shorten the cylinder by 50mm if doing a Calibration print
    cyl_bottom_z = (render_mode == "CAL") ? 50 : 0;

    // Scale math to avoid the tip singularity during extrusion
    extrude_h = light_height - 5;
    extrude_scale = (light_height - extrude_h) / light_height;

    difference() {
        // 1. Solid Master Cylinder (Shortened for CAL mode)
        translate([0, 0, cyl_bottom_z])
            cylinder(h = total_height - cyl_bottom_z, r = cyl_radius);
            
        // 2. Main Inner Lantern Void
        translate([0, 0, cyl_bottom_z - 0.1]) 
            cylinder(h = light_height - lip_thickness - cyl_bottom_z + 0.1, r = cyl_radius - wall_thickness);
            
        // 3. The LED Cavity 
        translate([0, 0, light_height])
            cylinder(h = led_recess + 0.1, r = fit_radius);
            
        // 4. The Lip Aperture 
        translate([0, 0, light_height - lip_thickness - 0.1])
            cylinder(h = lip_thickness + 0.2, r = fit_radius - lip_width);
            
        // 5. Chamfer for easy LED insertion
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