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
top_ring1_outer_radius = 22;
top_ring1_inner_radius = 18;
top_rings_spacing = 2;    // Spacing between ring 1 and 2
top_ring2_outer_radius = bottom_radius + 2;


// Parameters for upper tabs
rubber_tab_width = 2;
rubber_tab_height = 3;  // Added to shoulder_height
rubber_tab_angles = [45, 225];  // Angles around the circle where tabs are placed

// Parameters for retainer tabs
retainer_tab_contenance = 4.5; // Millstone has a 4mm lip, so .5 margin

// Heights - Sections
top_rings_height = 5;
shoulder_height = 3;
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


// Create a beveled cylinder - generic function
// h = height, or = outer radius, ir = inner radius, tb = top bevel width, bb = bottom bevel width
module beveled_tube(h, or, ir, tb = 0, bb = 0) {
    assert(or >= ir, "Inner radius must be less than outer radius");
    assert(h >= tb + bb, str("Height (", h, ") must be greater than top plus bottom bevels", [tb, bb]));
    echo("Beveled tube: ", [h, or, ir, tb, bb]);
    thickness = or - ir;
    if (tb > thickness) {
        tb = thickness;
    }
    if (bb > thickness) {
        bb = thickness;
    }
    union() {
        if (h > bb + tb)
            translate([0, 0, bb])
                tube(h = h - tb - bb, or = or, ir = ir, center = false);
        if (tb > 0)
            translate([0, 0, h - tb])
                tube(h = tb, or1 = or, or2 = or - tb, ir = ir, center = false);
        if (bb > 0) {
            tube(h = bb, or1 = or - bb, or2 = or, ir = ir, center = false);
        }
    }
}

// Stable tube/ring module using only core OpenSCAD functions
// Parameters:
// h = height of the tube
// or1 = outer radius at bottom
// or2 = outer radius at top (defaults to or1 if not specified)
// ir1 = inner radius at bottom
// ir2 = inner radius at top (defaults to ir1 if not specified)
// fn = optional fragment number (resolution)
module stable_tube(h, or1, ir1, or2 = undef, ir2 = undef, fn = $fn) {
    // Default values for optional parameters
    or2_actual = (or2 == undef) ? or1 : or2;
    ir2_actual = (ir2 == undef) ? ir1 : ir2;

    // Input validation
    assert(h > 0, str("Height must be positive: ", h));
    assert(or1 >= ir1, "Outer radius must be greater than inner radius at bottom");
    assert(or2_actual >= ir2_actual, "Outer radius must be greater than inner radius at top");

    // Create a 2D profile and rotate it around the Z axis
    rotate_extrude(angle = 360, $fn = fn) {
        polygon(
        points = [
                [ir1, 0], // Bottom inner
                [or1, 0], // Bottom outer
                [or2_actual, h], // Top outer
                [ir2_actual, h]    // Top inner
            ],
        // Define the face as a simple quad
        paths = [[0, 1, 2, 3]]
        );
    }
}

// Create the hollow top cylinder
module top_ring1(
outer_radius = top_ring1_outer_radius,
inner_radius = top_ring1_inner_radius,
height = top_rings_height
) {
    tube(h = height, or = outer_radius, ir = inner_radius, center = false);
}

// Create a continuous vertical ring around the top cylinder with connectors
module top_ring2(
height = top_rings_height,
base_spacing = top_rings_spacing, // should be refreing to connector origin
outer_radius = top_ring2_outer_radius  // Same as shoulder outer_radius default
) {
    inner_radius = base_spacing + top_ring1_outer_radius;
    thickness = outer_radius - inner_radius;
    outer_radius = outer_radius; // making it thicker to compensate
    bb = outer_radius - bottom_radius; // just in case we decide to over over large

    difference() {

        beveled_tube(
        h = height,
        or = outer_radius,
        ir = inner_radius,
        tb = 0,
        bb = bb
        );

        count = 8;
        for (i = [0:count - 1])
        rotate([0, 0, i * (360 / count)])
            translate([outer_radius + 4, 0, 0])
                cylinder(r = 6, h = height);

    }

}

// Create the shoulder transition part with reinforcement
// @todo to refactor, using common variables, etc
module shoulder(
height = shoulder_height,
inner_radius = top_ring1_inner_radius,
outer_radius = bottom_radius
) {
    bevel = top_rings_spacing;
    tube(h = height, or = outer_radius, ir = inner_radius, center = false);
}

// Parameters for middle tab thread
middle_tab_pitch = 2;
middle_tab_thread_width = 0.8;  // Make thread thinner (1mm in total width)
middle_tab_thread_depth = 2;    // Make thread thinner (1mm in total width)
middle_tab_turns = 0.3;
middle_tab_starts = 3;
middle_tab_lead_in = 2;
middle_tab_left_handed = true;
thread_depth = 1.5;      // Standard depth for reliable threading

// Middle tab with helix angle for threading onto the grinder
module tightening_thread() {
    // Use standard thread parameters that are known to work well

    // Use the default thread profile which renders reliably
    thread_helix(
    turns = middle_tab_turns, // Standard turns value
    d = (bottom_radius) * 2, // Outer diameter
    pitch = 2, // Distance between complete turns, fixed
    starts = 3, // Triple-start thread
    thread_depth = thread_depth, // how deep the thread goes, max 2 probably
//    thread_angle = 0, // Square thread profile for precision fit
    left_handed = true,
    lead_in1 = 2, // Standard lead-in
    anchor = BOTTOM
    );
}

// Create a segment of the hollow bottom cylinder
module bottom_cylinder_segment(
start_angle,
end_angle,
outer_radius = bottom_radius,
inner_radius = bottom_internal_radius,
height
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
        height = height
        );

        millstone_single_holder();
    }
}

// Create a segment with millstone retaining tab and horizontal flexibility slots
module millstone_retainer_tab_segment(
angle_width,
height = bottom_height,
z_position = bottom_height - retainer_tab_contenance,
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
    rotate([-90, 0, 0])
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
threads_z_position = 5.5;

// Assemble the complete body from all components
module body() {
    // @todo refactor this structure
    // Top section components
    translate([0, 0, bottom_height]) {

        // Shoulder transition
        color("blue")
            shoulder(height = shoulder_height);

    }

    translate([0, 0, bottom_height + shoulder_height]) {
        // inner ring
        color("green")
            top_ring1();
        // Outer ring
        color("red")
            top_ring2();

        color("pink") {

            // Add connectors at exactly the same positions as the original tabs
            // with the original connector height
            for (angle = rubber_tab_angles) {
                rotate([0, 0, angle])
                    translate([-rubber_tab_width / 2, top_ring1_inner_radius, 0])
                        cube(size = [rubber_tab_width, top_ring1_outer_radius - top_ring1_inner_radius +
                            top_rings_spacing,
                            rubber_tab_height]
                        );
            }

            bevel = top_rings_spacing;

//            //             creating a bevel for the overhang under the rubber
//            stable_tube(h = bevel, or1 = top_ring1_outer_radius + bevel, ir1 = top_ring1_outer_radius, ir2 =
//                top_ring1_outer_radius + bevel);
        }
    }

    // Middle section - threaded tabs
    color("yellow")
        translate([0, 0, threads_z_position])
            tightening_thread();

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
