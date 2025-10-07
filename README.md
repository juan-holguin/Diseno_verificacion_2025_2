# 🧠 PWM Generator Controlled via UART

## 📘 Project Overview
Este proyecto implementa un sistema digital que **genera una señal PWM (Pulse Width Modulation)** cuyo **ciclo útil (duty cycle)** y **frecuencia** pueden configurarse dinámicamente mediante comandos enviados a través de una **interfaz UART**.  
El diseño está orientado a FPGA y cumple las especificaciones establecidas en la guía del curso de *Diseño y Verificación Digital*.

---

## ⚙️ Functional Description

### 🔹 PWM Core
- **Frecuencia base:** 50 MHz (input clock).  
- **Frecuencia PWM máxima:** 50 kHz.  
- **Frecuencia PWM calculada como:**
  \[
  f_{PWM} = \frac{50~kHz}{(2^{POW2})\cdot(5^{POW5})}
  \]
- **Valores válidos:** `POW2` y `POW5` ∈ {0, 1, 2, 3}.  
- **Duty cycle:** 0% – 99%, pasos de 1%.  
- **Pulsos centrados** (simetría en el periodo).  
- Duty cycles superiores a 99% se consideran inválidos y no alteran la salida.

---

### 🔹 UART Interface
- **Frecuencia del reloj:** 50 MHz  
- **Configuración:** 115200 baud, 1 start bit, 1 stop bit, sin paridad.  
- **Buffer RX:** 32 bytes de profundidad.  
  - Se detiene (stall) cuando está lleno.  
  - Se reinicia al recibir un carácter de fin de cadena (`\n`).  
  - Se activa una bandera de “end of string” cuando se completa un comando.  

---

### 🔹 Command Parser (HMI)
Los comandos recibidos por UART permiten modificar parámetros y consultar el estado del sistema.

| Comando | Descripción | Respuesta esperada |
|----------|--------------|--------------------|
| `HELP` | Muestra los comandos disponibles. | `HELP: DC## POW2# POW5# STATUS\n` |
| `STATUS` | Muestra el estado actual del PWM. | `DC=XX POW2=X POW5=X\n` |
| `DC##` | Cambia el duty cycle (0–99). | `OK` o `FAIL` |
| `POW2#` | Cambia el divisor base 2 (0–3). | `OK` o `FAIL` |
| `POW5#` | Cambia el divisor base 5 (0–3). | `OK` o `FAIL` |
| Otro texto | Comando inválido. | `FAIL` |

---

## 🧩 System Architecture

┌────────────────────────────┐
│ UART RX │
│ - 115200 bauds │
│ - Start/Stop detection │
│ - Buffer 32 bytes │
└────────────┬───────────────┘
│
▼
┌────────────────────────────┐
│ Command Parser │
│ - Interpreta comandos │
│ - Actualiza registros │
│ - Genera respuestas TX │
└────────────┬───────────────┘
│
┌────────┴────────┐
│ │
▼ ▼
┌───────────────┐ ┌───────────────┐
│ PWM Core │ │ UART TX │
│ - f_PWM calc. │ │ - FSM TX FSM │
│ - Duty cycle │ │ - 115200 bps │
│ - Pulsos centr │ │ - Envía OK/FAIL│
└───────────────┘ └───────────────┘


---

## 🧱 Project Structure

PWM_UART_Project/
│
├── rtl/ # Módulos sintetizables
│ ├── pwm_generator.v # Generador de señal PWM configurable
│ ├── uart_rx.v # Receptor UART (115200 bps)
│ ├── uart_tx.v # Transmisor UART
│ ├── command_parser.v # Intérprete de comandos UART
│ └── top_module.v # Integración completa
│
├── tb/ # Bancos de prueba
│ └── tb_pwm_uart.v # Testbench del sistema completo
│
├── docs/
│ ├── design_notes.md # Documentación técnica
│ └── diagram.png # Diagrama de bloques
│
├── README.md # Este archivo
└── Makefile / scripts/ # Scripts de simulación (opcional)


---

## 🧪 Verification & Validation

### 🔸 Testbench features
El testbench (`tb_pwm_uart.v`) modela:
- Transmisión UART bit a bit con start/stop bits.  
- Secuencias dirigidas de comandos (`HELP`, `STATUS`, `DC50`, `POW23`, etc.).  
- Verificación automática de respuestas `"OK"`, `"FAIL"`, `"STATUS"`.  
- Visualización de PWM actualizado en GTKWave.

### 🔸 Coverage
Se busca cubrir:
- Todos los valores válidos de `POW2` y `POW5` (0–3).  
- Duty cycle en 0%, 50%, 99%.  
- Comandos inválidos y recuperación del sistema.  
- Comportamiento del buffer RX (overflow/restart).  

### 🔸 Exit criteria
- ≥95% de bins funcionales alcanzados.  
- No hay fallas en protocolos ni metastabilidad.  
- Resultados consistentes en simulación y revisión de ondas.

---

## 🧰 Simulation Instructions (VS Code + Icarus Verilog)

### 🔹 Requisitos previos
Instala Icarus Verilog y GTKWave:
```bash
sudo apt install iverilog gtkwave
