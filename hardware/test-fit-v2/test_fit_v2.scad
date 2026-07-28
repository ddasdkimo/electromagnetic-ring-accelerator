// ============================================================
// ERA v2 試配塊（Banked-Square 4 方案；派工 2026-07-28）
// 剖面函式移植自 era_concept_v2.scad（profile/rt 原式）
//
// 重要修正（回報 ERA 核定）：隧道孔心高不能等於球心 8.218——
//   球在 Ø11.2 孔內躺孔底滾，孔心 8.218 → 球心跌 0.85。
//   本檔採 BORE_Z = BALL_Z + (孔徑-球徑)/2 = 9.068，
//   孔底 3.468 = V 槽滾動面 → 全程球心 8.218 恆定（真零落差）。
// 另：法蘭 Ø22 低於軌道底板基準 1.93mm → 試配塊底板局部加厚 3
//   （正式件需同樣處理：局部加厚或開法蘭沉槽）
// ============================================================
part = "curve"; // curve | bobbin | tunnel

$fn = 128;

BALL_D  = 9.5;
BASE_Z  = 3;
BALL_Z  = BASE_Z + 5.218;      // 8.218
BANK    = 20;
R_C     = 85;
BOB_ID  = 11.2; BOB_WALL = 0.8; BOB_OD = BOB_ID+2*BOB_WALL;  // 12.8
BOB_LEN = 30; FLANGE_D = 22; FLANGE_T = 2;
BORE_Z  = BALL_Z + (BOB_ID-BALL_D)/2;   // 9.068（見上）
IR_D    = 3.5; IR_Z = 8;

NSEG = 30;   // 漸變段 15mm 分 30 片（0.5mm/片，比概念圖細一倍）

// ---- 原式移植 ----
function rt(p, phi) = [ p[0]*cos(phi) - (p[1]-BALL_Z)*sin(phi),
                        BALL_Z + p[0]*sin(phi) + (p[1]-BALL_Z)*cos(phi) ];
module profile(t) {
  phi = BANK * t;
  a = rt([ 6.5, BASE_Z+5], phi);
  b = rt([ 1.5, BASE_Z  ], phi);
  c = rt([-1.5, BASE_Z  ], phi);
  d = rt([-6.5, BASE_Z+5], phi);
  polygon([[-10,0], [10,0], [10,13], [a[0],13], a, b, c, d, [d[0],9], [-10,9]]);
}

// ============================================================
// (1) 彎道試配：直線 40（含漸變 15）＋ R85 弧 45°
//     直線沿 +y；y25..40 漸變 t 0→1；彎道左轉（中心 (-85,40)）
// ============================================================
module curve_test() {
    // 直線段 t=0（y 0..25）
    rotate([90,0,0]) translate([0,0,-25]) linear_extrude(25.01) profile(0);
    // 漸變段（y 25..40）
    for (i=[0:NSEG-1]) {
        t = i/(NSEG-1);
        rotate([90,0,0]) translate([0,0,-(25+(i+1)*15/NSEG)])
            linear_extrude(15/NSEG+0.02) profile(t);
    }
    // 彎道 45° t=1
    translate([-R_C, 40, 0]) rotate_extrude(angle=45, $fn=200)
        translate([R_C, 0]) profile(1);
}

// ============================================================
// (2) bobbin 薄壁樣（立印）
// ============================================================
module bobbin() {
    difference() {
        union() {
            cylinder(d=BOB_OD, h=BOB_LEN);
            for (z=[0, BOB_LEN-FLANGE_T]) translate([0,0,z]) cylinder(d=FLANGE_D, h=FLANGE_T);
        }
        translate([0,0,-1]) cylinder(d=BOB_ID, h=BOB_LEN+2);
        // 出線孔（兩法蘭）
        for (z=[FLANGE_T/2, BOB_LEN-FLANGE_T/2])
            translate([BOB_OD/2+2.5, 0, z]) cylinder(d=1.6, h=FLANGE_T+2, center=true);
        // D 形法蘭：下緣截平於軸心下 6.57（= 底板基準下 0.5，膜厚問題根治）
        translate([-(FLANGE_D/2+1), -6.57-FLANGE_D, -1]) cube([FLANGE_D+2, FLANGE_D, BOB_LEN+2]);
    }
}

// ============================================================
// (3) 隧道段試配：直線軌 74 + 中央 bobbin 巢座 + IR 孔
//     底板整體 +3 加厚（法蘭 Ø22 需沉入基準面下 1.93）
//     驗證：球 V 槽 → 隧道孔底 → V 槽全程球心同高
// ============================================================
module tunnel_test() {
    difference() {
        union() {
            // 加厚底 3 + 軌道剖面（整體抬 3）
            translate([-10, -37, 0]) cube([20, 74, 3]);
            translate([0,0,3]) rotate([90,0,0]) translate([0,0,-37]) linear_extrude(74) profile(0);
            // bobbin 巢座肋 ×2（在法蘭內側 ±11，U 巢 Ø12.9）
            for (sy=[-11,11-4]) translate([-10, sy, 0]) cube([20, 4, 3+BORE_Z]);
        }
        // 隧道包絡：Ø13.4 沿 y 貫通中央 38（含法蘭 34 +餘裕）
        translate([0, 0, 3+BORE_Z]) rotate([90,0,0]) cylinder(d=13.4, h=38, center=true);
        // 巢座肋開 U 巢（Ø12.9 貼管）
        for (sy=[-11.5, 11.5]) translate([0, sy, 3+BORE_Z])
            rotate([90,0,0]) cylinder(d=BOB_OD+0.3, h=5, center=true);
        // 法蘭淺沉槽（D 形法蘭只低於基準 0.5 → 槽深到基準下 0.8，底膜厚 5.2）
        for (sy=[-15+FLANGE_T/2+0.1, 15-FLANGE_T/2-0.1]) translate([-12, sy-(FLANGE_T+0.7)/2, 3+3-0.8])
            cube([24, FLANGE_T+0.7, 12]);
        // 兩側牆在隧道區開窗（放線圈外徑 ~20.8）
        translate([-11, -12, 3+6]) cube([22, 24, 12]);
        // IR：牆上 Ø3.5 橫向對穿（z = 3+IR_Z）＋外側 x±13 直立管座
        translate([-16, -22, 3+IR_Z]) rotate([0,90,0]) cylinder(d=IR_D, h=32);
        for (sx=[-13,13]) translate([sx, -22, -1]) cylinder(d=IR_D, h=3+IR_Z+1+1.75);
    }
    // IR 管座外擴底板
    difference() {
        translate([-16, -26, 0]) cube([32, 8, 3]);
        for (sx=[-13,13]) translate([sx, -22, -1]) cylinder(d=IR_D, h=6);
        translate([-16, -26, 0]) cube([0,0,0]);
    }
}

if (part=="curve")  curve_test();
if (part=="bobbin") bobbin();
if (part=="tunnel") tunnel_test();
