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

module create_tab(width = 4) {
    // Core tab dimensions
    tab_total_height = shoulder_height + top_height;
    tab_tip_angle = 45;
    tab_base_spacing = 1.6;
    tab_thickness = 1.6;
    tab_connector_width = 2;
    tab_connector_height = 2 + shoulder_height;
    tab_angle_start_height = shoulder_height + 5;
    tab_bevel_angle = 90 - tab_tip_angle;

    // Calculated dimensions
    tab_angled_part_height = tab_total_height - tab_angle_start_height;
    tab_bevel_length = tab_angled_part_height / cos(tab_tip_angle) + tab_thickness * tan(tab_tip_angle);
    tab_bevel_height = tab_bevel_length * cos(tab_tip_angle);

    // Extra clearance for clean cuts
    tab_cut_clearance = 0.1;
    tab_cut_height_clearance = 1;

    difference() {
        union() {
            translate([-tab_connector_width / 2, 0, 0])
                cube([tab_connector_width, tab_base_spacing, tab_connector_height]); // joint tab

            // Lower part of tab
            translate([-width / 2, tab_base_spacing, 0])
                cube([width, tab_thickness, tab_angle_start_height]);

            // Upper part of tab, beveled at given height
            translate([-width / 2, tab_base_spacing, tab_angle_start_height])
                rotate([-tab_tip_angle, 0, 0])
                    cube([width, tab_thickness, tab_bevel_length]);
        }

        // Cut at given height
        translate([-width / 2 - tab_cut_clearance, tab_base_spacing, tab_total_height])
            cube([width + 2 * tab_cut_clearance, tab_bevel_length + tab_cut_height_clearance, tab_bevel_height]);
    }
}

module upper_tabs() {
    upper_tab_width = 4.4;

    for (angle = [45, 225]) {
        rotate([0, 0, angle])
            translate([0, top_radius, 0])
                color("red") create_tab(width = upper_tab_width);
    }
}

module beveled_cylinder(r, h, b) {
    union() {
        cylinder(h = h - b, r = r);
        translate([0, 0, h - b])
            cylinder(h = b, r1 = r, r2 = r - b);
    }
}


module top_part() {
    top_inner_radius = 20;
    overlap_clearance = 0.05;
    height_clearance = 0.1;
    top_total_height = shoulder_height + top_height;

    difference() {
        cylinder(r = top_radius, h = top_total_height);
        translate([0, 0, -overlap_clearance])
            cylinder(r = top_inner_radius, h = top_total_height + height_clearance);
    }
}

module shoulder_part() {
    shoulder_outer_radius = 26.8;
    shoulder_bevel_radius = 25.8;
    bevel_thickness = 1;
    overlap_clearance = 0.05;
    height_clearance = 0.1;
    radius_clearance = 0.1;

    // Main shoulder transition
    color("blue") difference() {
        union() {
            cylinder(r1 = shoulder_outer_radius, r2 = top_radius, h = shoulder_height);
        }
        translate([0, 0, -overlap_clearance])
            cylinder(r = top_radius, h = shoulder_height + height_clearance);
    }

    // Reverse thicker reinforcement with bevel for mechanical strength
    rotate([0, 180, 0])
        color("white") difference() {
            beveled_cylinder(r = shoulder_bevel_radius + bevel_thickness,
            h = shoulder_extension,
            b = bevel_thickness);

            translate([0, 0, -overlap_clearance])
                cylinder(r = bottom_internal_radius + radius_clearance,
                h = shoulder_extension + height_clearance);
        }
}

// Middle tab with helix angle for threading onto the grinder
module create_middle_tab() {
    // Tab dimensions
    tab_position = bottom_radius - 4.5;
    tab_radius_extension = 6.5;
    tab_width = 40;
    middle_tab_height = 0.8; // [0.5:0.1:2]
    tab_half_width = tab_width / 2;
    pitch = 2;
    thread_width = 0.8;  // Make thread thinner (1mm in total width)
    thread_depth = 2;  // Make thread thinner (1mm in total width)
    //    chamfer_size = 0.8; // Size of the chamfer on the outer edge
    // Thread angle for 2mm rise per 120 degrees
    //thread_angle = -2.2; // Calculated helix angle for the given pitch

    // Define custom square thread profile

    // Keep the original uncentered profile
    external_ridge_height = 0.3;
    shoulder_straight_overhang_depth = 0.6;
    profile_pts = [
            [-pitch / 2, 0], // Start at bottom left
            [0, 0], // Up 1.5mm (thread depth)
            [0, thread_depth], // Up 1.5mm (thread depth)
            [external_ridge_height, thread_depth], // Up 1.5mm (thread depth)
            [thread_width, shoulder_straight_overhang_depth], // Down (thread depth)
            [thread_width, 0], // Down (thread depth)
        ];

    thread_helix(
    turns = 0.3,
    d = (bottom_radius) * 2, // Outer diameter
    pitch = pitch, // Distance between complete turns
    starts = 3,
    profile = profile_pts, // Use custom profile
    left_handed = true,
    lead_in1 = 2
    );

    // Apply a rotation to the original tab to create the helix effect
    //difference() {
    //        buttress_threaded_rod(
    //        d = (tab_position + tab_radius_extension) * 2, // Outer diameter
    //        l = 3, // Length/height
    //        pitch = 2, // Distance between complete turns
    //        starts = 3, // 3 parallel threads (3 starting points)
    //        left_handed = true,
    ////        thread_depth = 2,
    //        blunt_start2 = true
    //        );
    //        translate([0, 0, -10])
    //            cylinder(h = 20, r = bottom_internal_radius);

    //}

}

module middle_tabs() {
    create_middle_tab();
}

// Parameters for millstone retaining tabs
stone_thickness = 4.5;
stone_tab_height = bottom_height - shoulder_extension - stone_thickness;
stone_tab_width = 7.5;
stone_tab_depth = 1.5;
stone_tab_angles = [0, 180];

// Create a single millstone tab
module create_millstone_tab(width, depth, length) {
    translate([-width / 2, 0, 0])
        rotate([90, 0, 0])
            prism(width, depth, length);
}

// Create all millstone retaining tabs around the cylinder
module millstone_retaining_tabs() {
    translate([0, 0, stone_tab_height])
        for (angle = stone_tab_angles) {
            rotate([0, 0, angle])
                translate([0, bottom_internal_radius, 0])
                    create_millstone_tab(stone_tab_width, stone_tab_depth, side_holder_length);
        }
}

module bottom_parts() {
    overlap_clearance = 0.05;
    height_clearance = 0.1;

    difference() {
        cylinder(r = bottom_radius, h = bottom_height);
        translate([0, 0, -overlap_clearance])
            cylinder(r = bottom_internal_radius, h = bottom_height + height_clearance);
    }
}

module millstone_single_holder() {
    holder_wall_thickness = 1.5;
    holder_width = 3;
    holder_height = 6;
    holder_half_height = holder_height / 2;

    holder_prism_offset_y = 12;
    holder_prism_height = 4;
    holder_prism_depth = 2;
    holder_prism_z_level = 6;

    translate([bottom_radius - holder_wall_thickness - holder_width, 0, 0]) {
        // Main holder pillar
        translate([0, -holder_half_height, 0])
            cube([holder_width, holder_height, bottom_height]);

        // Left grip
        translate([0, -holder_prism_offset_y, holder_prism_z_level])
            rotate([0, -90, 0])
                prism(bottom_height - holder_prism_z_level, holder_prism_height, -holder_prism_depth);

        // Right grip (mirrored)
        mirror([0, 1, 0])
            translate([0, -holder_prism_offset_y, holder_prism_z_level])
                rotate([0, -90, 0])
                    prism(bottom_height - holder_prism_z_level, holder_prism_height, -holder_prism_depth);
    }
}

module millstone_holders() {
    for (angle = [0, 180]) {
        rotate([0, 0, angle])
            millstone_single_holder();
    }
}

module body() {
    middle_tabs_position = 5.5;

    // Top section components
    translate([0, 0, bottom_height]) {
        upper_tabs();

        color("green")
            top_part();

        shoulder_part();
    }

    // Middle section
    color("yellow")
        translate([0, 0, middle_tabs_position])
            middle_tabs();

    // Bottom section components
    color("Lime")
        millstone_retaining_tabs();

    color("orange")
        bottom_parts();

    color("Purple")
        millstone_holders();
}

// Parameters for millstone flexibility slits
slit_offset_x = -4.5;
slit_center_radius = 25;
slit_y_offset = 1.5;
slit_width = 0.75;
slit_height = 4;
slit_spacing = 8.25;
slit_clearance = 0.05;

// Create a single flexibility slit
module create_slit(width, height, depth) {
    cube([width, height, depth]);
}

// Create a pair of slits with specified spacing
module create_slit_pair(width, height, depth, spacing) {
    union() {
        create_slit(width, height, depth);
        translate([spacing, 0, 0])
            create_slit(width, height, depth);
    }
}

// Create slits for a single tab position
module millstone_cutouts_slits() {
    // Calculate final position
    slit_offset_y = -(slit_center_radius + slit_y_offset);
    total_depth = bottom_height + 2 * slit_clearance;

    translate([slit_offset_x, slit_offset_y, -slit_clearance])
        create_slit_pair(slit_width, slit_height, total_depth, slit_spacing);
}

module top_cutouts() {
    cutout_x = 23.5;
    cutout_y = -1.5;
    cutout_z = 7;
    cutout_width = 3;
    cutout_length = 4;
    cutout_height = 7.05;

    module top_cutout_cube() {
        translate([cutout_x, cutout_y, cutout_z])
            cube([cutout_length, cutout_width, cutout_height]);
    }
    
    // Create two cutouts at opposite sides
    top_cutout_angles = [0, 180];
    for (angle = top_cutout_angles) {
        rotate([0, 0, angle])
            top_cutout_cube();
    }
}


// Millstone Tab and Slit System - Documentation
// This module doesn't render anything, it's documentation for the design
module millstone_tab_system() {
    // Each tab position has both a physical tab and corresponding flexibility slits
    // When modifying the tab design, this helps ensure both parts stay in sync

    // For reference only - the actual rendering is done in:
    // Physical tabs: millstone_retaining_tabs() in body()
    // Flexibility slits: millstone_cutout_slits_all() in apply_cutouts()
}

// Create all slit cutouts at specified tab positions
module millstone_cutout_slits_all() {
    for (angle = stone_tab_angles) {
        rotate([0, 0, angle])
            millstone_cutouts_slits();
    }
}

// Apply cutouts
module apply_cutouts() {
    // Apply top cutouts
    top_cutouts();

    // Apply millstone tab flexibility slits
    millstone_cutout_slits_all();
}

// Final assembly
union() {
    difference() {
        // Main body
        body();

        // Apply cutouts
        apply_cutouts();
    }

    // Debug visualization
    if (debug_visualize_cutouts == 1) {
        // Show millstone tab slits with alternating colors for clarity
        for (i = [0:len(stone_tab_angles) - 1]) {
            color(i % 2 == 0 ? "red" : "blue", 0.3)
                rotate([0, 0, stone_tab_angles[i]])
                    millstone_cutouts_slits();
        }

        // Visualize top cutouts
        color("yellow", 0.3)
            top_cutouts();
    }
}