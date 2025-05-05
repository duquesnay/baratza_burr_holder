// Include BOSL2 library
include <BOSL2/std.scad>
include <BOSL2/threading.scad>

// Quality settings
$fa = 0.1;
$fs = 0.4;

// Dimensions - Main structure
outer_diameter = 51.6; // [51:0.05:53]
bottom_radius = outer_diameter / 2;
top_radius = 22.5;
bottom_thickness = 1.7; // [1:0.1:2]
bottom_internal_radius = bottom_radius - bottom_thickness;

// Heights - Sections
top_height = 6;
shoulder_height = 2;
bottom_height = 11;
shoulder_extension = 1.5;

// Tabs - Dimensions
side_holder_length = 1.2; // [1:0.1:2]


// Configuration options
debug_visualize_cutouts = 0; // [0, 1] - Set to 1 to see colored cutout shapes

// https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/Primitive_Solids
module prism(l, w, h) {
    polyhedron(
    points = [[0, 0, 0], [l, 0, 0], [l, w, 0], [0, w, 0], [0, w, h], [l, w, h]],
    faces = [[0, 1, 2, 3], [5, 4, 3, 2], [0, 4, 5, 1], [0, 3, 4], [5, 2, 1]]);
}

// Parameters for upper tabs
upper_tab_width = 4.4;
upper_tab_base_spacing = 1.6;
upper_tab_thickness = 1.6;
upper_tab_connector_width = 2;
upper_tab_connector_height_extension = 2;  // Added to shoulder_height
upper_tab_positions = [45, 225];  // Angles around the circle where tabs are placed

// Create a single tab with specified parameters - simplified straight design
module create_tab(
width = 4,
total_height = shoulder_height + top_height,
base_spacing = upper_tab_base_spacing,
thickness = upper_tab_thickness,
connector_width = upper_tab_connector_width,
connector_height = upper_tab_connector_height_extension + shoulder_height
) {
    // Create a simplified straight tab without angled top
    union() {
        // Connector to the main body - wider base for stability
        translate([-connector_width / 2, 0, 0])
            cube([connector_width, base_spacing, connector_height]);

        // Main tab body - straight vertical tab
        translate([-width / 2, base_spacing, 0])
            cube([width, thickness, total_height]);
    }
}

// Create all upper tabs at their designated positions
module upper_tabs(
tab_width = upper_tab_width,
tab_positions = upper_tab_positions,
radius = top_radius
) {
    for (angle = tab_positions) {
        rotate([0, 0, angle])
            translate([0, radius, 0])
                color("red") create_tab(width = tab_width);
    }
}

// Parameters for upper ring
upper_ring_thickness = 1.6;       // Thickness of the vertical ring
upper_ring_height = 8;            // Height of the vertical ring
upper_ring_base_spacing = 1.6;    // Spacing between body and ring

// Create a continuous vertical ring around the top cylinder with connectors
module upper_ring(
thickness = upper_ring_thickness,
height = upper_ring_height,
base_spacing = upper_ring_base_spacing,
connector_positions = upper_tab_positions,
connector_width = upper_tab_connector_width,
connector_height = upper_tab_connector_height_extension + shoulder_height,
radius = top_radius
) {
    color("red") union() {
        // Main ring
        difference() {
            // Outer cylinder for the ring
            cylinder(r = radius + base_spacing + thickness, h = height);
            
            // Inner cutout to create the ring
            translate([0, 0, -0.1])
                cylinder(r = radius + base_spacing, h = height + 0.2);
        }
        
        // Add connectors at exactly the same positions as the original tabs
        // with the original connector height
        for (angle = connector_positions) {
            rotate([0, 0, angle])
                translate([-connector_width / 2, radius, 0])
                    cube([connector_width, base_spacing, connector_height]);
        }
    }
}

module beveled_cylinder(r, h, b) {
    union() {
        cylinder(h = h - b, r = r);
        translate([0, 0, h - b])
            cylinder(h = b, r1 = r, r2 = r - b);
    }
}


// Create the hollow top cylinder
module top_cylinder(
outer_radius = top_radius,
height = shoulder_height + top_height,
inner_radius = 20,
overlap_clearance = 0.05,
height_clearance = 0.1
) {
    difference() {
        // Outer cylinder
        cylinder(r = outer_radius, h = height);

        // Inner hollow (with clearance for clean difference operation)
        translate([0, 0, -overlap_clearance])
            cylinder(r = inner_radius, h = height + height_clearance);
    }
}

// Legacy function for backward compatibility
module top_part() {
    top_cylinder();
}

// Create the shoulder transition part with reinforcement
module shoulder_transition(
outer_radius = 25.8,
top_radius_val = top_radius,
bevel_thickness = 1,
height = shoulder_height,
extension = shoulder_extension,
inner_radius = bottom_internal_radius,
overlap_clearance = 0.05,
height_clearance = 0.1,
radius_clearance = 0.1
) {
    bevel_radius = outer_radius;
    // Main shoulder transition (conical ring)
    color("blue") difference() {
        // Outer tapered cylinder
        cylinder(r1 = outer_radius, r2 = top_radius_val, h = height);

        // Inner cutout to create ring
        translate([0, 0, -overlap_clearance])
            cylinder(r = top_radius_val, h = height + height_clearance);
    }

}

// Legacy function for backward compatibility
module shoulder_part() {
    shoulder_transition();
}

// Parameters for middle tab thread
middle_tab_pitch = 2;
middle_tab_thread_width = 0.8;  // Make thread thinner (1mm in total width)
middle_tab_thread_depth = 2;    // Make thread thinner (1mm in total width)
middle_tab_external_ridge_height = 0.3;
middle_tab_shoulder_overhang_depth = 0.6;
middle_tab_turns = 0.3;
middle_tab_starts = 3;
middle_tab_lead_in = 2;
middle_tab_left_handed = true;

// Middle tab with helix angle for threading onto the grinder
module create_middle_tab(
// Parameters with defaults that match the original values
radius = bottom_radius,
pitch = middle_tab_pitch,
thread_width = middle_tab_thread_width,
thread_depth = middle_tab_thread_depth,
ridge_height = middle_tab_external_ridge_height,
shoulder_depth = middle_tab_shoulder_overhang_depth,
turns = middle_tab_turns,
starts = middle_tab_starts,
lead_in = middle_tab_lead_in,
left_handed = middle_tab_left_handed
) {
    // Define custom thread profile
    profile_pts = [
            [-pitch / 2, 0], // Start at bottom left
            [0, 0], // Bottom right corner
            [0, thread_depth], // Up to thread depth
            [ridge_height, thread_depth], // External ridge at top
            [thread_width, shoulder_depth], // Down to shoulder
            [thread_width, 0], // Back to bottom
        ];

    // Create thread helix with the custom profile
    thread_helix(
    turns = turns,
    d = radius * 2, // Outer diameter
    pitch = pitch, // Distance between complete turns
    starts = starts,
    profile = profile_pts, // Use custom profile
    left_handed = left_handed,
    lead_in1 = lead_in
    );
}

// Wrapper function for backward compatibility - uses default parameters
module middle_tabs() {
    create_middle_tab();
}

// Create a single millstone tab
module create_millstone_tab(
width,
depth,
length,
) {
    translate([-width / 2, 0, 0])
        rotate([90, 0, 0])
            prism(width, depth, length);
}

// Create a segment of the hollow bottom cylinder
module bottom_cylinder_segment(
start_angle,
end_angle,
outer_radius = bottom_radius,
inner_radius = bottom_internal_radius,
height = bottom_height,
overlap_clearance = 0,
height_clearance = 0
) {
    angle_span = end_angle - start_angle;

    // Outer segment
    rotate([0, 0, start_angle])
        rotate_extrude(angle = angle_span)
            translate([inner_radius, 0, 0])
                square([outer_radius - inner_radius, height]);
}

// Create a holder segment with the millstone holder integrated
module millstone_holder_segment(
angle_width = 60, // Angular width of the segment
outer_radius = bottom_radius,
inner_radius = bottom_internal_radius,
height = bottom_height,
tab_height = bottom_height - shoulder_extension - 4.5,
overlap_clearance = 0.05,
height_clearance = 0.1
) {
    // Calculate the start and end angles to center the holder at 0°
    half_width = angle_width / 2;
    start_angle = -half_width;
    end_angle = half_width;

    union() {
        // Create the cylinder segment
        bottom_cylinder_segment(
        start_angle = start_angle,
        end_angle = end_angle,
        outer_radius = outer_radius,
        inner_radius = inner_radius,
        height = height,
        overlap_clearance = overlap_clearance,
        height_clearance = height_clearance
        );

        millstone_single_holder();
    }
}

// Create a segment with millstone retaining tab and flexibility slit
module millstone_retainer_tab_segment(
angle_width,
height = bottom_height,
tab_height = bottom_height - shoulder_extension - 4.5,
tab_width = 7.5,
tab_depth = 1.5,
outer_radius = bottom_radius,
inner_radius = bottom_internal_radius,
tab_length = side_holder_length,
slit_width = 0.75,
) {
    // Calculate the start and end angles to center the tab
    half_width = (angle_width - slit_width) / 2;
    start_angle = -half_width;
    end_angle = half_width;

    union() {
        // Create the cylinder segment minus the slit
        bottom_cylinder_segment(
        start_angle = start_angle,
        end_angle = end_angle,
        height = height
        );

        // Add the millstone tab - rotated to align perpendicular to the cylinder radius
        // The -90° rotation positions the tab at right angles to the segment's central angle
        rotate([0, 0, -90])
            translate([0, inner_radius, tab_height])
                create_millstone_tab(tab_width, tab_depth, tab_length);
    }
}

// Create the bottom cylinder from segments with integrated holders and retainer tabs
module bottom_parts(
outer_radius = bottom_radius,
inner_radius = bottom_internal_radius,
height = bottom_height,
overlap_clearance = 0.05,
height_clearance = 0.1
) {
    // Local parameter definitions for better readability
    holder_segment_width = 60;     // Angular width of holder segments at 0° and 180°
    retainer_segment_width = 30;   // Angular width of retainer segments at 90° and 270°
    slit_width = 0.75;             // Width of gap between segments acting as flexibility slits

    // Calculate half-widths for angle calculations
    half_retainer_width = retainer_segment_width / 2;
    half_holder_width = holder_segment_width / 2;

    // Create the holder segments at 0° and 180°
    color("Purple")
        for (angle = [0, 180]) {
            rotate([0, 0, angle])
                millstone_holder_segment(angle_width = holder_segment_width);
        }

    // Create the retainer tab segments at 90° and 270° to match original design
    color("Lime")
        for (angle = [90, 270]) {
            // No additional rotation needed - tab is already centered at these angles in the segment
            rotate([0, 0, angle])
                // Create the retainer tab segment with slit space reserved
                millstone_retainer_tab_segment(
                angle_width = retainer_segment_width,
                slit_width = slit_width
                );
        }

    // Create the plain wall segments - adjusted to avoid both holder and retainer segments
    color("orange")
        union() {
            for (segment_angles = [
                    [half_holder_width, 90 - half_retainer_width],
                    [90 + half_retainer_width, 180 - half_holder_width],
                    [180 + half_holder_width, 270 - half_retainer_width],
                    [270 + half_retainer_width, 360 - half_holder_width]
                ]) {
                bottom_cylinder_segment(
                start_angle = segment_angles[0],
                end_angle = segment_angles[1],
                outer_radius = outer_radius,
                inner_radius = inner_radius,
                height = height,
                overlap_clearance = overlap_clearance,
                height_clearance = height_clearance
                );
            }
        }
}

// Create a single millstone holder with grips
module millstone_single_holder(
// Physical dimensions
wall_thickness = 1.5,
width = 3,
height = 6,
cylinder_height = bottom_height,
outer_radius = bottom_radius,

// Grip prism parameters
prism_offset_y = 12,
prism_height = 4,
prism_depth = 2,
prism_z_level = 6
) {
    half_height = height / 2;

    // Calculate positioning based on parameters
    x_position = outer_radius - wall_thickness - width;

    translate([x_position, 0, 0]) {
        // Main holder pillar
        translate([0, -half_height, 0])
            cube([width, height, cylinder_height]);

        // Left grip
        translate([0, -prism_offset_y, prism_z_level])
            rotate([0, -90, 0])
                prism(cylinder_height - prism_z_level, prism_height, -prism_depth);

        // Right grip (mirrored)
        mirror([0, 1, 0])
            translate([0, -prism_offset_y, prism_z_level])
                rotate([0, -90, 0])
                    prism(cylinder_height - prism_z_level, prism_height, -prism_depth);
    }
}

// Position parameters for main components
middle_tabs_position = 5.5;

// Assemble the complete body from all components
module body(
tabs_position = middle_tabs_position,
bottom_height_val = bottom_height
) {
    // Top section components
    translate([0, 0, bottom_height_val]) {
        // Top cylinder
        color("green")
            top_part();

        // Shoulder transition
        shoulder_part();
        
        // Upper ring around the top cylinder
        upper_ring();
    }

    // Middle section - threaded tabs
    color("yellow")
        translate([0, 0, tabs_position])
            middle_tabs();

    // Bottom section components
    bottom_parts();
}


// Create a single flexibility slit
module create_slit(
width = 0.75,
height = 4,
depth = bottom_height + 2 * 0.05, // Add clearance to cylinder height
clearance = 0.05
) {
    cube([width, height, depth]);
}

// Create a pair of slits with specified spacing
module create_slit_pair(
width = 0.75,
height = 4,
depth = bottom_height + 2 * 0.05,
spacing = 8.25
) {
    union() {
        for (position = [0, spacing]) {
            translate([position, 0, 0])
                create_slit(width, height, depth);
        }
    }
}

// Legacy slit creation function - no longer used with parametric spacing approach
module legacy_millstone_slit_at_angle(
offset_x = -4.5,
center_radius = 25,
y_offset = 1.5,
width = 0.75,
height = 4,
spacing = 8.25,
cylinder_height = bottom_height
) {
    // Calculate final position
    slit_offset_y = -(center_radius + y_offset);
    total_depth = cylinder_height;

    translate([offset_x, slit_offset_y, 0])
        create_slit_pair(width, height, total_depth, spacing);
}

// Create a single top cutout (currently disabled in the original code)
module top_cutout_at_angle(
cutout_x = 23.5,
cutout_y = -1.5,
cutout_z = 7,
cutout_width = 3,
cutout_length = 4,
cutout_height = 7.05
) {
    translate([cutout_x, cutout_y, cutout_z])
        cube([cutout_length, cutout_width, cutout_height]);
}

// Create all top cutouts but deactivated
module deactivated_legacy_top_cutouts(angles = [0, 180]) {
    for (angle = angles) {
        rotate([0, 0, angle])
            top_cutout_at_angle();
    }
}

body();
