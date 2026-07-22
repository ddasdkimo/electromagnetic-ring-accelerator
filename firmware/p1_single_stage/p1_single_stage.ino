// P1 單級直線驗證韌體 — XIAO ESP32-S3
// 時序：IR 閘門1 觸發 → 延遲 d → 線圈脈衝寬 w → 關斷
// 閘門1/閘門2 間距 GATE_SPACING_MM 測球速；序列埠即時調參
//
// 接線（見 my_car emring-driver.html 與 coil-and-driver-spec.md）：
//   IR 前端【定案】：光電晶體「集極輸出」——集極接 GPIO（內部上拉 INPUT_PULLUP）、
//   射極接 GND。受光導通=LOW、遮光截止=HIGH → 觸發邊緣 RISING、卡球判 HIGH（三處一致）
//   GPIO1 = IR 閘門1、GPIO2 = IR 閘門2（測速用，可先不接）
//   GPIO4 (D3) = MOSFET 閘極（→100Ω→IRLB8721 G）。板上 10k 閘極下拉必須保留：
//   開機/燒錄瞬間 GPIO 為 hi-Z，全靠它防線圈誤導通；並刻意避開 strapping 腳 GPIO3
// 序列埠指令：d <us> 設延遲 / w <us> 設脈寬 / s 顯示參數 / e 0|1 停用/啟用

const int PIN_GATE1 = 1;
const int PIN_GATE2 = 2;
const int PIN_COIL  = 4;

// my_car 脈寬對球速表（w≈d_eff/v，d_eff≈10mm，實務再提早~1ms 關斷防 suck-back）：
//   0.5m/s→19ms  1.0→9ms  1.5→5.7ms  2.0→4.0ms  2.5→3.0ms  3.0→2.3ms
// 0.5–3m/s 全在電流飽和區（τ≈0.65ms），調校重點只在「關斷時機」。
const float GATE_SPACING_MM = 30.0;   // 閘門1→閘門2 間距，依實裝修改
const uint32_t PULSE_MAX_US = 25000;  // 安全上限 25ms（涵蓋 0.5m/s 慢速；單發熱 ~1.8J 仍安全）
const uint32_t REARM_MIN_US = 30000;  // 兩次觸發最小間隔，防抖/防連發
const uint32_t STUCK_MS     = 500;    // 閘門遮擋超過此值視為卡球/故障 → 停用

uint32_t delay_us = 0;      // d：觸發後延遲
uint32_t pulse_us = 10000;  // w：起手 10ms（對應手推入球 ~1m/s，實測後調）
bool enabled = true;

volatile uint32_t t_gate1 = 0, t_gate2 = 0;
volatile bool fired = false;

void IRAM_ATTR onGate1() { t_gate1 = micros(); fired = true; }
void IRAM_ATTR onGate2() { t_gate2 = micros(); }

void setup() {
  pinMode(PIN_COIL, OUTPUT);
  digitalWrite(PIN_COIL, LOW);
  pinMode(PIN_GATE1, INPUT_PULLUP);
  pinMode(PIN_GATE2, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(PIN_GATE1), onGate1, RISING);
  attachInterrupt(digitalPinToInterrupt(PIN_GATE2), onGate2, RISING);
  Serial.begin(115200);
  Serial.println("P1 single stage ready. cmds: d <us> | w <us> | s | e 0|1");
}

void firePulse() {
  // d 以 t_gate1 中斷瞬間為基準，扣掉 loop 服務延遲（防時序抖動）
  uint32_t elapsed = micros() - t_gate1;
  if (delay_us > elapsed) delayMicroseconds(delay_us - elapsed);
  digitalWrite(PIN_COIL, HIGH);
  // 脈寬用 micros() 截止時間：delayMicroseconds 傳大值不保證準
  uint32_t t_off = micros() + min(pulse_us, PULSE_MAX_US);
  while ((int32_t)(t_off - micros()) > 0) {}
  digitalWrite(PIN_COIL, LOW);
}

void loop() {
  static uint32_t last_fire = 0;

  if (fired) {
    fired = false;
    uint32_t now = micros();
    if (enabled && (now - last_fire) > REARM_MIN_US) {
      last_fire = now;
      firePulse();
      Serial.printf("fired: d=%luus w=%luus\n", delay_us, pulse_us);
    }
  }

  // 測速：閘門2 晚於閘門1 → v = s/Δt
  static uint32_t last_report = 0;
  if (t_gate2 > t_gate1 && t_gate1 && t_gate2 != last_report) {
    last_report = t_gate2;
    float dt_s = (t_gate2 - t_gate1) / 1e6;
    Serial.printf("speed: %.2f m/s (dt=%luus)\n",
                  GATE_SPACING_MM / 1000.0 / dt_s, t_gate2 - t_gate1);
  }

  // 安全：閘門1 持續遮擋或斷線（皆讀 HIGH）→ 停用並確保線圈關斷
  static uint32_t blocked_since = 0;
  if (digitalRead(PIN_GATE1) == HIGH) {
    if (!blocked_since) blocked_since = millis();
    else if (millis() - blocked_since > STUCK_MS && enabled) {
      enabled = false;
      digitalWrite(PIN_COIL, LOW);
      Serial.println("!! gate1 stuck blocked -> disabled (e 1 to re-arm)");
    }
  } else blocked_since = 0;

  // 序列埠調參
  if (Serial.available()) {
    String line = Serial.readStringUntil('\n');
    char cmd = line.charAt(0);
    long v = line.substring(1).toInt();
    if (cmd == 'd') { delay_us = v; }
    else if (cmd == 'w') { pulse_us = min((uint32_t)v, PULSE_MAX_US); }
    else if (cmd == 'e') { enabled = v; if (!v) digitalWrite(PIN_COIL, LOW); }
    Serial.printf("d=%luus w=%luus enabled=%d\n", delay_us, pulse_us, enabled);
  }
}
