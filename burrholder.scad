// Include BOSL2 library
include <BOSL2/std.scad>
include <BOSL2/threading.scad>

// Quality settings
$fa = 0.1;
$fs = 0.4;

// Dimensions - Main structure
outer_diameter = 51.6; // [51:0.05:53]
bottom_radius = outer_diameter / 2;
bottom_thickness = 1.7; // [1:0.1:2]
bottom_internal_radius = bottom_radius - bottom_thickness;


// Parameters for upper ring
top_ring1_outer_radius = 22.5;
top_ring1_inner_radius = 20;
top_ring2_outer_radius = bottom_radius;
upper_ring_height = 8;            // Height of the vertical ring
top_ring_spacing = 2;    // Spacing between body and ring

// Heights - Sections
top_rings_height = 6;
shoulder_height = 2;
bottom_height = 11;
shoulder_extension = 1.5;

// Tabs - Dimensions
side_holder_length = 1.2; // [1:0.1:2]

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
upper_tab_angles = [45, 225];  // Angles around the circle where tabs are placed

// Create a continuous vertical ring around the top cylinder with connectors
module top_ring2(
height = upper_ring_height,
base_spacing = top_ring_spacing,
connector_positions = upper_tab_angles,
connector_width = upper_tab_connector_width,
connector_height = upper_tab_connector_height_extension + shoulder_height,
thickness,
outer_radius = top_ring2_outer_radius  // Same as shoulder_transition outer_radius default
) {
    inner_radius = base_spacing + top_ring1_outer_radius;
    thickness = outer_radius - inner_radius;

    cutout_clearance = 0.01; // percentage

    union() {
        difference() {
            // Main ring - same outer radius as the shoulder
            union() {
                beveled_cylinder(r = outer_radius, b = thickness, h = height);
            }
            //                translate([0, 0, -ring_thickness])
            apply_z_cutout_clearance(cutout_clearance, height);
            cylinder(r = inner_radius, h = height);
        }
    }

    module apply_z_cutout_clearance(z_clearance, height) {
        scale([1, 1, 1 + 2 * z_clearance])
            translate([0, 0, -height * cutout_clearance])
                cylinder(r = inner_radius, h = height);
    }


    // Add connectors at exactly the same positions as the original tabs
    // with the original connector height
    for (angle = connector_positions) {
        rotate([0, 0, angle])
            translate([-connector_width / 2, inner_radius, 0])
                cube([connector_width, base_spacing, connector_height]);
    }

}

// Create a beveled cylinder for the ring
// This is a simplified version of the original beveled cylinder
// r is the outer radius, h is the height, and b is the bevel thickness
module beveled_cylinder(r, h, b) {
    if (b < 0) {
        // Create a cylinder with a beveled bottom
        b = -b;
        union() {
            translate([0, 0, b])
                cylinder(h = h - b, r = r);
            cylinder(h = b, r1 = r - b, r2 = r);
        }
    } else {
        // Create a cylinder with bevel top
        union() {
            cylinder(h = h - b, r = r);
            translate([0, 0, h - b])
                cylinder(h = b, r1 = r, r2 = r - b);
        }
    }
}


// Create the hollow top cylinder
module top_ring1(
outer_radius = top_ring1_outer_radius,
inner_radius = top_ring1_inner_radius,
height = shoulder_height + top_rings_height
) {
    overlap_clearance = 0.05;
    height_clearance = 0.1;
    difference() {
        // Outer cylinder
        cylinder(r = outer_radius, h = height);

        // Inner hollow (with clearance for clean difference operation)
        translate([0, 0, -overlap_clearance])
            cylinder(r = inner_radius, h = height + height_clearance);
    }
}

// Create the shoulder transition part with reinforcement
// @todo to refactor, using common variables, etc
module shoulder_transition(
outer_radius = 25.8,
outer_radius_val = top_ring1_outer_radius,
bevel_thickness = 1,
height = shoulder_height,
extension = shoulder_extension,
inner_radius = bottom_internal_radius,
overlap_clearance = 0.05
) {
    height_clearance = 0.1;
    radius_clearance = 0.1;
    bevel_radius = outer_radius;
    // Main shoulder transition (conical ring)
    difference() {
        // Outer tapered cylinder
        cylinder(r2 = outer_radius, r1 = outer_radius_val, h = height);

        // Inner cutout to create ring
        translate([0, 0, -overlap_clearance])
            cylinder(r = outer_radius_val, h = height + height_clearance);
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
module create_middle_tab() {
    // Tab dimensions
    tab_position = bottom_radius - 4.5;
    tab_radius_extension = 6.5;
    tab_width = 40;
    middle_tab_height = 0.8; // [0.5:0.1:2]
    tab_half_width = tab_width / 2;

    // Use standard thread parameters that are known to work well
    pitch = 2;
    thread_depth = 1.5;      // Standard depth for reliable threading

    // Use the default thread profile which renders reliably
    thread_helix(
    turns = 0.3, // Standard turns value
    d = (bottom_radius) * 2, // Outer diameter
    pitch = pitch, // Distance between complete turns
    starts = 3, // Triple-start thread
    thread_depth = thread_depth, // Use depth parameter directly
    thread_angle = 0, // Square thread profile for precision fit
    left_handed = true,
    lead_in1 = 2                 // Standard lead-in
    );
}

// Wrapper function for backward compatibility - uses default parameters
module middle_tabs() {
    create_middle_tab();
}


// Create a segment of the hollow bottom cylinder
module bottom_cylinder_segment(
start_angle,
end_angle,
outer_radius = bottom_radius,
inner_radius = bottom_internal_radius,
height,
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

// Create a segment with millstone retaining tab and horizontal flexibility slots
module millstone_retainer_tab_segment(
angle_width,
height = bottom_height,
z_position = bottom_height - shoulder_extension - 4.5,
tab_width = 7.5,
tab_depth = 1.5,
outer_radius = bottom_radius,
inner_radius = bottom_internal_radius,
tab_length = side_holder_length,
slit_width = 1,
) {
    // Calculate the start and end angles to center the tab with a negative margin to create slits
    end_angle = angle_width / 2 - slit_width;
    start_angle = -end_angle;

    union() {
        // Create the complete cylinder segment
        bottom_cylinder_segment(
        start_angle = start_angle,
        end_angle = end_angle,
        height = height
        );

        // Add the millstone tab - rotated to align perpendicular to the cylinder radius
        // The -90° rotation positions the tab at right angles to the segment's central angle
        translate([inner_radius, 0, z_position])
            rotate([0, 0, 180])
                //            translate([ inner_radius, 0, z_position])
                retainer_tab(tab_width, tab_depth, tab_length);
    }
}

// Create a single millstone tab
module retainer_tab(
width,
depth,
height,
) {
    rotate([90, 0, 0])
        linear_extrude(width, center = true)
            polygon(points = [[0, 0], [depth, 0], [0, height]]);
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
    holder_segments_angle = [0, 180]; // Angles for holder segments
    retainer_segment_width = 30;   // Angular width of retainer segments at 90° and 270°
    retainer_tab_angles = [90, 270]; // Angles for retainer segments
    // Create the holder segments at 0° and 180°
    color("Purple") {
        // Holder at 0°
        for (angle = holder_segments_angle)
        rotate([0, 0, angle])
            millstone_holder_segment(angle_width = holder_segment_width);

    }

    // Create the retainer tab segments at 90° and 270° with horizontal slots
    color("Lime") {
        for (angle = retainer_tab_angles)
        rotate([0, 0, angle])
            millstone_retainer_tab_segment(
            angle_width = retainer_segment_width
            );
    }

    // Create the plain wall segments - connect the holders and retainers
    color("orange") {
        // Four wall segments to connect the main components
        // Each segment connects a holder to a retainer tab

        // 1. Connect 0° holder to 90° tab
        bottom_cylinder_segment(
        start_angle = holder_segment_width / 2,
        end_angle = 90 - retainer_segment_width / 2,
        outer_radius = outer_radius,
        inner_radius = inner_radius,
        height = height
        );

        // 2. Connect 90° tab to 180° holder
        bottom_cylinder_segment(
        start_angle = 90 + retainer_segment_width / 2,
        end_angle = 180 - holder_segment_width / 2,
        outer_radius = outer_radius,
        inner_radius = inner_radius,
        height = height
        );

        // 3. Connect 180° holder to 270° tab
        bottom_cylinder_segment(
        start_angle = 180 + holder_segment_width / 2,
        end_angle = 270 - retainer_segment_width / 2,
        outer_radius = outer_radius,
        inner_radius = inner_radius,
        height = height
        );

        // 4. Connect 270° tab to 0° holder (wraps around 360°)
        bottom_cylinder_segment(
        start_angle = 270 + retainer_segment_width / 2,
        end_angle = 360 - holder_segment_width / 2,
        outer_radius = outer_radius,
        inner_radius = inner_radius,
        height = height
        );
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
    // @todo refactor this structure
    // Top section components
    translate([0, 0, bottom_height_val]) {
        // Top cylinder
        color("green")
            top_ring1();

        // Shoulder transition
        color("blue")
            shoulder_part();

        // Upper ring around the top cylinder
        color("red")
            top_ring2();
    }

    // Middle section - threaded tabs
    color("yellow")
        translate([0, 0, tabs_position])
            middle_tabs();

    // Bottom section components
    bottom_parts();
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
