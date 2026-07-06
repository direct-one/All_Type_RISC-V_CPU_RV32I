# RISC-V RV32I Single-Cycle CPU Core 
## 1. Architecture Highlights

본 프로세서는 1 클럭 사이클(1 Clock Cycle) 내에 명령어 반환(Fetch), 해석(Decode), 실행(Execute), 메모리 접근(Memory Access), 쓰기 되돌리기(Write-back)가 모두 완료되는 직관적인 데이터패스를 가집니다.

* **Full ISA Support (All-Type)**: R, I, S, B, U(LUI, AUIPC), J(JAL, JALR) 타입 등 RV32I의 주요 6가지 명령어 집합을 누락 없이 완벽히 디코딩하고 제어합니다.
* **Byte-Alignment Memory Access**: 데이터 메모리 접근 시 주소의 하위 2비트를 활용하여 Byte(SB/LB), Half-word(SH/LH), Word(SW/LW) 연산을 유연하게 분기하고, 부호 확장(Sign Extension) 로직을 정교하게 처리합니다.
* **Combinational Logic Optimization**: 제어 장치(Control Unit) 내에 명확한 Default 값을 할당하여 합성 과정에서 원치 않게 발생하는 래치(Latch)를 원천 차단하고 타이밍 마진을 확보했습니다.

## 2. Core Modules & Data Flow

시스템의 복잡도를 낮추고, 코드의 재사용을 극대화하기 위해 모듈을 세분화

| 모듈명 (Module) | 역할 및 특징 |
| :--- | :--- |
| **`rv32i_cpu`** | Control Unit과 Datapath를 연결하여 제어 신호와 데이터가 유기적으로 교환되도록 하는 최상위 래퍼(Wrapper) |
| **`control_unit`** | Opcode와 funct 필드를 해독하여 MUX 선택 신호, ALU 제어 신호, 메모리 활성화 신호를 생성하는 순수 조합 논리 회로 |
| **`rv32i_datapath`** | 레지스터 파일, ALU, PC를 포함하며 실제 데이터 연산과 분기 주소 계산이 일어나는 물리적 경로 |
| **`alu` & `imm_extender`** | ALU 연산 및 B-Type 조건 비교 수행. 확장기(Extender)는 명령어 타입에 맞게 즉치(Immediate) 값을 32비트로 안전하게 확장 |

## 3. Engineering & Trouble Shooting

설계 과정에서 직면한 아키텍처 결함을 분석하고 논리적으로 해결한 과정입니다.

### Issue 1. JALR 명령어 베이스 주소 누락 결함 조치
* **현상**: JALR 명령어 실행 시, 목표 주소 계산을 위한 레지스터 값(`rs1`)과 즉치(`imm`)의 덧셈 연산이 정상적으로 수행되지 않음.
* **원인**: Datapath 계층에서 Program Counter(PC) 모듈 인스턴스화 시, `rd1` 데이터가 인가되지 않는 포트 매핑 누락(Port mapping omission) 발견.
* **해결**: ALU를 거치지 않고 PC 모듈 내부에서 독립적이고 정확한 Jump 주소 연산이 가능하도록 `.rd1(rd1)` 핀 연결을 명시적으로 추가하여 아키텍처 결함 수정 및 동작 검증 완료.

### Issue 2. Latch 발생 억제를 위한 제어 로직 구조화
* **현상**: 조합 논리 회로(`always_comb`) 합성 시, 예기치 않은 메모리 소자(Latch)가 생성되어 타이밍 이슈 발생 위험 존재.
* **원인**: `case` 문 내부에서 특정 제어 신호의 조건이 완전히 닫히지 않아 이전 상태를 유지하려는 합성 툴의 특성 때문.
* **해결**: 디코더 설계 시 진입 직전에 모든 제어 신호(`rf_we`, `branch` 등)에 대해 `1'b0`과 같은 명확한 기본값(Default)을 할당하여 래치 생성을 구조적으로 차단.

---
