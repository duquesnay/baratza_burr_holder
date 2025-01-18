$fa = 0.1;
$fs = 0.4;

//height (thickness) of 3 side tabs
tab_mid_h = 0.8; //[0.5:0.1:2]

outer_dia = 51.6; // [51:0.05:53]
bottom_radius = outer_dia / 2;
top_radius = 22.5;

bottom_thickness = 2; // [1:0.1:2]
bottom_internal_radius = bottom_radius - bottom_thickness;

top_h = 7;
shoulder_h = 2;
bottom_h = 12;

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
    // using shoulder_h to be able to play
    tab_height = shoulder_h + top_h;
    tip_angle = 45;
    rubber_width_spacing_spacing = 1.6;
    tip_thickness = 1.6;
    connector_width = 2;
    tip_angle_height = shoulder_h + 5;
    bevel_angle = 90 - tip_angle;
    //this... could have been rough and simple, but I went for the math purity:
    angled_part_height = tab_height - tip_angle_height;
    bevel_length = angled_part_height / cos(tip_angle) + tip_thickness * tan(tip_angle);
    bevel_height = bevel_length * cos(tip_angle);

    difference() {
        union() {
            translate([-connector_width / 2, 0, 0])
                cube([connector_width, rubber_width_spacing_spacing, 2 + shoulder_h]); // joint tab, 2mm high, 3mm long
            // tab origin
            translate([-width / 2, rubber_width_spacing_spacing, 0])
                //lower part of tab
                cube([width, tip_thickness, tip_angle_height]);
            // upper part of tab, beveled at given height
            translate([-width / 2, rubber_width_spacing_spacing, tip_angle_height])
                rotate([-tip_angle, 0, 0])
                    cube([width, tip_thickness, bevel_length]);
            //random long length, can't be twise as long since it's thiner on other dimensions
        }
        //cut at given heigth
        translate([-width / 2 - 0.1, rubber_width_spacing_spacing, tab_height]) cube([width + 0.2, bevel_length,
            bevel_height]);
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
    difference() {
        cylinder(r = 22.5, h = top_h);
        translate([0, 0, -0.05])
            cylinder(r = 20, h = top_h + 0.1);
    }
}
module shoulder_part() {
    // TODO user parameter for diameter and thickness
    difference() {
        beveled_cylinder(r = 25.8, h = shoulder_h, b = 1.2);

        translate([0, 0, -0.05])
            cylinder(r = 20, h = shoulder_h + 0.1);
    }
}
module middle_tabss() {
    // middle tabs
    translate([-28, -4.25, 5.5])
        cube([3.5, 8.5, tab_mid_h]);

    translate([16, -23.75, 5.5])
        rotate([0, 0, 115])
            cube([3.5, 8.5, tab_mid_h]);

    translate([11, 26.25, 5.5])
        rotate([0, 0, 240])
            cube([3.5, 8.5, tab_mid_h]);
}
module millstone_retaining_tabs() {
    t_y = bottom_internal_radius;
    stone_thickness = 6.5;
    stone_tab_h = bottom_h - stone_thickness;
    stone_tab_width = 7.5;

    for (i = [0:1]) {
        rotate([0, 0, i * 180])
            translate([-stone_tab_width / 2, t_y, stone_tab_h])
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
    translate([bottom_internal_radius - 3, 0, 0]) {
        translate([0, -3, 0])
            cube([3, 6, bottom_h]);

        translate([0, -12, 0])
            rotate([0, -90, 0])
                prism(bottom_h, 4, -2);
        mirror([0, 1, 0])
            translate([0, -12, 0])
                rotate([0, -90, 0])
                    prism(bottom_h, 4, -2);
    }
}

module millstone_holders() {
    millstone_single_holder();
    mirror([1, 0, 0])
        millstone_single_holder();
}

module body() {
    translate([0, 0, bottom_h])
        upper_tabs();

    translate([0, 0, bottom_h + shoulder_h])
        color("green")
            top_part();
    color("yellow")

        middle_tabss();

    translate([0, 0, bottom_h])
        color("blue")
            shoulder_part();

    color("Lime")
        millstone_retaining_tabs();

    color("orange")
        bottom_parts();

    color("Purple")
        millstone_holders();
}

module millstone_retainting_tab_cutouts() {
    translate([-4.5, -26.5, -0.05])
        union() {
            cube([9, 3, 5.5]);
            translate([0, 0, 5.45])
                cube([0.75, 3, 5.5]);
            translate([8.25, 0, 5.45])
                cube([0.75, 3, 5.5]);
        }

    translate([-4.5, 23.5, -0.05])
        union() {
            cube([9, 3, 5.5]);
            translate([0, 0, 5.45])
                cube([0.75, 3, 5.5]);
            translate([8.25, 0, 5.45])
                cube([0.75, 3, 5.5]);
        }
}

module millstone_cutouts_slits() {
    translate([-4.5, -26.5, -0.05])
        union() {
            cube([0.75, 4, bottom_h]);
            translate([8.25, 0, 0])
                cube([0.75, 4, bottom_h]);
        }

}
module top_cutouts() {
    module top_cutout_cube() {
        translate([23.5, -1.5, 7])
            cube([4, 3, 7.05]);
    }
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