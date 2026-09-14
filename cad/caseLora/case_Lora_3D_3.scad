// LoRa + ESP32 case - exterior styling pass
// internals identical to case_Lora_3D_2.scad
$fn = 32;

/* ---------- outer dims ---------- */
L  = 75;   // x
W  = 70;   // y
H  = 20;   // z

/* ---------- decoration params ---------- */
corner_cut   = 2.0;   // 45 deg vertical corner chamfer
top_cham     = 1.0;   // top edge chamfer
bot_cham     = 1.0;   // bottom edge chamfer (print-friendly)

groove_z     = 13.0;  // accent band, above SMA (12.2) and USB (11.5)
groove_h     = 1.0;
groove_d     = 0.7;

flute_on     = true;
flute_z0     = 15.2;
flute_z1     = 18.6;
flute_dia    = 1.6;
flute_depth  = 0.7;
flute_pitch  = 6;
flute_y0     = 8;
flute_n      = 10;


label_on     = true;
label_txt    = "LoRa";
label_size   = 6;
label_z      = 9;
label_depth  = 0.6;

/* ---------- footprint with cut corners ---------- */
module foot2d(){
    polygon([[corner_cut,0],[L-corner_cut,0],
             [L,corner_cut],[L,W-corner_cut],
             [L-corner_cut,W],[corner_cut,W],
             [0,W-corner_cut],[0,corner_cut]]);
}

// convex envelope: cut corners + top/bottom edge chamfers
module envelope(){
    hull(){
        linear_extrude(0.01) offset(delta=-bot_cham) foot2d();
        translate([0,0,bot_cham]) linear_extrude(H-bot_cham-top_cham) foot2d();
        translate([0,0,H-0.01]) linear_extrude(0.01) offset(delta=-top_cham) foot2d();
    }
}

/* ---------- decoration cuts ---------- */
module accent_groove(){
    translate([0,0,groove_z])
    linear_extrude(groove_h)
        difference(){
            offset(delta=0.5) foot2d();
            offset(delta=-groove_d) foot2d();
        }
}

module flute(){                        // vertical capsule, rounded ends
    hull(){
        translate([0,0,flute_z0]) sphere(d=flute_dia);
        translate([0,0,flute_z1]) sphere(d=flute_dia);
    }
}

module flutes(){
    off = flute_depth - flute_dia/2;   // surface offset for wanted depth
    for(i=[0:flute_n-1]){
        y = flute_y0 + i*flute_pitch;
        translate([off,   y, 0]) flute();   // left wall  (x=0)
        translate([L-off, y, 0]) flute();   // right wall (x=L)
    }
}

module label(){                        // engraved, back wall y=W
    translate([L/2, W-label_depth, label_z]) rotate([-90,0,0])
        linear_extrude(label_depth*2)
            text(label_txt, size=label_size, halign="center",
                 valign="center", font="Liberation Sans:style=Bold");
}

module decorations(){
    accent_groove();
    if(flute_on) flutes();
    if(label_on) label();
}

/* ---------- body (unchanged internals) ---------- */
module body(){
union(){
difference(){

    union(){
        ///////CASE WALLS
        //case (+ 3 mm walls)
        cube([75,70,15]);
        }

    //case cavity
    translate([3,3,3]) cube([69,64,21]);
    /*
    //SMA connector cavity
    translate([-5,21.5,9]) rotate([0,90,0])
    cylinder(h = 11.5,d = 6.45 );
    /*
    //DX-LR02 cavity
   translate([3,4+3.5,3])cube([35,18,6]);

    /*
    //ESP32 cavity
    translate([0,0,1.5])
        union(){
    translate([69-28,3,2])cube([28,55,6]);
            /*
    //USB-C cavity
    hull(){
        translate([69-(28/2)+2.75,6,5]) rotate([90,0,0]) cylinder(h=7,d=10);
        translate([69-(28/2)-2.75,6,5]) rotate([90,0,0]) cylinder(h=7,d=10);
        }
    }*/
}

//case-closing-screws turrets
        
        difference(){
        translate([3,3,2]) cylinder(h=14,d=5);
            translate([3,3,2])cylinder(h=20,d=2.5);  //screw hole
        }
        difference(){
        translate([72,3,2]) cylinder(h=14,d=5);
            translate([72,3,2])cylinder(h=20,d=2.5);

        }
        difference(){
        translate([72,67,2]) cylinder(h=14,d=5);
            translate([72,67,2])cylinder(h=20,d=2.5);
        }

        difference(){
        translate([3,67,2]) cylinder(h=14,d=5);
            translate([3,67,2])cylinder(h=20,d=2.5);
            }
       /*
       //esp32 screwholes
            difference(){
        translate([69-26,5,3])cube([3.5,3.5,3.5],center = true);
                translate([69-26,5,5])cylinder(h=3,d=2.5,center = true);
            }
                        difference(){
        translate([69-2,5,3])cube([3.5,3.5,3.5],center = true);
                translate([69-2,5,5])cylinder(h=3,d=2.5,center = true);
            }
                     difference(){
        translate([69-26,52,3])cube([3.5,3.5,3.5],center = true);
                translate([69-26,52,5])cylinder(h=3,d=2.5,center = true);
            }
                     difference(){
        translate([69-2,52,3])cube([3.5,3.5,3.5],center = true);
                translate([69-2,52,5])cylinder(h=3,d=2.5,center = true);
            }*/
        }
}

/* ---------- final ---------- */
difference(){
    intersection(){
        body();
        envelope();
    }
    //decorations();
}
