 $fa = 0.1;
$fs = 0.4;

//height (thickness) of 3 side tabs
tab_mid_h = 0.8; //[0.5:0.1:2]

outer_dia = 51.6; // [51:0.05:53]
bottom_radius = outer_dia / 2;
top_radius = 22.5;

bottom_thickness = 1.7; // [1:0.1:2]
bottom_internal_radius = bottom_radius - bottom_thickness;

top_h = 6;
shoulder_h = 2;
bottom_h = 11;

side_holder_length = 1.2; // [1:0.1:2]

cutouts = "slits"; // ["slits", "original"]
debug_visualize_cutouts = 0; // [0, 1]

// https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/Primitive_Solids
module prism(l, w, h) {
    polyhedron(
    points = [[0, 0, 0], [l, 0, 0], [l, w, 0], [0, w, 0], [0, w, h], [l, w, h]],
    faces = [[0, 1, 2, 3], [5, 4, 3, 2], [0, 4, 5, 1], [0, 3, 4], [5, 2, 1]]);
}

module create_tab(width = 4) {
    // Core tab dimensions
    tab_height = shoulder_h + top_h;
    tip_angle = 45;
    rubber_width_spacing = 1.6;
    tip_thickness = 1.6;
    connector_width = 2;
    connector_height = 2 + shoulder_h;
    tip_angle_height = shoulder_h + 5;
    bevel_angle = 90 - tip_angle;
    
    // Calculated dimensions
    angled_part_height = tab_height - tip_angle_height;
    bevel_length = angled_part_height / cos(tip_angle) + tip_thickness * tan(tip_angle);
    bevel_height = bevel_length * cos(tip_angle);
    
    // Extra clearance for clean cuts
    cut_clearance = 0.1;
    cut_height_clearance = 1;

    difference() {
        union() {
            translate([-connector_width / 2, 0, 0])
                cube([connector_width, rubber_width_spacing, connector_height]); // joint tab
                
            // Lower part of tab
            translate([-width / 2, rubber_width_spacing, 0])
                cube([width, tip_thickness, tip_angle_height]);
                
            // Upper part of tab, beveled at given height
            translate([-width / 2, rubber_width_spacing, tip_angle_height])
                rotate([-tip_angle, 0, 0])
                    cube([width, tip_thickness, bevel_length]);
        }
        
        // Cut at given height
        translate([-width / 2 - cut_clearance, rubber_width_spacing, tab_height]) 
            cube([width + 2*cut_clearance, bevel_length + cut_height_clearance, bevel_height]);
    }
}

module upper_tabs() {
    union() {
        rotate([0, 0, 45])
            translate([0, top_radius, 0])
                color("red") create_tab(width = 4.4);

        rotate([0, 0, 225])
            translate([0, top_radius, 0])
                color("red") create_tab(width = 4.4);
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
    
    difference() {
        cylinder(r = top_radius, h = shoulder_h + top_h);
        translate([0, 0, -overlap_clearance])
            cylinder(r = top_inner_radius, h = shoulder_h + top_h + height_clearance);
    }
}
shoulder_extends = 1.5;
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
            cylinder(r1 = shoulder_outer_radius, r2 = top_radius, h = shoulder_h);
        }
        translate([0, 0, -overlap_clearance])
            cylinder(r = top_radius, h = shoulder_h + height_clearance);
    }
    
    // Reverse thicker reinforcement with bevel for mechanical strength
    rotate([0, 180, 0])
        color("white") difference() {
            beveled_cylinder(r = shoulder_bevel_radius + bevel_thickness, 
                             h = shoulder_extends, 
                             b = bevel_thickness);

            translate([0, 0, -overlap_clearance])
                cylinder(r = bottom_internal_radius + radius_clearance, 
                         h = shoulder_extends + height_clearance);
        }
}

module create_middle_tab() {
    tab_position = bottom_radius - 1;
    tab_radius_extension = 4;
    tab_width = 8.5;
    tab_length = 5;
    tab_half_width = tab_width / 2;
    
    intersection() {
        cylinder(h = tab_mid_h, r = tab_position + tab_radius_extension);
        translate([tab_position, -tab_half_width, 0])
                cube([tab_length, tab_width, tab_mid_h]);
    }
}

module middle_tabs() {
    for (i = [0:2]) {
        rotate([0, 0, i * 120])
            create_middle_tab();
    }
}

module millstone_retaining_tabs() {
    stone_thickness = 4.5;
    stone_tab_h = bottom_h - shoulder_extends - stone_thickness;
    stone_tab_width = 7.5;

    translate([0, 0, stone_tab_h])
        for (i = [0:1]) {
            rotate([0, 0, i * 180])
                translate([-stone_tab_width / 2, bottom_internal_radius, 0])
                    rotate([90, 0, 0])
                        prism(stone_tab_width, 1.5, side_holder_length);
        }

}
module bottom_parts() {
    difference() {
        cylinder(r = bottom_radius, h = bottom_h); // refined to match mid cylinder
        translate([0, 0, -0.05])
            cylinder(r = bottom_internal_radius, h = bottom_h + 0.1);
    }
}

module millstone_single_holder() {
    wall_thickness = 1.5;
    holder_width = 3;
    holder_height = 6;
    holder_half_height = holder_height / 2;
    
    prism_offset_y = 12;
    prism_height = 4;
    prism_depth = 2;
    prism_z_level = 6;
    
    translate([bottom_radius - wall_thickness - holder_width, 0, 0]) {
        // Main holder pillar
        translate([0, -holder_half_height, 0])
            cube([holder_width, holder_height, bottom_h]);

        // Left grip
        translate([0, -prism_offset_y, prism_z_level])
            rotate([0, -90, 0])
                prism(bottom_h - prism_z_level, prism_height, -prism_depth);
                
        // Right grip (mirrored)
        mirror([0, 1, 0])
            translate([0, -prism_offset_y, prism_z_level])
                rotate([0, -90, 0])
                    prism(bottom_h - prism_z_level, prism_height, -prism_depth);
    }
}

module millstone_holders() {
    for (i = [0:1])
    rotate([0, 0, i * 180])
        millstone_single_holder();

}

module body() {
    translate([0, 0, bottom_h])
        upper_tabs();

    translate([0, 0, bottom_h])
        color("green")
            top_part();

    height_tabs_h = 5.5;
    color("yellow")
        translate([0, 0, height_tabs_h])
            middle_tabs();

        translate([0, 0, bottom_h])
//            color("blue")
                shoulder_part();

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
    
    for (pos_y in tab_positions_y) {
        translate([tab_offset_x, pos_y, -overlap_clearance])
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
    slit_offset_y = -26.5;
    slit_width = 0.75;
    slit_height = 4;
    slit_spacing = 8.25;
    overlap_clearance = 0.05;
    
    translate([slit_offset_x, slit_offset_y, -overlap_clearance])
        union() {
            cube([slit_width, slit_height, bottom_h + 2*overlap_clearance]);
            translate([slit_spacing, 0, 0])
                cube([slit_width, slit_height, bottom_h + 2*overlap_clearance]);
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

union() {
    difference() {

        body();
        top_cutouts();
        if (cutouts == "original") {
            millstone_retainting_tab_cutouts();
        } else if (cutouts == "slits") {
            millstone_cutouts_slits();
            rotate([0, 0, 180])
                millstone_cutouts_slits();
        }
    }

    //support_ring();
    if (debug_visualize_cutouts == 1) {
        color("red", 0.3)
            millstone_cutouts_slits();
        rotate([0, 0, 180])
            color("blue", 0.3)
                millstone_cutouts_slits();
    }
}