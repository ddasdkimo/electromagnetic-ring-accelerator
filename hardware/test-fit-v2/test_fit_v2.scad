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
part = "combo"; // combo | bobbin | joint_a | joint_b | ir

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
Z_CUT   = 2.5;   // D形法蘭截平面的絕對高（基準3-0.5）。繞線鬆脫備案：改1.5
                 // （無擋線角 94.2°→80.8°、隧道底膜 5.2→4.2；下限≈0.12）
FL_FLAT = BORE_Z - Z_CUT;   // 截平距 bobbin 軸心 6.568

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
    translate([-R_C, 40, 0]) rotate_extrude(angle=45, $fn=400)
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
        // D 形法蘭：下緣截平於軸心下 FL_FLAT（膜厚問題根治；擋線靠張力非法蘭——ERA 核定）
        translate([-(FLANGE_D/2+1), -FL_FLAT-FLANGE_D, -1]) cube([FLANGE_D+2, FLANGE_D, BOB_LEN+2]);
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
        // 法蘭淺沉槽（槽底 = Z_CUT-0.3 餘裕；Z_CUT=2.5 時底膜 5.2、1.5 時 4.2）
        for (sy=[-15+FLANGE_T/2+0.1, 15-FLANGE_T/2-0.1]) translate([-12, sy-(FLANGE_T+0.7)/2, 3+Z_CUT-0.3])
            cube([24, FLANGE_T+0.7, 14]);
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


// ============================================================
// (合併版) combo：彎道45°→漸變15→直線60（含隧道巢座+IR）一體件
// 基準統一：底板全周 6（=正式件定案），球心 11.218、孔心 12.068
// 理由（ERA 建議核定）：正式件一體無接縫，「過渡零落差」不能用
// 拼接驗——接縫誤差會污染核心驗證項。bobbin 維持獨立（繞線後裝）。
// ============================================================
module combo_test() {
    difference() {
        union() {
            // 加厚底（直線+漸變）
            translate([-10, 0, 0]) cube([20, 75, 3]);
            // 直線 t=0（y 0..60）
            translate([0,0,3]) rotate([90,0,0]) translate([0,0,-60]) linear_extrude(60.01) profile(0);
            // 漸變 y60..75
            for (i=[0:NSEG-1]) {
                t = i/(NSEG-1);
                translate([0,0,3]) rotate([90,0,0]) translate([0,0,-(60+(i+1)*15/NSEG)])
                    linear_extrude(15/NSEG+0.02) profile(t);
            }
            // 彎道 45°（含自己的加厚底）
            translate([-R_C, 75, 0]) rotate_extrude(angle=45, $fn=400) union() {
                translate([R_C, 3]) profile(1);
                translate([R_C-10, 0]) square([20, 3.01]);
            }
            // 隧道座（v3 共用：法蘭 D 槽定位）
            tun_add(30);
            // IR 管座翼板（y 6..14）
            translate([-16, 6, 0]) cube([32, 8, 3]);
        }
        tun_cut(30);
        // IR：牆上 Ø3.5 橫穿（y=10, z=基準6+5=11）＋ x±13 直立管座
        translate([-16, 10, 3+IR_Z]) rotate([0,90,0]) cylinder(d=IR_D, h=32);
        for (sx=[-13,13]) translate([sx, 10, -1]) cylinder(d=IR_D, h=3+IR_Z+2.75);
    }
}
if (part=="combo") combo_test();


// ============================================================
// 接縫試配對（David 需求 2026-07-31：軌道分件卡榫）
// 概念：正式件切 4 個 L 形角件，接縫全部落在「線圈隧道正中央」——
// 球在隧道內騎 bobbin 內孔（單一件），全程摸不到軌道接縫。
// 接合 = 底部燕尾搭接舌（z0..3、план燕尾、垂直落入）＋bobbin 本身兼對位銷。
// joint_a + joint_b 組起來 = 一段帶接縫的隧道直線段，供實測驗證。
// ============================================================
DT_NECK=10; DT_HEAD=16; DT_LEN=9; DT_CL=0.4;   // 燕尾（FDM 鐵律間隙）

// ---- 隧道座共用（v3：線圈 Ø20.8 有位、法蘭 D 槽定位，繞線區零遮擋）----
CRADLE_T = 2.7; COIL_OD = 20.8;
module tun_add(yc) {   // 法蘭座板 ×2（@ yc±14）
    for (sf=[-1,1]) translate([-10, yc+sf*14-CRADLE_T/2, 0]) cube([20, CRADLE_T, 13]);
}
module tun_cut(yc) {
    // 線圈包絡：長度須蓋滿繞線區 26（+0.2/端），否則線圈端撞座板（法蘭讓位已不再兼差挖這裡）
    translate([0, yc, 3+BORE_Z]) rotate([90,0,0]) cylinder(d=COIL_OD+0.8, h=26.4, center=true);
    // 光管讓位：長度＝bobbin 光管 30 +0.3/端。**切勿放長**——多切一段就是一段
    // 「V 槽沒了、bore 還沒開始」的無支撐區，球會在隧道進出口跌落
    // （實測：舊值 h=38 兩端各留 4mm 空檔 → 球心掉到 10.776，−0.44mm）
    translate([0, yc, 3+BORE_Z]) rotate([90,0,0]) cylinder(d=13.4, h=BOB_LEN+0.6, center=true);
    // 法蘭 D 座槽：垂直落入通道（弦寬+0.3/側）＋圓弧讓位；D 平面落 z5.5 = 基準
    for (sf=[-1,1]) {
        translate([-9.12, yc+sf*14-(CRADLE_T+0.7)/2, 3+Z_CUT]) cube([18.24, CRADLE_T+0.7, 20]);
        // 圓弧讓位只切基準面以上：法蘭 D 面就落在 z=3+Z_CUT，底下不必讓
        // （切成整圓會把座板根部底膜啃到 0.75mm——上次回報 ERA 的 5.2mm 是錯的）
        intersection() {
            translate([0, yc+sf*14, 3+BORE_Z]) rotate([90,0,0])
                cylinder(d=FLANGE_D+0.6, h=CRADLE_T+0.7, center=true);
            translate([-15, yc+sf*14-3, 3+Z_CUT]) cube([30, 6, 20]);
        }
    }
    translate([-11, yc-12, 3+6]) cube([22, 24, 12]);                                          // 側牆開窗
}


module joint_straight() {   // 完整 60 直線含隧道特徵（接縫將落 y=30）
    difference() {
        union() {
            translate([-10, 0, 0]) cube([20, 60, 3]);
            translate([0,0,3]) rotate([90,0,0]) translate([0,0,-60]) linear_extrude(60.01) profile(0);
            tun_add(30);
        }
        tun_cut(30);
    }
}
module dovetail_plan(cl=0) {   // 平面燕尾（+y 指向）
    polygon([[-DT_NECK/2-cl, -1],[DT_NECK/2+cl, -1],
             [DT_NECK/2+cl, 0.01],[DT_HEAD/2+cl, DT_LEN+cl],
             [-DT_HEAD/2-cl, DT_LEN+cl],[-DT_NECK/2-cl, 0.01]]);
}
module joint_a() {   // y 0..30 ＋ 底部燕尾舌（伸入 B；舌需同受線圈包絡刀）
    difference() {
        union() {
            intersection() { joint_straight(); translate([-11,-1,-1]) cube([22, 31, 30]); }
            translate([0, 30, 0]) linear_extrude(3) dovetail_plan(0);
        }
        tun_cut(30);
    }
}
module joint_b() {   // y 30..60 － 底部燕尾槽
    difference() {
        intersection() { joint_straight(); translate([-11, 30, -1]) cube([22, 31, 30]); }
        translate([0, 30, -1]) linear_extrude(5) dovetail_plan(DT_CL);
    }
}
if (part=="joint_a") joint_a();
if (part=="joint_b") joint_b();


// ============================================================
// IR 水平夾座（ERA 2026-07-31 核定：感測方案不變，5 對對射、
// 光路水平橫穿、束高 z=3+IR_Z=11＝球心 11.218 略下方）
// 舊做法「垂直插孔 + 水平光路」裝不了——3mm 圓柱管的光軸就是管軸。
// 改：元件躺進水平 U 槽，從上方壓入，槽口收窄 CLIP_W 靠彈性卡住
// （不賭尺寸公差，走壓潰/卡入路線）。
// ============================================================
IR_CLIP_H = 5;      // 立柱厚（x 向）＝夾持長度，對 3mm 元件本體
IR_CLIP_W = 2.8;    // 槽口寬（元件 Ø3.0 → 0.2 過盈卡入）
IR_X      = 13;     // 立柱中心 x（軌道外緣 ±10 之外）
IR_LED_D  = 3.0;    // 元件實際外徑
IR_SLOT_D = 3.2;    // 槽徑（0.2 讓元件落得到底）
IR_BEAM_Z = 3 + IR_Z;                              // 11：光路束高
// 元件是「躺在槽底」不是懸在槽心 → 槽心要抬半個間隙，元件軸心才落在束高。
// 與隧道孔心 BORE_Z = 球心 + (孔徑−球徑)/2 完全同一個道理。
IR_SLOT_Z = IR_BEAM_Z + (IR_SLOT_D - IR_LED_D)/2;  // 11.1
IR_CLIP_Z = IR_SLOT_Z + IR_SLOT_D/2 + 1.3;         // 14：頂面高於槽頂，卡入頸才完整

module ir_clip(sx) {
    translate([sx*IR_X, 0, 0]) difference() {
        translate([-IR_CLIP_H/2, -3, 0]) cube([IR_CLIP_H, 6, IR_CLIP_Z]);
        translate([0, 0, IR_SLOT_Z]) rotate([0,90,0])
            cylinder(d=IR_SLOT_D, h=IR_CLIP_H+4, center=true);      // 管槽
        translate([-IR_CLIP_H/2-2, -IR_CLIP_W/2, IR_SLOT_Z])
            cube([IR_CLIP_H+4, IR_CLIP_W, 8]);                      // 上開口（收窄卡入）
    }
}

// 試片：20mm 軌道段（可放球）＋兩側水平夾座＋牆上光路孔
// 驗：元件壓入卡不卡得住、兩側光軸是否同高對準、球放上去能否確實遮斷
module ir_test() {
    difference() {
        union() {
            translate([-10, 0, 0]) cube([20, 20, 3]);                // 加厚底
            translate([0,0,3]) rotate([90,0,0]) translate([0,0,-20]) linear_extrude(20.01) profile(0);
            translate([-16, 7, 0]) cube([32, 6, 3]);                 // 夾座翼板
            translate([0,10,0]) ir_clip(-1);
            translate([0,10,0]) ir_clip( 1);
        }
        // 光路：Ø3.5 水平橫穿兩側牆（外牆頂 16、內牆頂 12，束高 11 兩側都要穿）
        // 止於軌道外緣 ±10.5，**不可貫穿立柱**——Ø3.5 孔底 9.25 低於 Ø3.2 槽底 9.5，
        // 打穿的話元件會落到孔底、光軸偏低 0.25（已實測過一次）
        translate([-10.5, 10, IR_BEAM_Z]) rotate([0,90,0]) cylinder(d=IR_D, h=21);
    }
}
if (part=="ir") ir_test();
