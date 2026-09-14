// LoRa + ESP32 case - COMPACT revision
// One file, both parts:   part = "bottom" | "lid" | "both"
//   OpenSCAD -D 'part="lid"' -o lid.csg cad/caseLora/case_Lora_3D_5.scad
//
// Shrunk from 75 x 70 x 30 (case_Lora_3D_3 + _4) to 63 x 60 x 24.
// Same component placeholders, repacked:
//   - ESP32 rotated 90 deg: long axis on X, so its USB-C exits the x=L wall
//     instead of y=0, which frees the whole y=0..W side for the LoRa module.
//   - LoRa module stacked behind it on Y instead of beside it on X, so the
//     footprint is max(55,35) wide, not 28+35 wide.
//   - SMA stays on x=0, USB-C on x=L -> connectors on opposite walls.
// Corner screw bosses are kept at inset 3 (same scheme as the old parts) and
// both boards start at y=6, past the 2.75 boss radius, so nothing collides.

part = "both";          // "bottom" | "lid" | "both"
$fn  = 48;

/* ================= shared ================= */
wall    = 2.5;
floor_t = 2.5;
L = 63;                 // x
W = 60;                 // y
H_bot = 13;             // bottom height
H_lid = 11;             // lid height
gap   = 30;             // "both" preview separation on x

corner_cut = 2.0;       // 45 deg vertical corner chamfer
top_cham   = 1.0;
bot_cham   = 1.0;

// case-closing screws - bottom turrets and lid bosses share these
screw_pos   = [[3,3],[L-3,3],[L-3,W-3],[3,W-3]];
boss_d      = 5.5;
tap_d       = 2.5;      // bottom: self-tapping for M3
screw_clear = 2.8;      // lid: through hole
csk_d       = 6.2;
csk_h       = 1.8;

/* ================= components ================= */
// ESP32 devkit, long axis on X
esp     = [55,28];
esp_org = [4,6];        // y=6 clears the y=3 bosses (3 + 2.75)
esp_h   = 6;            // clearance above its standoffs
esp_hole_off   = [2,2]; // mount holes, inset from board corner
esp_hole_pitch = [47,24];

// DX-LR02 433T22D
lora     = [35,18];
lora_org = [4,36];

stand_h = 2.5;          // board standoff height
pad_d   = 4.0;
pad_hole_d = 2.2;

// SMA barrel through the x=0 wall, on the LoRa module edge
sma_d = 6.45;
sma_y = lora_org[1] + 14;
sma_z = 7;

// USB-C through the x=L wall, on the ESP32 short edge
usb_y = esp_org[1] + esp[1]/2;
usb_z = 8;
usb_d = 8.5;            // slot height
usb_w = 5.5;            // slot width (hull separation)

/* ---------- OLED 128x32, carried by the lid ---------- */
oled_island  = [31,31,7];
oled_org     = [(L-oled_island[0])/2, (W-oled_island[1])/2];
oled_pocket  = [29,29,8];
oled_win     = [13.5,25.5,4];
oled_win_off = [5.3,2.75];
oled_post_off   = 3;
oled_post_pitch = 25;
oled_post_d     = 4.4;  // 4.0 is exactly tangent to the pocket wall
                        // (zero-width contact = non-manifold)
oled_post_hole  = 2.5;
oled_post_top   = 5.5;
oled_floor_keep = 2;    // floor left solid under the posts (blind holes)
oled_post_pos = [ for(i=[0,1], j=[0,1])
    [oled_org[0]+oled_post_off+i*oled_post_pitch,
     oled_org[1]+oled_post_off+j*oled_post_pitch] ];

/* ================= shell ================= */
module foot2d(){
    polygon([[corner_cut,0],[L-corner_cut,0],
             [L,corner_cut],[L,W-corner_cut],
             [L-corner_cut,W],[corner_cut,W],
             [0,W-corner_cut],[0,corner_cut]]);
}

module envelope(h){
    hull(){
        linear_extrude(0.01) offset(delta=-bot_cham) foot2d();
        translate([0,0,bot_cham]) linear_extrude(h-bot_cham-top_cham) foot2d();
        translate([0,0,h-0.01]) linear_extrude(0.01) offset(delta=-top_cham) foot2d();
    }
}

/* ================= bottom ================= */
module esp_hole_pos(){
    for(i=[0,1], j=[0,1])
        translate([esp_org[0]+esp_hole_off[0]+i*esp_hole_pitch[0],
                   esp_org[1]+esp_hole_off[1]+j*esp_hole_pitch[1],0]) children();
}

module lora_pad_pos(){
    for(i=[0,1], j=[0,1])
        translate([lora_org[0]+2+i*(lora[0]-4),
                   lora_org[1]+2+j*(lora[1]-4),0]) children();
}

module sma_cut(){
    translate([-1,sma_y,sma_z]) rotate([0,90,0])
        cylinder(h=wall+2, d=sma_d);
}

module usb_cut(){
    translate([L-wall-1,usb_y,usb_z]) rotate([0,90,0])
        hull(){
            translate([0, usb_w/2,0]) cylinder(h=wall+2, d=usb_d);
            translate([0,-usb_w/2,0]) cylinder(h=wall+2, d=usb_d);
        }
}

module bottom(){
    difference(){
        intersection(){
            union(){
                difference(){
                    cube([L,W,H_bot]);
                    translate([wall,wall,floor_t])
                        cube([L-2*wall, W-2*wall, H_bot]);
                    sma_cut();
                    usb_cut();
                }
                // screw turrets, full height, welded to floor and wall
                for(p=screw_pos) translate([p[0],p[1],0]) cylinder(h=H_bot, d=boss_d);
                // board standoffs
                esp_hole_pos()  cylinder(h=floor_t+stand_h, d=pad_d);
                lora_pad_pos()  cylinder(h=floor_t+stand_h, d=pad_d);
            }
            envelope(H_bot);
        }
        // drilled last so the turrets/pads are solid before cutting
        for(p=screw_pos) translate([p[0],p[1],floor_t]) cylinder(h=H_bot, d=tap_d);
        esp_hole_pos() translate([0,0,floor_t])
            cylinder(h=stand_h+1, d=pad_hole_d);
    }
}

/* ================= lid ================= */
module oled_cut(){
    translate([oled_org[0]+1, oled_org[1]+1, 1]) cube(oled_pocket);
    translate([oled_org[0]+oled_win_off[0],
               oled_org[1]+oled_win_off[1], -1]) cube(oled_win);
}

module oled_posts(){
    for(p=oled_post_pos) translate([p[0],p[1],0]) cylinder(h=oled_post_top, d=oled_post_d);
}

module oled_post_holes(){
    for(p=oled_post_pos) translate([p[0],p[1],oled_floor_keep])
        cylinder(h=oled_post_top-oled_floor_keep+1, d=oled_post_hole);
}

module lid_screw_holes(){
    for(p=screw_pos) translate([p[0],p[1],0]){
        translate([0,0,-1]) cylinder(h=H_lid+2, d=screw_clear);
        translate([0,0,-0.01]) cylinder(h=csk_h, d1=csk_d, d2=screw_clear);
    }
}

module lid(){
    difference(){
        intersection(){
            union(){
                difference(){
                    cube([L,W,H_lid]);
                    // cavity, minus the solid island that carries the OLED
                    difference(){
                        translate([wall,wall,floor_t])
                            cube([L-2*wall, W-2*wall, H_lid]);
                        translate([oled_org[0],oled_org[1],0]) cube(oled_island);
                    }
                    oled_cut();
                }
                for(p=screw_pos) translate([p[0],p[1],0]) cylinder(h=H_lid, d=boss_d);
                oled_posts();
            }
            envelope(H_lid);
        }
        lid_screw_holes();
        oled_post_holes();
    }
}

/* ================= output ================= */
if(part=="bottom") bottom();
else if(part=="lid") lid();
else { bottom(); translate([L+gap,0,0]) lid(); }
