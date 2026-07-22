// ============================================================
// 電磁環形加速器 試配塊（派工 @ERA 2026-07-22）
// 規格：鋼球 Ø12.7、中心圓 Ø240、bobbin ID14.5/壁0.8/C形、
//       繞線層 4 → 法蘭 Ø26、IR Ø3 對射孔、PETG
// 幾何核心：開放段球騎 45° 雙軌（球心高 9.98）；隧道段球騎
//   bobbin 孔底 → 孔心 10.88 時球心同高（過渡零落差）
// ============================================================
part = "plate"; // bobbin_sample | track_sample | plate

$fn = 128;

ball_d   = 12.7;
r_track  = 120;      // 軌道中心半徑（正式件 Ø240）
bob_id   = 14.5;
bob_wall = 0.8;
bob_len  = 24;
flange_d = 26;       // 繞線層 4：16.1+2*4=24.1 → 26 留裕
slot_w   = 6;        // C 形底縫
ir_d     = 3.0;
ball_c_h = 9.98;     // 球心高（軌道底板頂 z3 + 6.98）
bore_c_h = 10.88;    // 隧道孔心高

// ---------- bobbin 試樣（立印） ----------
module bobbin_sample() {
    difference() {
        union() {
            cylinder(d=bob_id+2*bob_wall, h=bob_len);
            for (z=[0, bob_len-1.6]) translate([0,0,z]) cylinder(d=flange_d, h=1.6);
        }
        translate([0,0,-1]) cylinder(d=bob_id, h=bob_len+2);
        // C 形底縫（使用時朝下；立印時是側縫）
        translate([-slot_w/2, -flange_d/2-1, -1]) cube([slot_w, flange_d/2+1, bob_len+2]);
        // 出線孔（兩法蘭各一）
        for (z=[0.8, bob_len-0.8]) translate([bob_id/2+bob_wall/2+2, 0, z-0.8])
            rotate([0,0,20]) translate([0,0,0]) cylinder(d=1.6, h=1.7);
    }
}

// ---------- 軌道 U 槽剖面（正式件同款） ----------
// 底板 z0..3；V 軌：平底寬4、45° 斜軌到 z8/|x|7；內牆到 z10、外牆到 z17；牆厚 2.5
module track_profile() {
    polygon([
        [-9.5, 0],[9.5, 0],[9.5, 17],[7, 17],[7, 8],[2, 3],
        [-2, 3],[-7, 8],[-7, 10],[-9.5, 10]
    ]);
}
// 30° 弧段試樣 @r120 ＋ IR 孔 3 組
module track_sample() {
    difference() {
        rotate([0,0,-15]) rotate_extrude(angle=30)
            translate([r_track, 0]) track_profile();
        // IR Ø3 對射孔（z9 略低於球心 9.98，貫穿內外牆；3 組 @ -10/0/+10°）
        for (a=[-10,0,10]) rotate([0,0,a])
            translate([105, 0, 9]) rotate([0,90,0]) cylinder(d=ir_d, h=30);
    }
}

module plate() {
    translate([0, 20, 0]) bobbin_sample();
    translate([-r_track+30, -25, 0]) track_sample();
}

if (part=="bobbin_sample") bobbin_sample();
if (part=="track_sample")  translate([-r_track,0,0]) track_sample();
if (part=="plate")         plate();
