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
upper_ring_height = 8;            // Height of the vertical ring
upper_ring_base_spacing = 2;    // Spacing between body and ring

// Create a continuous vertical ring around the top cylinder with connectors
module upper_ring(
height = upper_ring_height,
base_spacing = upper_ring_base_spacing,
connector_positions = upper_tab_positions,
connector_width = upper_tab_connector_width,
connector_height = upper_tab_connector_height_extension + shoulder_height,
outer_radius = 27.8  // Same as shoulder_transition outer_radius default
) {
    inner_radius = top_radius;
    outer_inner_radius = top_radius + base_spacing;

    ring_thickness = 2;
    color("red")
        union() {
            difference() {
                // Main ring - same outer radius as the shoulder
                union() {
                    // Outer cylinder for the ring

                    //                        cylinder(r = outer_radius, h = height - ring_thickness);
                    // Inner cutout to create the ring
                    //                translate([0, 0, -ring_thickness])
                    beveled_cylinder(r = outer_radius, b = -ring_thickness, h = height);
                }
                //                translate([0, 0, -ring_thickness])
                translate([0, 0, -0.1])
                    union() {
                        translate([0, 0, ring_thickness])
                            cylinder(r = outer_inner_radius, h = height - ring_thickness + 0.2);
                        // Inner cutout to create the ring
                        cylinder(r = outer_inner_radius, h = ring_thickness + 0.2);
                    }
            }


            // Add connectors at exactly the same positions as the original tabs
            // with the original connector height
            for (angle = connector_positions) {
                rotate([0, 0, angle])
                    translate([-connector_width / 2, inner_radius, 0])
                        cube([connector_width, base_spacing, connector_height]);
            }
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
        cylinder(r2 = outer_radius, r1 = top_radius_val, h = height);

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
        turns = 0.3,                 // Standard turns value
        d = (bottom_radius) * 2,     // Outer diameter
        pitch = pitch,               // Distance between complete turns
        starts = 3,                  // Triple-start thread
        thread_depth = thread_depth, // Use depth parameter directly
        thread_angle = 0,            // Square thread profile for precision fit
        left_handed = true,
        lead_in1 = 2                 // Standard lead-in
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

// Create a segment with millstone retaining tab and horizontal flexibility slots
module millstone_retainer_tab_segment(
angle_width,
height = bottom_height,
tab_height = bottom_height - shoulder_extension - 4.5,
tab_width = 7.5,
tab_depth = 1.5,
outer_radius = bottom_radius,
inner_radius = bottom_internal_radius,
tab_length = side_holder_length,
closed_gap_width = 0.75,
) {
    // Calculate the start and end angles to center the tab
    // No need for a vertical slit anymore since we'll use horizontal slots
    start_angle = -angle_width / 2;
    end_angle = angle_width / 2;

    difference() {
        union() {
            // Create the complete cylinder segment (no vertical slit)
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

        // Add horizontal flexibility slots instead of vertical slits
        // These will follow the print layers for better strength
        slot_height = 0.75;                      // Height of the slots
        slot_depth = outer_radius - inner_radius + 0.2; // Wall thickness plus overlap
        
        // Offset distance from tab center
        slot_offset = 2;                         // Distance from tab in mm
        
        // First slot - above the tab
        translate([0, -angle_width/5, tab_height + slot_offset])
            rotate([0, 0, 0])
                cube([slot_depth, angle_width/2.5, slot_height]);
                
        // Second slot - below the tab
        translate([0, -angle_width/5, tab_height - slot_offset - slot_height])
            rotate([0, 0, 0])
                cube([slot_depth, angle_width/2.5, slot_height]);
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
    closed_gap_width = 0.75;       // Width of horizontal slots

    // Create the holder segments at 0° and 180°
    color("Purple") {
        // Holder at 0°
        rotate([0, 0, 0])
            millstone_holder_segment(angle_width = holder_segment_width);

        // Holder at 180°
        rotate([0, 0, 180])
            millstone_holder_segment(angle_width = holder_segment_width);
    }

    // Create the retainer tab segments at 90° and 270° with horizontal slots
    color("Lime") {
        // Retainer at 90°
        rotate([0, 0, 90])
            millstone_retainer_tab_segment(
            angle_width = retainer_segment_width,
            closed_gap_width = closed_gap_width
            );

        // Retainer at 270°
        rotate([0, 0, 270])
            millstone_retainer_tab_segment(
            angle_width = retainer_segment_width,
            closed_gap_width = closed_gap_width
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

// Legacy slit creation function - now uses horizontal slots instead of vertical slits
// This is maintained for backward compatibility but not actually used anymore
module legacy_millstone_slit_at_angle(
offset_x = -4.5,
center_radius = 25,
y_offset = 1.5,
width = 0.75,
height = 0.75, // Height of horizontal slit (was vertical slit width)
spacing = 8.25,
cylinder_height = bottom_height
) {
    // This module is no longer needed as we've switched to horizontal slots
    // in the millstone_retainer_tab_segment module
    // This is kept for backward compatibility
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
