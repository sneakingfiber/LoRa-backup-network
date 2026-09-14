// LoRa + ESP32 case - LID
// mates rim-to-rim with case_Lora_3D_3.scad (flipped 180 deg to close)

use <assets/Inter-ExtraBold.ttf>

$fn = 48;

/* ---------- outer dims ---------- */
L = 75;   // x
W = 70;   // y
H = 15;   // z

/* ---------- inner cavity ---------- */
// NOTE: walls are asymmetric - 2 mm at x=0 / y=0, 4 mm at x=L / y=W.
// origin moved 3 -> 2 but the size stayed 69 x 64. Set size to [71,66,21]
// if you want a uniform 2 mm wall all round.
cav_org  = [2,2,2];
cav_size = [69,64,21];

/* ---------- case-closing screws ---------- */
// positions must match the case bottom turrets
screw_pos   = [[3,3],[72,3],[72,67],[3,67]];
boss_d      = 6.0;   // trimmed flush by envelope() at the outer faces
screw_clear = 2.8;   // clearance for M3 (case bottom has the 2.5 tapping hole)
csk_d       = 6.2;   // countersink head dia, on the z=0 face (outer once flipped)
csk_h       = 1.8;

/* ---------- OLED 128x32 ---------- */
oled_org     = [7,33];    // island footprint corner
oled_island  = [31,31,7];
oled_pocket  = [29,29,8]; // module body pocket, inset 1 mm, from z=1
oled_win     = [13.5,25.5,4];
oled_win_off = [5.3,2.75]; // window offset from oled_org
oled_post_off   = 3;      // first post, offset from oled_org
oled_post_pitch = 25;
oled_post_d     = 4.4;  // 4.0 made the posts exactly tangent to the pocket
                        // walls (zero-width contact = non-manifold); 4.4 makes
                        // them bite 0.2 mm into the rim instead
oled_post_hole  = 2.5;
oled_post_top   = 5.5;  // post height above the lid floor
oled_floor_keep = 2;    // floor left solid under the posts (blind holes)
oled_post_pos = [ for(i=[0,1], j=[0,1])
    [oled_org[0]+oled_post_off+i*oled_post_pitch,
     oled_org[1]+oled_post_off+j*oled_post_pitch] ];

/* ---------- shell shaping ---------- */
corner_cut = 2.0;   // 45 deg vertical corner chamfer
top_cham   = 1.0;   // rim edge chamfer
bot_cham   = 1.0;   // outer face chamfer (print-friendly first layer)

/* ---------- engraving ---------- */
engrave_depth = 0.5;   // wall is only 2 mm on the y=0 side - keep it shallow
engrave_z     = 7.5;   // vertical centre on the side walls
flip_engrave  = true;  // lid flips 180 deg to close, so draw it upside down here

logo_h  = 9;           // meshtastic mark height (aspect 1.894 : 1 -> ~17 mm wide)
logo_x  = L/2;

text_str  = "sneakingfiber";
text_size = 7;
text_x    = L/2;

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

/* ---------- meshtastic mark ---------- */
// flattened from the official logo (assets/meshtastic_logo.svg,
// github.com/meshtastic/design). Normalised: height 1, centred on origin.
module meshtastic_2d(){
    polygon([[0.2975,0.2865],[-0.2382,-0.4990],[-0.3511,-0.4220],[0.2409,0.4462],[0.2442,0.4507],[0.2479,0.4549],[0.2519,0.4587],[0.2562,0.4620],[0.2608,0.4649],[0.2656,0.4674],[0.2706,0.4693],[0.2757,0.4707],[0.2809,0.4716],[0.2862,0.4720],[0.2914,0.4718],[0.2966,0.4711],[0.3018,0.4698],[0.3069,0.4680],[0.3117,0.4657],[0.3164,0.4629],[0.3209,0.4596],[0.3250,0.4559],[0.3289,0.4517],[0.3324,0.4471],[0.3355,0.4421],[0.3381,0.4368],[0.3403,0.4311],[0.3419,0.4252],[0.3430,0.4190],[0.3435,0.4126],[0.3434,0.4060],[0.3427,0.3993],[0.3412,0.3924],[0.3391,0.3855],[0.3362,0.3785],[0.3326,0.3715],[0.9472,-0.4237],[0.8347,-0.5000]]);
    polygon([[-0.8336,-0.5000],[-0.2045,0.4225],[-0.3181,0.5000],[-0.9472,-0.4225]]);
}

/* ---------- engraving placement ---------- */
// shape is drawn centred on the origin in 2D, then laid onto a side wall.
// centred extrusion straddles the wall face, so it bites engrave_depth in.
// the two walls face opposite ways, so the y=W one needs the extra 180.
module on_wall(px, pz, back=false){
    translate([px, back ? W : 0, pz])
        rotate([90, 0, back ? 180 : 0])
            rotate([0, 0, flip_engrave ? 180 : 0])
                linear_extrude(engrave_depth*2, center=true) children();
}

module engravings(){
    // meshtastic mark on the y=0 wall
    on_wall(logo_x, engrave_z)
        scale([logo_h,logo_h]) meshtastic_2d();

    // wordmark on the y=W wall
    on_wall(text_x, engrave_z, back=true)
        text(text_str, size=text_size, halign="center", valign="center",
             font="Inter:style=ExtraBold");
}

// cut LAST, from the whole assembly, so it goes through the floor too
module screw_holes(){
    for(p = screw_pos) translate([p[0],p[1],0]){
        translate([0,0,-1]) cylinder(h=H+2, d=screw_clear);
        translate([0,0,-0.01]) cylinder(h=csk_h, d1=csk_d, d2=screw_clear);
    }
}

/* ---------- OLED cut-outs ---------- */
// pocket + viewing window through the floor
module oled_cut(){
    translate([oled_org[0]+1, oled_org[1]+1, 1]) cube(oled_pocket);
    translate([oled_org[0]+oled_win_off[0],
               oled_org[1]+oled_win_off[1], -1]) cube(oled_win);
}

// solid posts, added back after the pocket is cut; drilled last
module oled_posts(){
    for(p = oled_post_pos)
        translate([p[0],p[1],0]) cylinder(h=oled_post_top, d=oled_post_d);
}

// blind: they start on top of the floor so they never break through
module oled_post_holes(){
    for(p = oled_post_pos)
        translate([p[0],p[1],oled_floor_keep])
            cylinder(h=oled_post_top-oled_floor_keep+1, d=oled_post_hole);
}

/* ---------- body ---------- */
module body(){
    union(){
        difference(){
            cube([L,W,H]);

            // cavity, minus the solid island that carries the OLED
            difference(){
                translate(cav_org) cube(cav_size);
                translate([oled_org[0],oled_org[1],0]) cube(oled_island);
            }

            oled_cut();
        }

        // screw bosses: full height, welded to the floor and flush with the rim
        for(p = screw_pos) translate([p[0],p[1],0]) cylinder(h=H, d=boss_d);

        oled_posts();
    }
}

/* ---------- final ---------- */
difference(){
    intersection(){
        body();
        envelope();
    }
    screw_holes();
    oled_post_holes();
    engravings();
}
