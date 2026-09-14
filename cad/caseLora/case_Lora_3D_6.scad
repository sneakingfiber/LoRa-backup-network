// LoRa + ESP32 case - HANDHELD BAR revision
//   part = "bottom" | "lid" | "both" | "assembled"
//   OpenSCAD -D 'part="lid"' -o lid.stl cad/caseLora/case_Lora_3D_6.scad
//
// Different concept from _3/_4 (75x70 box) and _5 (63x60 box): the boards go
// end to end on one axis instead of side by side, so the case becomes a
// 101 x 45 x 24 bar held like a handheld radio. Antenna exits the nose, USB-C
// the tail, both on the long centreline.
//
// Footprint is an irregular octagon: 10 mm 45 deg cuts at the nose, 4 mm at the
// tail, so the shape points. Section is octagonal too - a 3 mm chamfer on each
// part's outer face plus a 0.8 mm chamfer at the rim, which opens a V-groove
// right at the seam. Chamfering the OUTER face is free: at floor level it has
// receded to 0.5 mm, so the thinnest wall is still 2.0 mm.
//
// Everything below the "components" heading is carried over unchanged from
// case_Lora_3D_2.scad; only the placement changed.

part = "both";          // "bottom" | "lid" | "both" | "assembled"
$fn  = 48;

/* ================= shell ================= */
wall    = 2.5;
floor_t = 2.5;
L = 101;                // x - nose at x=0, tail at x=L
W = 45;                 // y
H_bot = 13;
H_lid = 11;
gap   = 24;             // "both" preview separation on y

nose_cut = 10;          // 45 deg corner cut, antenna end
tail_cut = 4;           // 45 deg corner cut, USB end
out_cham = 3.0;         // chamfer on the outer face of each part
rim_cham = 0.8;         // chamfer at the rim -> 1.6 mm V-groove at the seam

belt_d  = 0.7;          // accent groove below the rim
belt_h  = 1.4;
belt_z  = 3.0;          // groove top, measured down from the rim

/* ---------- case-closing screws ----------
   6 of them: the bar is long and the lid is thin. They sit at y = 4 / W-4,
   clear of both boards (which start at y = 8.5), NOT in the corners - the
   10 mm nose cut leaves no corner to put one in. */
screw_x     = [12, 55, 97];
screw_y     = [4, W-4];
screw_pos   = [ for(x=screw_x, y=screw_y) [x,y] ];
boss_d      = 5.5;      // trimmed flush by envelope() where it meets a wall
tap_d       = 2.5;      // bottom: self-tapping for M3
screw_clear = 2.8;      // lid: through hole
csk_d       = 6.2;
csk_h       = 1.8;

/* ================= components ================= */
// ESP32 devkit, long axis on X, USB-C out the tail
esp     = [55,28];
esp_org = [43, (W-28)/2];       // y = 8.5
esp_hole_off   = [2,2];
esp_hole_pitch = [47,24];

// DX-LR02 433T22D, long axis on X, SMA out the nose.
// x = 6.5 is the minimum that clears the nose chamfer: the cavity's 45 deg
// edge is x + y >= nose_cut + wall*sqrt(2) = 13.54, and y starts at 8.5.
lora     = [35,18];
lora_org = [6.5, 8.5];

stand_h    = 2.5;       // board standoff height
pad_d      = 4.0;
pad_hole_d = 2.2;

// SMA through the nose. lora_org[1] + 14 puts it on the long centreline,
// same 14 mm offset from the module edge as case_Lora_3D_2.scad used.
sma_d = 6.45;
sma_y = lora_org[1] + 14;       // 22.5 = W/2
sma_z = 7;
collar_af = 14;         // octagonal antenna collar, across flats
collar_h  = 2.5;

// USB-C through the tail, on the ESP32 short edge
usb_y = esp_org[1] + esp[1]/2;  // 22.5 = W/2
usb_z = 8;
usb_d = 8.5;
usb_w = 5.5;

// diagonal grip flutes, rear half of both long walls
flute_on    = true;
flute_depth = 0.7;
flute_dia   = 1.8;
flute_len   = 7;
flute_tilt  = 25;       // degrees off vertical
flute_x0    = 62;
flute_pitch = 5;
flute_n     = 7;
flute_z     = 6;        // centre height

/* ---------- OLED 128x32, carried by the lid ---------- */
oled_island  = [31,31,7];
// x set so the WINDOW, not the island, lands on L/2 - the island is offset
// inside its own footprint by oled_win_off
oled_org     = [L/2 - (5.3 + 13.5/2), (W-31)/2];
oled_pocket  = [29,29,8];
oled_win     = [13.5,25.5,4];
oled_win_off = [5.3,2.75];
oled_win_flare = 1.2;   // 45 deg flare on the lid's outer face
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

// machined-look recesses flanking the window on the lid's outer face
lid_recess_on = true;
lid_recess_d  = 0.8;

/* ================= profile ================= */
module foot2d(){
    polygon([[nose_cut,0],[L-tail_cut,0],
             [L,tail_cut],[L,W-tail_cut],
             [L-tail_cut,W],[nose_cut,W],
             [0,W-nose_cut],[0,nose_cut]]);
}

// octagonal section: big chamfer on the outer face, small one at the rim
module envelope(h){
    hull(){
        linear_extrude(0.01) offset(delta=-out_cham) foot2d();
        translate([0,0,out_cham])  linear_extrude(0.01) foot2d();
        translate([0,0,h-rim_cham]) linear_extrude(0.01) foot2d();
        translate([0,0,h-0.01]) linear_extrude(0.01) offset(delta=-rim_cham) foot2d();
    }
}

module cavity(h){
    translate([0,0,floor_t])
        linear_extrude(h) offset(delta=-wall) foot2d();
}

module belt_groove(h){
    translate([0,0,h-belt_z])
        linear_extrude(belt_h)
            difference(){
                offset(delta=1) foot2d();
                offset(delta=-belt_d) foot2d();
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
    translate([-collar_h-1,sma_y,sma_z]) rotate([0,90,0])
        cylinder(h=wall+collar_h+2, d=sma_d);
}

// faceted collar, unioned AFTER the envelope intersection so it can stand
// proud of the nose face instead of being trimmed flush
module sma_collar(){
    translate([-collar_h,sma_y,sma_z]) rotate([0,90,0])
        cylinder(h=collar_h+wall, d=collar_af/cos(180/8), $fn=8);
}

module usb_cut(){
    translate([L-wall-1,usb_y,usb_z]) rotate([0,90,0])
        hull(){
            translate([0, usb_w/2,0]) cylinder(h=wall+2, d=usb_d);
            translate([0,-usb_w/2,0]) cylinder(h=wall+2, d=usb_d);
        }
}

// capsule tilted inside the X-Z plane, i.e. ALONG the wall face. Tilting it
// about any other axis swings it into the wall and drills straight through.
module flute(){
    rotate([0,flute_tilt,0]) hull(){
        translate([0,0,-flute_len/2]) sphere(d=flute_dia);
        translate([0,0, flute_len/2]) sphere(d=flute_dia);
    }
}

module flutes(){
    off = flute_depth - flute_dia/2;   // surface offset for the wanted depth
    for(i=[0:flute_n-1]){
        x = flute_x0 + i*flute_pitch;
        translate([x, off,   flute_z]) flute();
        translate([x, W-off, flute_z]) flute();
    }
}

module bottom(){
    difference(){
        union(){
            intersection(){
                union(){
                    difference(){ linear_extrude(H_bot) foot2d(); cavity(H_bot); }
                    for(p=screw_pos) translate([p[0],p[1],0]) cylinder(h=H_bot, d=boss_d);
                    esp_hole_pos() cylinder(h=floor_t+stand_h, d=pad_d);
                    lora_pad_pos() cylinder(h=floor_t+stand_h, d=pad_d);
                }
                envelope(H_bot);
            }
            sma_collar();
        }
        sma_cut();
        usb_cut();
        belt_groove(H_bot);
        if(flute_on) flutes();
        // drilled last, so turrets and pads are solid before cutting
        for(p=screw_pos) translate([p[0],p[1],floor_t]) cylinder(h=H_bot, d=tap_d);
        esp_hole_pos() translate([0,0,floor_t]) cylinder(h=stand_h+1, d=pad_hole_d);
    }
}

/* ================= lid ================= */
module oled_cut(){
    translate([oled_org[0]+1, oled_org[1]+1, 1]) cube(oled_pocket);

    wo = [oled_org[0]+oled_win_off[0], oled_org[1]+oled_win_off[1]];
    translate([wo[0],wo[1],-1]) cube([oled_win[0],oled_win[1],oled_win[2]+1]);
    // flared bezel on the outer face
    translate([wo[0]+oled_win[0]/2, wo[1]+oled_win[1]/2, 0])
        hull(){
            translate([0,0,-0.01]) linear_extrude(0.01)
                offset(delta=oled_win_flare) square([oled_win[0],oled_win[1]], center=true);
            translate([0,0,oled_win_flare]) linear_extrude(0.01)
                square([oled_win[0],oled_win[1]], center=true);
        }
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

// two tapered pockets flanking the window, 0.8 deep into a 2.5 floor
module lid_recesses(){
    for(m=[0,1])
        translate([0,0,-0.01]) linear_extrude(lid_recess_d)
            mirror([m,0,0]) translate([m ? -L : 0, 0])
                polygon([[13,10],[30,14],[30,W-14],[13,W-10]]);
}

module lid(){
    difference(){
        intersection(){
            union(){
                difference(){
                    linear_extrude(H_lid) foot2d();
                    // cavity, minus the solid island that carries the OLED
                    difference(){
                        cavity(H_lid);
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
        belt_groove(H_lid);
        if(lid_recess_on) lid_recesses();
    }
}

/* ================= output ================= */
if(part=="bottom") bottom();
else if(part=="lid") lid();
else if(part=="assembled"){
    bottom();
    // flip about X: the lid's rim (z=H_lid) lands on the bottom's rim (z=H_bot).
    // the profile is symmetric about y=W/2, so the y flip costs nothing.
    translate([0,W,H_bot+H_lid]) rotate([180,0,0]) lid();
}
else { bottom(); translate([0,W+gap,0]) lid(); }
