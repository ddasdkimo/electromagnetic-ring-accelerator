// ============================================================
// ERA v2 正式件「完成品」預覽（Banked-Square 4）
// 純視覺用途——幾何參數與 test_fit_v2.scad 同源，但不作為出圖檔。
// 用途：讓 David / ERA 在下正式件之前先看整體長相與分件方式。
//
// 渲染：
//   openscad -o preview_iso.png  --preview --autocenter --viewall --imgsize=1600,1200 \
//            -D 'view="iso"' preview_v2.scad
// view = iso | top | corner | section | explode | testfit
// ============================================================
view = "iso";
$fn = 64;

// ---- 幾何（與 test_fit_v2.scad 同源）----
BALL_D  = 9.5;
BASE_Z  = 3;                    // 槽底距「加厚底之上」的高
BALL_Z  = BASE_Z + 5.218;       // 8.218（局部）
BANK    = 20;
STRAIGHT = 60; R_C = 85;
C  = STRAIGHT/2;                // 30
DD = C + R_C;                   // 115：直線段中心線離原點
PLATE = 3;                      // 加厚底（全周，正式件定案）

BOB_ID = 11.2; BOB_WALL = 0.8; BOB_OD = BOB_ID + 2*BOB_WALL;
BOB_LEN = 30; FLANGE_D = 22; FLANGE_T = 2;
BORE_Z = BALL_Z + (BOB_ID-BALL_D)/2;   // 9.068
Z_CUT  = 2.5; FL_FLAT = BORE_Z - Z_CUT;
COIL_OD = 20.8; CRADLE_T = 2.7;
IR_D = 3.5; IR_Z = 8;
NSEG = 12;                      // 預覽用（出圖件是 30）

AXZ = PLATE + BORE_Z;           // 隧道軸心絕對高 12.068
BZ  = PLATE + BALL_Z;           // 球心絕對高 11.218

// ---- 剖面（原式）----
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

// ---- 隧道座（v3：線圈有位、法蘭 D 槽定位）----
// 半座：只長「接縫本側」那一片，另一片由相鄰角件長 → 合起來剛好夾住 bobbin
module tun_add_half() {
  translate([DD-10, 14-CRADLE_T/2, 0]) cube([20, CRADLE_T, PLATE+13]);
}
module tun_cut_at() {
  translate([DD, 0, AXZ]) rotate([90,0,0]) cylinder(d=COIL_OD+0.8, h=26.4, center=true);
  translate([DD, 0, AXZ]) rotate([90,0,0]) cylinder(d=13.4, h=BOB_LEN+0.6, center=true);
  for (sf=[-1,1]) {
    translate([DD-9.12, sf*14-(CRADLE_T+0.7)/2, PLATE+Z_CUT]) cube([18.24, CRADLE_T+0.7, 20]);
    intersection() {
      translate([DD, sf*14, AXZ]) rotate([90,0,0])
        cylinder(d=FLANGE_D+0.6, h=CRADLE_T+0.7, center=true);
      translate([DD-15, sf*14-3, PLATE+Z_CUT]) cube([30, 6, 20]);
    }
  }
  translate([DD-11, -12, PLATE+6]) cube([22, 24, 12]);
}
// IR 光路：止於軌道外緣 ±10.5，不可打進夾座立柱
// （Ø3.5 孔底比 Ø3.2 槽底低 0.25，打穿的話元件落到孔底、光軸就偏了）
module ir_beam_hole(y) {
  translate([DD-10.5, y, PLATE+IR_Z]) rotate([0,90,0]) cylinder(d=IR_D, h=21);
}

// ---- 半段直線：y 0..30（0..15 為 t=0 線圈區，15..30 漸變）----
module half_straight() {
  translate([DD,0,0]) {
    translate([0,0,PLATE]) rotate([90,0,0]) {
      translate([0,0,-15]) linear_extrude(15.01) profile(0);
      for (i=[0:NSEG-1]) {
        t = i/(NSEG-1);
        translate([0,0,-(15+(i+1)*15/NSEG)]) linear_extrude(15/NSEG+0.02) profile(t);
      }
    }
    translate([-10,0,0]) cube([20, 30, PLATE]);           // 加厚底
  }
}
module corner90() {
  translate([C,C,0]) rotate_extrude(angle=90, $fn=240) {
    translate([R_C, PLATE]) profile(1);
    translate([R_C-10, 0]) square([20, PLATE+0.01]);      // 加厚底
  }
}

// ---- L 形角件：半直線 + 彎道 90° + 鏡射半直線 ----
// 接縫落在 (±115, 0) / (0, ±115) —— 也就是每個線圈隧道的正中央
// datum_gate：基準級多開一道測速孔（ERA：每級 1 道 + 基準級加 1 道 = 5 對）
module quarter(datum_gate=false) {
  difference() {
    union() {
      half_straight(); corner90(); mirror([1,-1,0]) half_straight();
      tun_add_half();  mirror([1,-1,0]) tun_add_half();
    }
    tun_cut_at(); mirror([1,-1,0]) tun_cut_at();
    ir_beam_hole(20);
    if (datum_gate) ir_beam_hole(27);
  }
}

// ---- 線圈組（bobbin + 繞線）----
module bobbin_coil() {
  translate([DD, 0, AXZ]) rotate([90,0,0]) {
    color("#8fc7e8") difference() {                       // bobbin
      union() {
        cylinder(d=BOB_OD, h=BOB_LEN, center=true);
        for (s=[-1,1]) translate([0,0,s*(BOB_LEN-FLANGE_T)/2])
          cylinder(d=FLANGE_D, h=FLANGE_T, center=true);
      }
      cylinder(d=BOB_ID, h=BOB_LEN+2, center=true);
      translate([-(FLANGE_D/2+1), -FL_FLAT-FLANGE_D, -BOB_LEN])   // D 截平
        cube([FLANGE_D+2, FLANGE_D, BOB_LEN*2]);
    }
    color("#b5651d") difference() {                       // 漆包線 Ø20.8×26
      cylinder(d=COIL_OD, h=BOB_LEN-2*FLANGE_T, center=true);
      cylinder(d=BOB_OD-0.1, h=BOB_LEN, center=true);
    }
  }
}

// ---- 場景 ----
QCOL = ["#c9ccd4", "#9aa7bd", "#b9c4b0", "#c6b8a8"];   // 4 角件異色：看得出分件與接縫位置
module track_all(ex=0) {
  for (i = [0:3]) rotate([0,0,i*90])
    translate([ex*0.7071, ex*0.7071, 0]) color(QCOL[i]) quarter(i==0);
}
module coils_all()  { for (i=[0:3]) rotate([0,0,i*90]) bobbin_coil(); }
module ball_on_curve() {
  rotate([0,0,45]) translate([C*sqrt(2)+R_C, 0, BZ])
    color("#e8e8ee") sphere(d=BALL_D);
}
module driver_board() {                                    // 集中驅動板（示意）
  translate([0,0,1.5]) {
    color("#1f6f43") cube([70,48,2.4], center=true);
    for (i=[-1.5:1:1.5]) color("#1a1a1a") translate([i*14, 16, 5]) cube([7,4.2,9], center=true);
    for (i=[-1.5:1:1.5]) color("#4a4a52") translate([i*14, -3, 9]) cylinder(d=13, h=15, center=true);
    color("#37474f") translate([0,-19,4]) cube([22,10,4], center=true);
  }
}
// IR 水平夾座（ERA 2026-07-31 核定：5 對對射、束高 z=11、光路水平橫穿）
// 元件躺槽底，槽心抬半個間隙 → 軸心正好落在束高（同隧道孔心的道理）
IR_BEAM = PLATE + IR_Z;          // 11
IR_SLOT = IR_BEAM + 0.1;         // 槽心 11.1（槽 Ø3.2 對元件 Ø3.0）
module ir_gate(y) {
  for (sf=[-1,1]) translate([DD + sf*13, y, 0]) {
    color("#b6bcc4") difference() {
      translate([-2.5, -3, 0]) cube([5, 6, 14]);
      translate([0,0,IR_SLOT]) rotate([0,90,0]) cylinder(d=3.2, h=9, center=true);
      translate([-4.5, -1.4, IR_SLOT]) cube([9, 2.8, 8]);            // 上開口，壓入卡住
    }
    translate([0,0,IR_BEAM]) rotate([0,90,0])
      color("#2b2b2b") cylinder(d=3, h=5, center=true);
  }
}
module ir_pairs() {
  for (i=[0:3]) rotate([0,0,i*90]) ir_gate(20);                      // 每級 1 道觸發
  ir_gate(27);                                                       // 基準級第 2 道（測速）
}

module scene_full() { track_all(); coils_all(); ball_on_curve(); ir_pairs(); driver_board(); }

if (view == "iso" || view == "top") scene_full();

// 這次要印的 4 個試配塊（直接讀出圖用的 STL，所見即所印）
if (view == "testfit") {
  color("#c9ccd4") import("test_v2_combo.stl");
  translate([60, 0, 0])   color("#9aa7bd") import("test_v2_joint_a.stl");
  translate([60, 45, 0])  color("#b9c4b0") import("test_v2_joint_b.stl");
  translate([100, 20, 0]) color("#8fc7e8") import("test_v2_bobbin.stl");
  translate([-45, 5, 0])  color("#c6b8a8") import("test_v2_ir.stl");
}

// 分解圖：4 角件沿對角外拉、線圈組垂直抬起（＝實際組裝動作：繞好線後垂直落入 D 槽）
if (view == "explode") {
  EX = 34;
  track_all(EX);
  for (i=[0:3]) rotate([0,0,i*90]) translate([EX*0.7071, EX*0.7071, 40]) bobbin_coil();
  driver_board();
}

// 單角件特寫：一個 L 件 + 它半邊的兩組線圈
if (view == "corner") {
  color("#c9ccd4") quarter();
  bobbin_coil();
  mirror([1,-1,0]) bobbin_coil();
  ball_on_curve();
}

// 透視圖：線圈／bobbin 半透明，看球在隧道內的位置與接縫落點
// （preview 模式下真剖切會被線圈斷面填滿，透明反而看得清楚）
if (view == "section") {
  intersection() {
    translate([DD-30, -46, -5]) cube([60, 92, 50]);         // 只留接縫段，好聚焦
    union() {
      color("#c9ccd4") quarter();
      color("#7d8aa0") rotate([0,0,-90]) quarter();         // 相鄰角件 → 接縫在 y=0 成形
      // 線圈組上半剖掉 → 直接看見球躺在 bobbin 內孔底（球心 z=11.218 恆定的來源）
      difference() {
        translate([DD, 0, AXZ]) rotate([90,0,0]) {
          color("#b5651d") difference() {                   // 漆包線
            cylinder(d=COIL_OD, h=BOB_LEN-2*FLANGE_T, center=true);
            cylinder(d=BOB_OD-0.1, h=BOB_LEN, center=true);
          }
          color("#8fc7e8") difference() {                   // bobbin
            union() {
              cylinder(d=BOB_OD, h=BOB_LEN, center=true);
              for (s=[-1,1]) translate([0,0,s*(BOB_LEN-FLANGE_T)/2])
                cylinder(d=FLANGE_D, h=FLANGE_T, center=true);
            }
            cylinder(d=BOB_ID, h=BOB_LEN+2, center=true);
            translate([-(FLANGE_D/2+1), -FL_FLAT-FLANGE_D, -BOB_LEN])
              cube([FLANGE_D+2, FLANGE_D, BOB_LEN*2]);
          }
        }
        translate([DD-20, -25, AXZ]) cube([40, 50, 25]);    // 剖掉上半
      }
      translate([DD, 0,  BZ]) color("#f2f4f8") sphere(d=BALL_D);   // 球在隧道正中＝接縫處
      translate([DD, 21, BZ]) color("#cfd6e0") sphere(d=BALL_D);   // 球在開放 V 槽
    }
  }
}
