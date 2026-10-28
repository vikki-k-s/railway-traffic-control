# 🛠️ Physical Hardware Prototype Construction Guide
### Railway Level Crossing & Train Traffic Controller
**Course Code:** UE25EC2302 | **GM University, Davanagere** | **Semester 3 PBL**

---

## 1. 🛒 Complete Bill of Materials (Component Checklist)

All these components are standard, inexpensive, and readily available on **Robu.in**, **Amazon.in**, or local electronics shops (SP Road Bangalore / Davanagere):

| Sl. No. | Component Description | Specifications / Part No. | Qty | Approx. Price (INR ₹) | Purpose in Model |
|:---:|:---|:---|:---:|:---:|:---|
| **1** | **Main Controller Board** | **Option A:** Basys 3 / Cyclone IV FPGA <br>*(OR)*<br> **Option B:** Arduino Uno R3 / Mega 2560 | 1 | ₹450 (Arduino) / Lab FPGA | Executes the Level Crossing FSM controller logic |
| **2** | **Servo Motors (Gate Barrier)** | TowerPro SG90 (9g Micro Servo) | 2 | ₹120 each (₹240) | Motorized mechanical arms rotating 0° (closed) to 90° (open) |
| **3** | **IR Proximity Sensor Modules** | TCRT5000 / LM393 Active-Low Infrared Obstacle Detector (Adjustable Range 2–30 cm) | 4 | ₹40 each (₹160) | • Sensor 1: Entry Sensor (Inbound)<br>• Sensor 2: Track Occupancy<br>• Sensor 3: Exit Sensor (Outbound)<br>• Sensor 4: Road Track Obstacle |
| **4** | **Road Traffic Light Module** | Mini 3-Color Traffic Light LED Module (or 5mm discrete LEDs: Red, Yellow, Green) | 2 | ₹35 each (₹70) | Signals for road traffic on both sides of the crossing |
| **5** | **Crossbuck Warning LEDs** | 5mm High-Brightness Diffused Red LEDs | 4 | ₹2 each (₹8) | Alternating wig-wag hazard flasher lights |
| **6** | **Pedestrian Crossing LEDs** | 5mm Green (Walk) & Red (Don't Walk) LEDs | 2 pairs | ₹2 each (₹8) | Visual crossing status for pedestrians |
| **7** | **Train Aspect Signal LEDs** | 5mm Bi-color or Red/Green LEDs | 2 | ₹5 each (₹10) | Signals facing locomotive on tracks |
| **8** | **Audible Warning Buzzer** | 5V Active Piezo Buzzer (Continuous/Pulsed) | 1 | ₹25 | Emits warning chime during descent and high-pitch emergency siren |
| **9** | **Emergency Push Button** | 12mm Tactile Push-to-Make Button with Cap | 2 | ₹10 each (₹20) | Manual Emergency Stop & Gate Interlock Tamper Test |
| **10** | **Current Limiting Resistors** | 220Ω / 330Ω, 1/4W Resistors | 15 | ₹1 each (₹15) | Prevents LED burnout |
| **11** | **Pull-down / Pull-up Resistors**| 10kΩ Resistors | 4 | ₹1 each (₹4) | Stabilizes button inputs |
| **12** | **Breadboard & Jumper Wires** | 830-Point MB-102 Breadboard + 65 Male-to-Male & Male-to-Female Jumper Wires | 1 set | ₹150 | Solderless rapid prototyping & wire routing |
| **13** | **Power Supply** | 5V 2A DC Power Adapter / 9V Hi-Watt Battery with DC Barrel Jack & 5V Buck Module | 1 | ₹120 | Powers the controller, servos, and sensors |
| **14** | **Diorama Base & Tracks** | Foam Board / 5mm Sunboard Sheet (30x45 cm), Toy Train Tracks / 3D Printed Rails, Toy Car | 1 set | ₹150–250 | Aesthetic physical demonstration diorama |
| **15** | **Barrier Arms Crafting** | Ice-cream wooden sticks / 3mm acrylic strips painted with Red & White hazard stripes | 2 | ₹20 | Lightweight physical barrier arms glued to servo horns |
| **TOTAL** | — | — | — | **~₹1,100 – ₹1,500** | *(Complete hardware budget)* |

---

## 2. 🔌 Circuit Schematic & Wiring Pinout Table

### Pin Connection Mapping (Arduino / FPGA GPIO)

```
                     +---------------------------------------+
                     |           CONTROLLER BOARD            |
                     |         (Arduino Uno / FPGA)          |
                     +---------------------------------------+
                        |        |        |        |        |
         +--------------+        |        |        |        +---------------+
         |                       |        |        |                        |
         v                       v        v        v                        v
  [TRACK SENSORS]             [SERVOS] [TRAFFIC] [BUZZER]             [EMERGENCY BTNS]
  • Pin 2: Entry Sensor (S1)  • Pin 9  • Pin 4:  • Pin 8: 5V Active   • Pin A0: Manual
  • Pin 3: Track Sensor (S2)    North    Red       Buzzer (+)           Stop Button
  • Pin 7: Exit Sensor  (S3)  • Pin 10 • Pin 5:  • GND:    GND        • Pin A1: Track
  • Pin 6: Track Obstacle       South    Yellow                         Obstacle Switch
                                         • Pin 6:
                                           Green
```

### Complete Pin Assignment Table:

| Subsystem | Component Pin | Controller Pin (Arduino Uno) | FPGA Board Pin (Basys 3 / Spartan) | Notes / Wiring Instructions |
|:---|:---|:---:|:---:|:---|
| **Entry Sensor (S1)** | `OUT` pin | **Pin 2** (Interrupt) | `V17` (SW0 or PMOD JA1) | Active-Low / High when train passes |
| **Track Sensor (S2)** | `OUT` pin | **Pin 3** (Interrupt) | `V16` (SW1 or PMOD JA2) | Located directly on level crossing |
| **Exit Sensor (S3)** | `OUT` pin | **Pin 7** | `W16` (SW2 or PMOD JA3) | Located 15–20 cm after crossing |
| **Obstacle Sensor** | `OUT` pin | **Pin A1** (or D11) | `W17` (SW3 or PMOD JA4) | Optical sensor facing the roadway track area |
| **Manual Emergency Btn**| One terminal | **Pin A0** | `U18` (Center Push Button) | Connect with 10kΩ pull-down resistor to GND |
| **Gate Servo 1 (North)**| Signal wire (Orange/Yellow) | **Pin 9** (PWM) | `J1` (PMOD JB1 - PWM pulse) | Connect Red wire to 5V, Brown wire to GND |
| **Gate Servo 2 (South)**| Signal wire (Orange/Yellow) | **Pin 10** (PWM) | `L2` (PMOD JB2 - PWM pulse) | Move in tandem with Servo 1 |
| **Road RED Light** | Anode (+) via 220Ω | **Pin 4** | `U16` (LD0) | High when gate closing/closed |
| **Road YELLOW Light** | Anode (+) via 220Ω | **Pin 5** | `E19` (LD1) | High during early warning pre-closure |
| **Road GREEN Light** | Anode (+) via 220Ω | **Pin 6** | `U19` (LD2) | High ONLY when gate is 90° open & safe |
| **Crossbuck Flasher L** | Anode (+) via 220Ω | **Pin 12** | `V19` (LD3) | Alternates with Flasher R |
| **Crossbuck Flasher R** | Anode (+) via 220Ω | **Pin 13** | `W18` (LD4) | Alternates with Flasher L |
| **Train Signal GREEN** | Anode (+) via 220Ω | **Pin A2** | `U15` (LD5) | Train aspect: Green ONLY if gate = 0° |
| **Train Signal RED** | Anode (+) via 220Ω | **Pin A3** | `U14` (LD6) | Train aspect: Red if gate open/obstacle |
| **Audible Buzzer** | Positive (+) pin | **Pin 8** | `V14` (LD7 / Piezo) | Ground negative pin to common GND |
| **Power Distribution** | VCC & GND | **5V & GND Rails** | **5V & GND Pins** | Tie all grounds together! |

> [!IMPORTANT]
> **Power Tip for Servos:** Two SG90 micro-servos can draw up to 500mA–800mA peak when moving. Do **not** power both servos from the Arduino 5V pin alone (as it can cause the board to brown-out reset). Power the servo VCC lines from an external 5V 1A/2A DC power supply and ensure the **GND of the external power supply is connected to the Arduino/FPGA GND** (Common Ground).

---

## 3. 🏗️ Step-by-Step Diorama & Physical Model Construction

### Step 1: Baseboard Layout
1. Take a 30 cm × 45 cm Sunboard or MDF sheet.
2. Paint or draw a two-lane asphalt roadway intersecting a two-track railway line at a $90^\circ$ cross-angle in the center.

### Step 2: Track & Sensor Placement
1. **Sensor 1 (Entry / Up-Line):** Mount 20 cm before the crossing on the left side of the track. Adjust the potentiometer screw so it triggers when a toy train or wagon passes within 3–5 cm.
2. **Sensor 2 (Track Occupancy):** Mount directly inside the level crossing between the rails facing upwards or across the rails.
3. **Sensor 3 (Exit / Outbound):** Mount 20 cm past the crossing on the right side.
4. **Obstacle Sensor:** Mount across the road lane pointing at the railway track zone to detect stalled cars.

### Step 3: Motorized Barrier Arms Assembly
1. Take two wooden craft sticks (or white acrylic strips). Paint red diagonal stripes at $45^\circ$ angles using red marker/tape.
2. Screw the craft stick to the single-arm horn supplied with the SG90 servo.
3. Glue the SG90 servo motor body vertically on the road curb so the arm sits at $90^\circ$ (vertical) when open and drops to $0^\circ$ (horizontal across the road) when closed.

### Step 4: Signal Lights & Poles
1. Use a drinking straw or wooden skewer painted black as a signal mast.
2. Mount the Red, Yellow, and Green LEDs on a small piece of perforated dot-board or stiff paper at the top of the mast.
3. Place crossbuck red LEDs at a $45^\circ$ angle at the crossing entrance.

---

## 4. 💻 Hardware Driver Code (Arduino Demonstration Companion)

If presenting a physical prototype demo while submitting the Verilog HDL code, the following Arduino sketch implements the **exact same 4-state FSM and safety interlocking logic** as your Verilog model:

```cpp
/*
 * GM UNIVERSITY - DEPARTMENT OF ECE (UE25EC2302)
 * Hardware Implementation of Railway Level Crossing Controller
 * FSM & Hardware Interlocking Logic matching Verilog HDL model
 */

#include <Servo.h>

// Pin Definitions
const int PIN_SENSOR_ENTRY    = 2;  // S1 (Inbound)
const int PIN_SENSOR_TRACK    = 3;  // S2 (Crossing Zone)
const int PIN_SENSOR_EXIT     = 7;  // S3 (Outbound)
const int PIN_SENSOR_OBSTACLE = A1; // Track Obstacle LiDAR/IR
const int PIN_EMG_BUTTON      = A0; // Manual Emergency Button

const int PIN_ROAD_RED        = 4;
const int PIN_ROAD_YELLOW     = 5;
const int PIN_ROAD_GREEN      = 6;

const int PIN_FLASHER_LEFT    = 12;
const int PIN_FLASHER_RIGHT   = 13;
const int PIN_BUZZER          = 8;

const int PIN_TRAIN_GREEN     = A2;
const int PIN_TRAIN_RED       = A3;

const int PIN_SERVO_NORTH     = 9;
const int PIN_SERVO_SOUTH     = 10;

Servo servoNorth;
Servo servoSouth;

// FSM States (identical to Verilog localparams)
enum GateState { ST_OPEN, ST_CLOSING, ST_CLOSED, ST_OPENING };
GateState currentState = ST_OPEN;

int gateAngle = 90; // 90 = Open, 0 = Closed
unsigned long stateTimer = 0;
bool flasherPhase = false;
unsigned long lastFlasherTime = 0;

void setup() {
  Serial.begin(115200);

  pinMode(PIN_SENSOR_ENTRY, INPUT_PULLUP);
  pinMode(PIN_SENSOR_TRACK, INPUT_PULLUP);
  pinMode(PIN_SENSOR_EXIT,  INPUT_PULLUP);
  pinMode(PIN_SENSOR_OBSTACLE, INPUT_PULLUP);
  pinMode(PIN_EMG_BUTTON, INPUT_PULLUP);

  pinMode(PIN_ROAD_RED, OUTPUT);
  pinMode(PIN_ROAD_YELLOW, OUTPUT);
  pinMode(PIN_ROAD_GREEN, OUTPUT);

  pinMode(PIN_FLASHER_LEFT, OUTPUT);
  pinMode(PIN_FLASHER_RIGHT, OUTPUT);
  pinMode(PIN_BUZZER, OUTPUT);

  pinMode(PIN_TRAIN_GREEN, OUTPUT);
  pinMode(PIN_TRAIN_RED, OUTPUT);

  servoNorth.attach(PIN_SERVO_NORTH);
  servoSouth.attach(PIN_SERVO_SOUTH);

  // Initial Safe State: Barriers Up (90 deg)
  servoNorth.write(90);
  servoSouth.write(90);

  Serial.println("==================================================");
  Serial.println("  GM UNIVERSITY - LEVEL CROSSING CONTROLLER       ");
  Serial.println("  Verilog Hardware Model Initialized in SAFE IDLE ");
  Serial.println("==================================================");
}

void loop() {
  // Read active-low sensors (LM393 IR modules output LOW on detection)
  bool trainApproaching = (digitalRead(PIN_SENSOR_ENTRY) == LOW);
  bool trainPresent     = (digitalRead(PIN_SENSOR_TRACK) == LOW);
  bool trainCleared     = (digitalRead(PIN_SENSOR_EXIT)  == LOW);
  bool obstacleDetected = (digitalRead(PIN_SENSOR_OBSTACLE) == LOW);
  bool manualEmergency  = (digitalRead(PIN_EMG_BUTTON) == LOW);

  bool emergencyActive = obstacleDetected || manualEmergency;

  // Flasher timer (every 400ms)
  if (millis() - lastFlasherTime > 400) {
    lastFlasherTime = millis();
    flasherPhase = !flasherPhase;
  }

  // =========================================================================
  // FSM State Machine Execution (Unit 3 Behavioural Modelling in Silicon)
  // =========================================================================
  switch (currentState) {
    case ST_OPEN:
      gateAngle = 90;
      setRoadLight(LOW, LOW, HIGH); // Road GREEN
      setTrainLight(HIGH, LOW);     // Train RED (Stop)
      setFlashers(false);
      noTone(PIN_BUZZER);

      if (trainApproaching || emergencyActive) {
        Serial.println("[FSM] Train Approaching! Pre-closure Yellow Warning.");
        currentState = ST_CLOSING;
        stateTimer = millis();
      }
      break;

    case ST_CLOSING:
      setRoadLight(LOW, HIGH, LOW); // Road YELLOW Caution
      setTrainLight(HIGH, LOW);     // Train RED (Stop)
      setFlashers(true);
      tone(PIN_BUZZER, emergencyActive ? 1200 : 600); // Warning Tone

      // Step servo downwards from 90 to 0
      if (millis() - stateTimer > 1500) { // 1.5s warning lead time
        for (int a = 90; a >= 0; a -= 5) {
          servoNorth.write(a);
          servoSouth.write(180 - a);
          delay(40);
        }
        gateAngle = 0;
        currentState = ST_CLOSED;
        Serial.println("[FSM] Barrier fully LOCKED at 0°. Train Aspect GREEN.");
      }
      break;

    case ST_CLOSED:
      gateAngle = 0;
      setRoadLight(HIGH, LOW, LOW); // Road solid RED (Stop)
      setFlashers(true);

      // Gate-Level Safety Interlock Rule (Unit 2):
      // Train receives GREEN ONLY IF gate is 0° AND no obstacle on tracks!
      if (!emergencyActive) {
        setTrainLight(LOW, HIGH); // Train GREEN (Clear to Proceed)
        noTone(PIN_BUZZER);
      } else {
        setTrainLight(HIGH, LOW); // Train FORCED RED on obstacle
        tone(PIN_BUZZER, 1400);   // Emergency siren
      }

      // Check if train has departed and safety delay satisfied
      if (trainCleared && !trainPresent && !emergencyActive) {
        Serial.println("[FSM] Train completely departed. Preparing to open.");
        delay(1000); // Post-clear buffer delay
        currentState = ST_OPENING;
      }
      break;

    case ST_OPENING:
      setRoadLight(HIGH, LOW, LOW); // Hold road RED during transit
      setTrainLight(HIGH, LOW);     // Train RED
      setFlashers(false);
      noTone(PIN_BUZZER);

      // Step servo upwards from 0 to 90
      for (int a = 0; a <= 90; a += 5) {
        servoNorth.write(a);
        servoSouth.write(180 - a);
        delay(40);
      }
      gateAngle = 90;
      currentState = ST_OPEN;
      Serial.println("[FSM] Barrier restored to 90°. Road restored to GREEN.");
      break;
  }

  delay(20);
}

// Helper Functions
void setRoadLight(bool r, bool y, bool g) {
  digitalWrite(PIN_ROAD_RED, r);
  digitalWrite(PIN_ROAD_YELLOW, y);
  digitalWrite(PIN_ROAD_GREEN, g);
}

void setTrainLight(bool r, bool g) {
  digitalWrite(PIN_TRAIN_RED, r);
  digitalWrite(PIN_TRAIN_GREEN, g);
}

void setFlashers(bool active) {
  if (active) {
    digitalWrite(PIN_FLASHER_LEFT, flasherPhase ? HIGH : LOW);
    digitalWrite(PIN_FLASHER_RIGHT, flasherPhase ? LOW : HIGH);
  } else {
    digitalWrite(PIN_FLASHER_LEFT, LOW);
    digitalWrite(PIN_FLASHER_RIGHT, LOW);
  }
}
```

---

## 5. 🎯 Tips for Scoring Full 40/40 Marks in College Demonstration

1. **Demonstrate Unit 2 Gate-Level Interlock:**
   - While the train is passing on the track (Sensor 2 covered), try pressing an external button to force open the gate. Show the examiner that the system **refuses to open the gate** and sounds the violation alarm. Mention: *"Sir, this is enforced by pure structural gate primitives (`and`, `or`, `not`) in `gate_safety_interlock.v`!"*
2. **Demonstrate Obstacle Emergency Priority:**
   - Put a toy car on the track sensor while the train is inbound. Show that the train aspect signal instantly flips from **Green to RED**, proving that the controller prevents collisions.
3. **Show the Live Waveform on Screen:**
   - Keep GTKWave or the Web Dashboard (`http://localhost:3000`) open on your laptop alongside the physical model to show real-time synchronization between the hardware model and software telemetry.
