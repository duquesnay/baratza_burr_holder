$fa = 0.1;
$fs = 0.4;

//height (thickness) of 3 side tabs
tab_mid_h = 0.8; //[0.5:0.1:2]

outer_dia = 51.6; // [51:0.05:53]
bottom_thickness = 1.5; // [1:0.1:2]

middle_h = 2;
bottom_h = 14;

side_holder_length = 1.2; // [1:0.1:2]

cutouts = "slits"; // ["slits", "original"]
debug_visualize_cutouts = 0; // [0, 1]

// https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/Primitive_Solids
module prism(l, w, h){
   polyhedron(
    points=[[0,0,0], [l,0,0], [l,w,0], [0,w,0], [0,w,h], [l,w,h]],
    faces=[[0,1,2,3],[5,4,3,2],[0,4,5,1],[0,3,4],[5,2,1]]);
}


module beveled_tip(dimensions, initial_angle) {
    width = dimensions[0];
    depth = dimensions[1];
    height = dimensions[2];
    
    bevel_angle=90-initial_angle;
    extra_height = depth * tan(initial_angle);  // Extra height needed based on angle and depth
    bevel_length = sqrt(width^2+height^2);  // Length needed to span depth in angled position
    bevel_height = extra_height * cos(initial_angle);
    
    union() {
        // Bevel
        difference() {
            // Add calculated extra height b
        // Original cube
            cube([width,depth,height+extra_height]);            
            // Move to right corner and create cutting piece
            translate([0,depth,height])
            rotate([(bevel_angle),0,0])
            cube([width,bevel_height,bevel_length]);  
        }
    }
}


module upper_tabs() {
    union() {
        rotate([0,0,45])
        translate([-2,-26,0])
        union() {
            translate([1,1,0])
            cube([2,3,2]);
            cube([4,2,5]);
            translate([0,0,3.5])
            rotate([45,0,0])
            beveled_tip([4,2,3],45);
        }
        
        rotate([0,0,225])
        translate([-2,-26,0])
        union() {
            translate([1,1,0])
            cube([2,3,2]);
            cube([4,2,5]);
            translate([0,0,3.5])
            rotate([45,0,0])
            beveled_tip([4,2,3],45);
        }
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