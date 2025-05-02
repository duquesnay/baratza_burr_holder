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
middle_tab_height = 0.8; // [0.5:0.1:2]
side_holder_length = 1.2; // [1:0.1:2]

// Configuration options
cutout_type = "slits"; // ["slits", "original"]
debug_visualize_cutouts = 1; // [0, 1] - Set to 1 to see colored cutout shapes

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
            cube([width + 2*tab_cut_clearance, tab_bevel_length + tab_cut_height_clearance, tab_bevel_height]);
    }
}

module upper_tabs() {
    upper_tab_width = 4.4;
    upper_tab_angles = [45, 225];
    
    for (tab_index = [0:len(upper_tab_angles)-1]) {
        rotate([0, 0, upper_tab_angles[tab_index]])
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

module create_middle_tab() {
    tab_position = bottom_radius - 1;
    tab_radius_extension = 4;
    tab_width = 8.5;
    tab_length = 5;
    tab_half_width = tab_width / 2;
    
    intersection() {
        cylinder(h = middle_tab_height, r = tab_position + tab_radius_extension);
        translate([tab_position, -tab_half_width, 0])
                cube([tab_length, tab_width, middle_tab_height]);
    }
}

module middle_tabs() {
    middle_tab_angles = [0, 120, 240];
    
    for (tab_index = [0:len(middle_tab_angles)-1]) {
        rotate([0, 0, middle_tab_angles[tab_index]])
            create_middle_tab();
    }
}

module millstone_retaining_tabs() {
    stone_thickness = 4.5;
    stone_tab_height = bottom_height - shoulder_extension - stone_thickness;
    stone_tab_width = 7.5;
    stone_tab_depth = 1.5;

    translate([0, 0, stone_tab_height])
        for (side_index = [0:1]) { // 0 = first side, 1 = opposite side
            rotate([0, 0, side_index * 180])
                translate([-stone_tab_width / 2, bottom_internal_radius, 0])
                    rotate([90, 0, 0])
                        prism(stone_tab_width, stone_tab_depth, side_holder_length);
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
    holder_angles = [0, 180];
    
    for (holder_index = [0:len(holder_angles)-1]) {
        rotate([0, 0, holder_angles[holder_index]])
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

module millstone_retainting_tab_cutouts() {
    tab_offset_x = -4.5;
    tab_width = 9;
    tab_height = 3;
    tab_depth = 5.5;
    small_tab_width = 0.75;
    small_tab_offset_z = 5.45;
    small_tab_spacing = 8.25;
    overlap_clearance = 0.05;
    
    tab_positions_y = [-26.5, 23.5];
    
    for (position_index = [0:len(tab_positions_y)-1]) {
        translate([tab_offset_x, tab_positions_y[position_index], -overlap_clearance])
            union() {
                // Main tab cutout
                cube([tab_width, tab_height, tab_depth]);
                
                // Left small tab extension
                translate([0, 0, small_tab_offset_z])
                    cube([small_tab_width, tab_height, tab_depth]);
                    
                // Right small tab extension
                translate([small_tab_spacing, 0, small_tab_offset_z])
                    cube([small_tab_width, tab_height, tab_depth]);
            }
    }
}

module millstone_cutouts_slits() {
    slit_offset_x = -4.5;
    slit_offset_y = -26.5; // Only used for one side, other is rotated 180°
    slit_width = 0.75;
    slit_height = 4;
    slit_spacing = 8.25;
    overlap_clearance = 0.05;
    
    translate([slit_offset_x, slit_offset_y, -overlap_clearance])
        union() {
            cube([slit_width, slit_height, bottom_height + 2*overlap_clearance]);
            translate([slit_spacing, 0, 0])
                cube([slit_width, slit_height, bottom_height + 2*overlap_clearance]);
        }
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
    top_cutout_cube();
    rotate([0, 0, 180])
        top_cutout_cube();
}

// Apply cutouts based on selected type
module apply_cutouts() {
    // Top section cutouts for all variants
    top_cutouts();
    
    // Apply selected millstone cutout type
    if (cutout_type == "original") {
        millstone_retainting_tab_cutouts();
    } else if (cutout_type == "slits") {
        // Apply slits on both sides (180° apart)
        for (slit_side = [0:1]) { // 0 = first side, 1 = opposite side
            rotate([0, 0, slit_side * 180])
                millstone_cutouts_slits();
        }
    }
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
        // Visualize slit cutouts with different colors for each side
        slit_colors = ["red", "blue"];
        slit_opacities = [0.3, 0.3];
        
        for (side = [0:1]) {
            rotate([0, 0, side * 180])
                color(slit_colors[side], slit_opacities[side])
                    millstone_cutouts_slits();
        }
        
        // Visualize retaining tab cutouts
        color("green", 0.3)
            millstone_retainting_tab_cutouts();
            
        // Visualize top cutouts
        color("yellow", 0.3)
            top_cutouts();
    }
}