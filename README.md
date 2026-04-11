# SPI-Controlled PWM Generator IP Core

A configurable PWM (Pulse Width Modulation) generator hardware peripheral implemented in Verilog, controlled via SPI communication. Designed as a reusable IP core that can be integrated into larger digital systems such as microcontrollers.

## Background

Many electronic devices, including microcontrollers like the ATmega328P found on Arduino Uno boards, contain dedicated circuits for generating PWM signals. These signals are extremely useful — they can drive optoelectronic components (LEDs) to adjust brightness, control the speed or direction of electric motors, and serve countless other applications.

PWM signals have several universal characteristics:

1. **Period** — The time in which the active and inactive sequence determined by the duty cycle must be completed. It can be expressed as a time interval or as a frequency (the inverse of the period).
2. **Duty Cycle** — The portion of the period during which the PWM signal is active. Usually expressed as a percentage or time unit.
3. **Alignment** — Determines how the PWM signal begins generation (either active-first or inactive-first).

<div align="center">

![PWM waveform example with different configurations](https://raw.githubusercontent.com/cs-pub-ro/computer-architecture/main/assignments/projects/pwmgen/media/example_pwm.png)

*Figure: Waveform for a PWM signal with a period of 8 clock cycles and a 75% duty cycle*

</div>

## Module Architecture

Peripheral architectures are not standardized — they are designed according to the manufacturer's requirements and the target market. As such, implementations vary between manufacturers, though the core functionality remains similar.

This module can be thought of as a peripheral that could be integrated into more complex designs, such as a microcontroller. The PWM generator consists of the following major components:

<div align="center">

![Top-level view of the peripheral and submodule connections](https://raw.githubusercontent.com/cs-pub-ro/computer-architecture/main/assignments/projects/pwmgen/media/top_level.png)

*Figure: Top-level view of the peripheral and the connections between submodules*

</div>

### Communication Bridge (SPI)

Every peripheral needs a method to communicate with the external environment so it can be programmed by the user (e.g., an embedded software engineer). The industry uses various communication protocols, each with its own advantages and tradeoffs.

This project uses [SPI](https://en.wikipedia.org/wiki/Serial_Peripheral_Interface) (Serial Peripheral Interface), a simple serial protocol. Key points:

- SPI is a **master-slave serial protocol** — messages are split into bits and sent over a line in a chosen order (MSB first in our case), from the master which requests or sends data to the slave.
- SPI has a clock signal (**SCLK**) used to synchronize data. The modifiers CPOL (clock polarity) and CPHA (clock phase) are both set to 0 in our design. This means data is placed on the line on the **falling edge** and sampled on the **rising edge**.
- **CS (Chip Select)** is an active-low signal that notifies the slave that the data line is active for upcoming transfers.
- There are 2 data lines: **MISO** (Master In Slave Out) and **MOSI** (Master Out Slave In). Since our peripheral is a slave, MISO is the write line and MOSI is the read line.

In our architecture, we assume **SCLK = 10 MHz and the peripheral clock = 10 MHz, with both clocks being synchronous**. Any number of 8-bit sequences can be communicated as long as CS is asserted (low).

### Instruction Decoder

The instruction decoder functions as an FSM that reads bit sequences and executes the operations described by the architect. It has the following stages, each one byte long:

**1. Setup Phase:** Processes the first byte of the message received via the SPI bridge. This byte contains all the information needed for a data transfer:

| Bits | Name       | Meaning |
|------|------------|---------|
| 7    | Read/Write | Indicates whether the instruction is a read (0) or write (1) operation |
| 6    | High/Low   | Specifies the register zone (MSB/LSB): 1 = bits [15:8], 0 = bits [7:0] |
| 5:0  | Address    | The address of the target register |

**2. Data Phase:** The actual data byte is received or transmitted based on what was identified in the setup phase. All data is transferred in 8-bit chunks, even though registers are 16 bits wide.

<div align="center">

![Waveform for a write operation](https://raw.githubusercontent.com/cs-pub-ro/computer-architecture/main/assignments/projects/pwmgen/media/write.png)

*Figure: Waveform for a write operation in 2 stages. Note: timing is relative to the SPI clock.*

</div>

In the figure above, after 8 SPI clock cycles the value `0x93` is captured. Breaking it into bits (`1001_0011`): this is a **write** operation to the **LSB** section of the 16-bit register space at address `0x13`.

### Register Block

Every peripheral needs a region to store configuration and operating mode information. In our design, configuration is stored in registers (D flip-flop cells), addressed in multiples of 8 bits:

| Name          | Address | Access | Width  | Description |
|:-------------:|:-------:|:------:|:------:|:------------|
| PERIOD        | 0x00    | R/W    | [15:0] | Counter period expressed in clock cycles |
| COUNTER_EN    | 0x02    | R/W    | 1      | Enables/disables the counter |
| COMPARE1      | 0x03    | R/W    | [15:0] | Value at which the PWM signal toggles |
| COMPARE2      | 0x05    | R/W    | [15:0] | Value at which the PWM signal toggles (used only in unaligned mode) |
| COUNTER_RESET | 0x07    | W      | 1      | Resets the counter value to 0; the register self-clears after the second clock cycle |
| COUNTER_VAL   | 0x08    | R      | [15:0] | Current counter value at the time the read instruction was issued |
| PRESCALE      | 0x0A    | R/W    | [7:0]  | Number of clock cycles before incrementing the counter (0→1, 1→2, 2→4, etc.) |
| UPNOTDOWN     | 0x0B    | R/W    | 1      | Counting direction: 1 = increment, 0 = decrement |
| PWM_EN        | 0x0C    | R/W    | 1      | Enables the PWM output channel; holds the output line in its current state when disabled |
| FUNCTIONS     | 0x0D    | R/W    | [1:0]  | Bit 0: left-aligned (0) / right-aligned (1). Bit 1: aligned (0) / unaligned (1) |

Any write to an undefined address is ignored. Any read from an undefined address returns 0.

### Counter

The counter is an essential part of the PWM generator — it provides the time base that determines the PWM signal's duration and fills the allocated period.

The counter's bit width determines the resolution at which the signal can be generated: more bits means finer control over the duty cycle. A **prescaler** limits the counter's increment rate, scaling the time base to a larger unit.

Counter features:
- **Time scaling:** Controlled by `PRESCALE`, an internal counter tracks how many clock cycles must pass before incrementing/decrementing the main counter value.
- **Counting settings:** Period (`PERIOD`), comparison values (`COMPARE1` and `COMPARE2`), and direction (`UPNOTDOWN`).
- **Other functions:** `COUNTER_RESET` resets counting registers without affecting the rest of the peripheral. `COUNTER_EN` activates the counter.

<div align="center">

![Counter with prescaler set to 4](https://raw.githubusercontent.com/cs-pub-ro/computer-architecture/main/assignments/projects/pwmgen/media/counter_prescale.png)

*Figure: Counter waveform with prescaler set to 2 (counts 4 clock cycles per counter increment).*

</div>

### PWM Generator

The PWM generator interfaces with the outside world — the signal is routed to the external device being controlled (LED, motor, transistor driver, etc.). The generation mode is determined by `PWM_EN` and `FUNCTIONS` registers, while signal characteristics depend on the counter configuration.

**PWM generation mechanism:**

1. Register values are configured: period (`PERIOD`), comparison values (`COMPARE1` and/or `COMPARE2`), operating mode (`FUNCTIONS`), prescaler (`PRESCALE`), and counting direction (`UPNOTDOWN`).
2. The counter starts when `COUNTER_EN` is set to 1. The PWM signal begins generating when `PWM_EN` is activated.
3. Based on `FUNCTIONS`:
   - **Left-aligned** (`FUNCTIONS[0]=0, FUNCTIONS[1]=0`): PWM starts HIGH
   - **Right-aligned** (`FUNCTIONS[0]=1, FUNCTIONS[1]=0`): PWM starts LOW
4. When the counter reaches `COMPARE1`, the PWM output toggles to the opposite state and continues until the counter overflows/underflows, then restarts from step 3.
5. **Unaligned mode** (`FUNCTIONS[1]=1`): PWM starts LOW, goes HIGH when counter reaches `COMPARE1`, and resets to LOW when counter reaches `COMPARE2`. This mode is designed for `COMPARE1 < COMPARE2` only.

<div align="center">

![Left-aligned and right-aligned PWM signal](https://raw.githubusercontent.com/cs-pub-ro/computer-architecture/main/assignments/projects/pwmgen/media/pwm_aligned.png)

*Figure: Left-aligned and right-aligned PWM signals (prescale = 1). The signal toggles immediately when the counter reaches a compare value.*

</div>

<div align="center">

![Unaligned PWM signal](https://raw.githubusercontent.com/cs-pub-ro/computer-architecture/main/assignments/projects/pwmgen/media/pwm_unaligned.png)

*Figure: Unaligned PWM signal (prescale = 0). The signal activates and deactivates as the counter reaches the compare values.*

</div>

**Additional notes:**

1. PWM activation and counter activation are independent — both must be enabled for `pwm_out` to produce a PWM signal.
2. Register values can be modified while `COUNTER_EN` or `PWM_EN` are active, but changes only take effect on the next counter overflow/underflow or when the counter stops.
3. `COUNTER_VAL` exposes the current counter value for software reads.
4. `COUNTER_RESET` resets only the counter value, not other parameters.

## Tech Stack

- **Language:** Verilog
- **Protocol:** SPI (Serial Peripheral Interface)
- **Tools:** Any Verilog simulator (e.g., ModelSim, Icarus Verilog)

## Project Structure

```
├── src/           # Verilog source files
├── media/         # Diagrams and waveform images
├── doc.pdf        # Project documentation
└── README.md
```

## License

This project was developed as a university assignment at [Politehnica Bucharest (UNSTPB)](https://www.unstpb.ro/), Faculty of Automatic Control and Computer Science.
