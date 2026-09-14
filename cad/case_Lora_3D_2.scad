//r = 3.175;
//n = 10;
//$fn = r * cos(pi/n); apotema
$fn = 32;
union(){
difference(){
    
    union(){
        ///////CASE WALLS
        //case (+ 3 mm walls)
        cube([75,70,20]); 
        }
        
    //case cavity
    translate([3,3,6]) cube([69,64,21]);
    
    //SMA connector cavity
    translate([-5,21.5,9]) rotate([0,90,0]) 
    cylinder(h = 11.5,d = 6.45 );
    
    //DX-LR02 cavity
   translate([3,4+3.5,3])cube([35,18,6]);
    
    
    //ESP32 cavity
    translate([0,0,1.5])
        union(){
    translate([69-28,3,2])cube([28,55,6]);
    //USB-C cavity
    hull(){
        translate([69-(28/2)+2.75,6,5]) rotate([90,0,0]) cylinder(h=7,d=10);
        translate([69-(28/2)-2.75,6,5]) rotate([90,0,0]) cylinder(h=7,d=10);
        }
    }
}
    
//case-closing-screws turrets
        difference(){
        translate([3,3,6]) cylinder(h=14,d=5);
            #translate([3,3,6])cylinder(h=20,d=2.5);  //screw hole
        }
        difference(){
        translate([72,3,6]) cylinder(h=14,d=5);
            #translate([72,3,6])cylinder(h=20,d=2.5);
            
        }
        difference(){
        translate([72,67,6]) cylinder(h=14,d=5);              
            #translate([72,67,6])cylinder(h=20,d=2.5);
        }
        
        difference(){
        translate([3,67,6]) cylinder(h=14,d=5);
            #translate([3,67,6])cylinder(h=20,d=2.5);
            }
       //esp32 screwholes
            difference(){
        translate([69-26,5,3])cube([3.5,3.5,3.5],center = true);
                #translate([69-26,5,5])cylinder(h=3,d=2.5,center = true);
            }
                        difference(){
        translate([69-2,5,3])cube([3.5,3.5,3.5],center = true);
                #translate([69-2,5,5])cylinder(h=3,d=2.5,center = true);
            }
                     difference(){
        translate([69-26,52,3])cube([3.5,3.5,3.5],center = true);
                #translate([69-26,52,5])cylinder(h=3,d=2.5,center = true);
            }
                     difference(){
        translate([69-2,52,3])cube([3.5,3.5,3.5],center = true);
                #translate([69-22,52,5])cylinder(h=3,d=2.5,center = true);
            }
        }
    