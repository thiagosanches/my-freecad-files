$fn = 50;

module symmetricHoles(width, depth, holeDiameter, holeHeight) {
    holeDistance=75;
   
    translate([-75, 26.50, holeHeight]) {
        cylinder(d = holeDiameter, h = 20, center = true);
        
        hull() {
            translate([0, holeDiameter/2, 0])
            cylinder(d = 4.2, h = 20, center = true);

            translate([0, holeDiameter/2 + 13, 0])
            cylinder(d = 4.2, h = 20, center = true);
        }
    }
    
   
    translate([75, 26.50, holeHeight]) {
        cylinder(d = holeDiameter, h = 20, center = true);
        
        hull() {
            translate([-holeDiameter/2, 0, 0])
                cylinder(d =4.2, h = 20, center = true);
            
            translate([-holeDiameter/2 - 13, 0, 0])
                cylinder(d = 4.2, h = 20, center = true);
            
        }
    }
}

module roundedCube(width, depth, height, radius) {
    linear_extrude(height, center = true)
    offset(r = radius)
    offset(r = -radius)
    square([width - radius*2, depth - radius*2], center = true);
}

module bottomCutout(width, depth, height, wall_thickness = 2) {
    translate([0, 0, -height/2])
    cube([width - wall_thickness*2, 
          depth - wall_thickness*2, 
          height], center = true);
}


difference() {
    roundedCube(206, 123, 8, 3);  // 3mm radius corners
    symmetricHoles(40, 0, 23, 0);
    
    translate([0,0,-4])
        roundedCube(206-3, 123-3, 8, 3);  // 3mm radius corners
    
    rotate([0,0,-90])
        translate([26.50-80,-75+5, 2])  // x, y, z position   
            linear_extrude(5)
                text("OFF", size = 6);
    
    rotate([0,0,-90])
        translate([26.50-80,(75-25), 2])  // x, y, z position   
            linear_extrude(50)
                text("OFF", size = 6);   
}
