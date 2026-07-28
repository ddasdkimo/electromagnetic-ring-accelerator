// 電磁環形加速器 — 方案 B（v2 Banked-Square 4）概念示意圖
// 與 v1 差異：圓角方形（線圈在直線段、入口角 0°）、彎道傾斜賽道 65°/35°、Ø9.5 小球
// 渲染：openscad -o concept_v2.png --preview era_concept_v2.scad

STRAIGHT = 60;      // 直線段長（中間 30 放線圈，兩端各 15 為 banking 漸變段）
R_CORNER = 85;      // 彎道中心線半徑
C = STRAIGHT/2;     // 彎心座標 (±30, ±30)
D = C + R_CORNER;   // 直線段中心線離原點距離 = 115

BALL_D  = 9.5;
BASE_Z  = 3;        // 軌道底板厚（槽底基準面）
BALL_Z  = BASE_Z + 5.218;  // 球心高 = r√2 − 平底半寬 = 4.75×1.4142 − 1.5
BORE_Z  = BALL_Z;   // 隧道孔心與球心同高（零落差）
BANK    = 20;       // 彎道傾斜角（外側面 45+20=65°、內側面 45−20=25°）

NSEG = 15;          // banking 漸變段分片數（示意用；正式件應以連續掃掠生成）

// ---- banking = 整個 V 槽「繞球心旋轉」，槽夾角維持 90° ----
// 關鍵：球心的高度與徑向位置全程不變 → 直線段↔彎道過渡零高差。
// （若改成單獨掰彎兩個面的角度，槽夾角會張開，球陷得較淺、球心抬高 3.3mm，過渡就會有坡。）
function rt(p, phi) = [ p[0]*cos(phi) - (p[1]-BALL_Z)*sin(phi),
                        BALL_Z + p[0]*sin(phi) + (p[1]-BALL_Z)*cos(phi) ];

module profile(t) {
  phi = BANK * t;
  a = rt([ 6.5, BASE_Z+5], phi);   // 外側 45° 斜面頂
  b = rt([ 1.5, BASE_Z  ], phi);   // 平底外緣
  c = rt([-1.5, BASE_Z  ], phi);   // 平底內緣
  d = rt([-6.5, BASE_Z+5], phi);   // 內側 45° 斜面頂
  polygon([[-10,0], [10,0], [10,13], [a[0],13], a, b, c, d, [d[0],9], [-10,9]]);
}

// ---- 直線段：中央 t=0，兩端漸變到 t=1 銜接彎道 ----
module straight_side() {
  translate([D,0,0]) rotate([90,0,0]) {
    translate([0,0,-15]) linear_extrude(30) profile(0);   // 中段：線圈區
    for (i = [0:NSEG-1]) {
      t0 = i/NSEG;  seg = 15/NSEG;
      translate([0,0,15 + i*seg])  linear_extrude(seg+0.01) profile(t0);
      translate([0,0,-15 - (i+1)*seg]) linear_extrude(seg+0.01) profile(t0);
    }
  }
}

module corner() {
  translate([C,C,0]) rotate_extrude(angle=90, $fn=160)
    translate([R_CORNER,0]) profile(1);
}

module track() {
  color("#d8d8de") difference() {
    union() {
      for (a=[0,90,180,270]) rotate([0,0,a]) { straight_side(); corner(); }
    }
    // 線圈段清出兩側牆（由 bobbin 隧道取代）
    for (a=[0,90,180,270]) rotate([0,0,a])
      translate([D,0,BASE_Z+10]) cube([26, 32, 20], center=true);
  }
}

// ---- 線圈組（bobbin 內孔 11.2、法蘭 Ø22、0.5mm×290匝 外徑約 20.8）----
module coil_section() {
  rotate([90,0,0]) {
    color("#7ab3d9") {
      difference() {
        cylinder(d=12.8, h=30, center=true, $fn=64);
        cylinder(d=11.2, h=32, center=true, $fn=64);
      }
      for (s=[-1,1]) translate([0,0,s*14]) difference() {
        cylinder(d=22, h=2, center=true, $fn=64);
        cylinder(d=11.2, h=4, center=true, $fn=64);
      }
    }
    color("#c47a35") difference() {
      cylinder(d=20.8, h=24, center=true, $fn=64);
      cylinder(d=12.9, h=26, center=true, $fn=64);
    }
  }
}

// v2 感測：每級 1 道觸發 IR；其中一級（a=0）加第 2 道作測速基準
module ir_gate(a, y) {
  rotate([0,0,a]) for (side=[-1,1])
    translate([D + side*13, y, 0]) color("#222") cylinder(d=3.5, h=12, $fn=24);
}

// ---- 組立 ----
// 底座（圓角方形板）
color("#3a3f46") translate([0,0,-4]) linear_extrude(4)
  hull() for (sx=[-1,1], sy=[-1,1]) translate([sx*C, sy*C]) circle(r=R_CORNER+16, $fn=120);

track();

for (a = [0,90,180,270]) {
  rotate([0,0,a]) translate([D,0,BORE_Z]) coil_section();
  ir_gate(a, -24);                      // 每級觸發道
}
ir_gate(0, -34);                        // 基準級的第 2 道（測速）

// 集中驅動板：4× MOSFET + 4700µF×4 並聯 + XIAO ESP32-S3
color("#2e7d4f") translate([0,0,1]) cube([64,44,2], center=true);
for (i=[-1.5:1:1.5]) color("#1a1a1a") translate([i*13, 15, 4]) cube([7,4,9], center=true);
for (i=[-1.5:1:1.5]) color("#4a4a52") translate([i*13, -2, 8]) cylinder(d=13, h=14, center=true, $fn=32);
color("#37474f") translate([0,-17,4]) cube([22,10,4], center=true);

// 鋼球在彎道上（球心高度與徑向位置和直線段完全相同）
rotate([0,0,45]) translate([C*sqrt(2) + R_CORNER, 0, BALL_Z])
  color("#cfd6dd") sphere(d=BALL_D, $fn=64);
