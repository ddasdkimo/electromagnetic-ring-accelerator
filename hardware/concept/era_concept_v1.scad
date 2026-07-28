// 電磁環形加速器 — 第一版 3D 概念示意圖（非製造圖，尺寸沿用定案參數）
// 中心圓 Ø240、4 線圈段 90° 均布、45° 雙軌 U 槽、bobbin ID14.5/法蘭 Ø26
// 渲染：openscad -o concept_v1.png --preview era_concept_v1.scad

R = 120;            // 軌道中心圓半徑
TRACK_W = 23;       // 軌道剖面寬
BALL_D = 12.7;
BALL_Z = 9.98;      // 開放段球心高（stl 定案）
BORE_Z = 10.88;     // 隧道段孔心高（零落差過渡）
COIL_ANGLES = [0, 90, 180, 270];
COIL_CLEAR_LEN = 40;   // 線圈段清出軌道牆的弦長

module track_profile() {
  // x=0 為內側；底板3、V槽平底4(z3)、45°斜軌到z8、內牆z10、外牆z17
  // 修正 2026-07-28：原本外側漏了斜面頂點 [18.5,8]，從 [20.5,8] 直接連到 [13.5,3]
  // 使外側實際只有 35.5°（Δx=7/Δz=5），與同檔 BALL_Z=9.98 所依據的對稱 45° 不符，
  // 且外側比內側緩正是離心力要壓的那面。stl 確認正式件一直是對稱 45°，錯只在本示意檔。
  polygon([[0,0],[TRACK_W,0],[TRACK_W,17],[TRACK_W-2.5,17],[TRACK_W-2.5,8],
           [18.5,8],[13.5,3],[9.5,3],[4.5,8],[2.5,8],[2.5,10],[0,10]]);
}

module track_ring() {
  color("#d8d8de") difference() {
    rotate_extrude($fn=240)
      translate([R-TRACK_W/2, 0]) track_profile();
    // 線圈段把兩側牆清出來（隧道取代此段）
    for (a = COIL_ANGLES) rotate([0,0,a])
      translate([R,0,3+10]) cube([TRACK_W+8, COIL_CLEAR_LEN, 20], center=true);
  }
}

module coil_section() {
  rotate([90,0,0]) {
    // bobbin 薄壁管 + 兩端法蘭
    color("#7ab3d9") {
      difference() {
        cylinder(d=16.1, h=30, center=true, $fn=64);
        cylinder(d=14.5, h=32, center=true, $fn=64);
      }
      for (s=[-1,1]) translate([0,0,s*14]) difference() {
        cylinder(d=26, h=2, center=true, $fn=64);
        cylinder(d=14.5, h=4, center=true, $fn=64);
      }
    }
    // 銅線圈（0.5mm×290匝，繞線層厚4 → 外徑約24）
    color("#c47a35") difference() {
      cylinder(d=24, h=24, center=true, $fn=64);
      cylinder(d=16.2, h=26, center=true, $fn=64);
    }
  }
}

module ir_gate(a) {  // 隧道入口前的 IR 對射柱（示意）
  rotate([0,0,a]) for (side=[-1,1])
    translate([R+side*(TRACK_W/2+3), 0, 0])
      color("#222") cylinder(d=4, h=13, $fn=24);
}

module driver_pcb(a) {  // 每線圈一組驅動板（示意）
  rotate([0,0,a]) translate([R-45,0,0.5])
    color("#2e7d4f") cube([22,16,2], center=true);
}

// ---- 組立 ----
color("#3a3f46") translate([0,0,-4]) cylinder(d=295, h=4, $fn=240);  // 底座
track_ring();
for (a = COIL_ANGLES) {
  rotate([0,0,a]) translate([R,0,BORE_Z]) coil_section();
  ir_gate(a-13);
  driver_pcb(a);
}
// 控制板（XIAO ESP32-S3 示意）置中
color("#37474f") translate([0,0,1]) cube([24,18,4], center=true);
color("#c0c0c0") translate([0,0,3.5]) cube([10,10,2], center=true);
// 鋼球在開放段
rotate([0,0,205]) translate([R,0,BALL_Z]) color("#cfd6dd") sphere(d=BALL_D, $fn=64);
