$fa = 0.1;
$fs = 0.4;

//height (thickness) of 3 side tabs
tab_mid_h = 0.8; //[0.5:0.1:2]

outer_dia = 51.6; // [51:0.05:53]
top_radius = 22.5;

bottom_thickness = 1.5; // [1:0.1:2]

middle_h = 2;
bottom_h = 14;

side_holder_length = 1.2; // [1:0.1:2]

cutouts = "slits"; // ["slits", "original"]
debug_visualize_cutouts = 0; // [0, 1]
top_part_height = 7;

// https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/Primitive_Solids
module prism(l, w, h) {
    polyhedron(
    points = [[0, 0, 0], [l, 0, 0], [l, w, 0], [0, w, 0], [0, w, h], [l, w, h]],
    faces = [[0, 1, 2, 3], [5, 4, 3, 2], [0, 4, 5, 1], [0, 3, 4], [5, 2, 1]]);
}

module create_tab(width, total_height) {
    tip_angle = 45;
    connector_width = 2;
    tip_thickness = 2;
    tip_angle_height = 5;
    bevel_angle = 90 - tip_angle;
    angle_part_height = total_height - tip_angle_height;
    bevel_length = angle_part_height / cos(tip_angle) + tip_thickness * tan(tip_angle);
    //this... could have been rough and simple
    bevel_height = bevel_length * cos(tip_angle);

    difference() {
        tip_to_cylinder_spacing = 1;
        union() {
            translate([-connector_width / 2, 0, 0])
                cube([connector_width, tip_to_cylinder_spacing, 2]); // joint tab, 2mm high, 3mm long
            // tab origin
            translate([-width / 2, tip_to_cylinder_spacing, 0])
                //lower part of tab
                cube([width, tip_thickness, tip_angle_height]); // 5mm high, 2mm deep
            // upper part of tab, beveled at given height
            translate([-width / 2, tip_to_cylinder_spacing, tip_angle_height])
                rotate([-tip_angle, 0, 0])
                    cube([width, tip_thickness, bevel_length]);
            //random long length, can't be twise as long since it's thiner on other dimensions
        }
        //cut at given heigth
        translate([-width / 2 - 0.1, tip_to_cylinder_spacing, top_part_height]) cube([width + 0.2, bevel_length,
            bevel_height]);
    }
}

module upper_tabs() {
    union() {
        rotate([0, 0, 45])
            translate([0, top_radius, 0])
                color("red") create_tab(width = 4, total_height = top_part_height);

        rotate([0, 0, 225])
            translate([0, top_radius, 0])
                color("red") create_tab(width = 4, total_height = top_part_height);
    }
}


module top_part() {
    difference() {
        cylinder(r=22.5, h=7);
        translate([0,0,-0.05])
        cylinder(r=20, h=4.1);
    }
}
module middle_part() {
    difference() {
        cylinder(r=25.5, h=middle_h);
        translate([0,0,-0.05])
        cylinder(r=20,h=middle_h+0.1);
    }
}
module middle_tabs() {
    // prostřední pacičky
    // middle tabs
    translate([-28,-4.25,5.5])
    cube([3.5,8.5,tab_mid_h]);
    
    translate([16,-23.75,5.5])
    rotate([0,0,115])
    cube([3.5,8.5,tab_mid_h]);
    
    translate([11,26.25,5.5])
    rotate([0,0,240])
    cube([3.5,8.5,tab_mid_h]);
}
module millstone_retaining_tabs() {
    t_y = outer_dia/2 - bottom_thickness;
    translate([-3.75,t_y,5.5])
    rotate([90,0,0])
    prism(7.5, 1.5, side_holder_length);
    
    translate([3.75,-t_y,5.5])
    rotate([90,0,180])
    prism(7.5, 1.5, side_holder_length);
}
module bottom_parts() {
    difference() {
        cylinder(r=outer_dia/2, h=bottom_h);
        translate([0,0,-0.05])
        cylinder(r=(outer_dia/2) - bottom_thickness, h=bottom_h + 0.1);
    }
}
module support_ring() {
    difference() {
        cylinder(r=outer_dia/2, bottom_h);
        translate([0,0,-0.5])
        cylinder(r=(outer_dia/2)-0.4, bottom_h+1);
    }
}

module millstone_holders() {
    translate([21.5,-3,0])
    cube([3,6,12.05]);
    
    translate([-24.5,-3,0])
    cube([3,6,12.05]);
}
module side_millstone_holders() {
    translate([21.5,-12,12])
    rotate([0,90,0])
    prism(bottom_h - middle_h,4,2);
    
    translate([21.5,12,0])
    rotate([0,-90,180])
    prism(bottom_h - middle_h,4,2);
    
    translate([-21.5,12,12])
    rotate([0,90,180])
    prism(bottom_h - middle_h,4,2);
    
    translate([-21.5,-12,0])
    rotate([0,-90,0])
    prism(bottom_h - middle_h,4,2);
}

module body() {
    translate([0,0,bottom_h])
    upper_tabs();
    
    translate([0,0,bottom_h])
    color("green")
    top_part();
    color("yellow")

    middle_tabs();

    translate([0,0,bottom_h - middle_h])
    color("blue")
    middle_part();

    color("Lime")
    millstone_retaining_tabs();

    color("orange")
    bottom_parts();

    color("Purple")
    millstone_holders();

    color("Maroon")
    side_millstone_holders();
}
 
module millstone_retainting_tab_cutouts() {
    translate([-4.5,-26.5,-0.05])
    union() {
        cube([9,3,5.5]);
        translate([0,0,5.45])
        cube([0.75,3,5.5]);
        translate([8.25,0,5.45])
        cube([0.75,3,5.5]);
    }
    
    translate([-4.5,23.5,-0.05])
    union() {
        cube([9,3,5.5]);
        translate([0,0,5.45])
        cube([0.75,3,5.5]);
        translate([8.25,0,5.45])
        cube([0.75,3,5.5]);
    }
}

module millstone_cutouts_slits() {
    translate([-4.5,-26.5,-0.05])
    union() {
        cube([0.75,3,bottom_h - middle_h]);
        translate([8.25,0,0])
        cube([0.75,3,bottom_h - middle_h]);
    }
 
}
module top_cutouts() {
    module top_cutout_cube() {
        translate([23.5,-1.5,7])
        cube([4,3,7.05]);
    }
    top_cutout_cube();
    rotate([0,0,180])
    top_cutout_cube();
}

union() {
    difference() {

        body();
        top_cutouts();
        if ( cutouts == "original") {
            millstone_retainting_tab_cutouts();
        } else if (cutouts == "slits") {
            millstone_cutouts_slits();
            rotate([0,0,180])
            millstone_cutouts_slits();
        }
    }

    //support_ring();
    if ( debug_visualize_cutouts == 1) {
        color("red",0.3)
        millstone_cutouts_slits();
        rotate([0,0,180])
        color("blue",0.3)
        millstone_cutouts_slits();
    }
}