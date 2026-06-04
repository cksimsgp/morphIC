# I2C Master Implementation Guide

## Integration with System Design

This guide shows how to integrate the I2C Master controller into your FTDI MorphIC II design.

---

## Module Instantiation

### Basic Instantiation

```verilog
module my_system (
    input wire clk,
    input wire rst_n,
    inout wire sda,
    inout wire scl
);

    // I2C Master instantiation
    morphic_top #(
        .CLK_FREQ_MHZ(50),           // System clock frequency
        .I2C_FREQ_KHZ(3400)          // I2C speed
    ) i2c_master_inst (
        .clk(clk),
        .rst_n(rst_n),
        .sda(sda),
        .scl(scl),
        
        // Configuration
        .slave_addr_cfg(10'h24A),    // Default address
        .num_bytes_cfg(8'h01),       // Read 1 byte
        .start_read(start_signal),
        
        // Status
        .read_busy(busy),
        .read_done(done),
        .read_error(error),
        .read_byte_out(data),
        .data_valid_out(data_valid)
    );

endmodule
```

---

## Control Logic Examples

### Example 1: Simple Polling State Machine

```verilog
// Simple state machine to manage I2C transactions
localparam STATE_IDLE  = 2'h0;
localparam STATE_START = 2'h1;
localparam STATE_WAIT  = 2'h2;
localparam STATE_DONE  = 2'h3;

reg [1:0] state, next_state;
reg [31:0] wait_counter;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= STATE_IDLE;
        start_read <= 1'b0;
        wait_counter <= 32'h0;
    end else begin
        state <= next_state;
    end
end

always @(*) begin
    case (state)
        STATE_IDLE: begin
            start_read <= 1'b0;
            if (start_transaction) begin
                next_state <= STATE_START;
            end else begin
                next_state <= STATE_IDLE;
            end
        end
        
        STATE_START: begin
            start_read <= 1'b1;
            next_state <= STATE_WAIT;
        end
        
        STATE_WAIT: begin
            start_read <= 1'b0;
            if (read_done || read_error) begin
                next_state <= STATE_DONE;
            end else begin
                next_state <= STATE_WAIT;
            end
        end
        
        STATE_DONE: begin
            start_read <= 1'b0;
            next_state <= STATE_IDLE;
        end
        
        default: next_state <= STATE_IDLE;
    endcase
end
```

### Example 2: Multi-Sensor Reading

```verilog
// Read from multiple I2C sensors sequentially
localparam NUM_SENSORS = 4;
localparam [9:0] SENSOR_ADDRS[0:3] = {
    10'h200,  // Sensor 0
    10'h201,  // Sensor 1
    10'h202,  // Sensor 2
    10'h203   // Sensor 3
};

reg [3:0] sensor_idx;
reg [7:0] sensor_data[0:3];
reg [3:0] state;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sensor_idx <= 4'h0;
        state <= 4'h0;
    end else begin
        case (state)
            // Initiate read
            4'h1: begin
                slave_addr_cfg <= SENSOR_ADDRS[sensor_idx];
                num_bytes_cfg <= 8'h01;
                start_read <= 1'b1;
                state <= 4'h2;
            end
            
            // Wait for completion
            4'h2: begin
                start_read <= 1'b0;
                if (read_done) begin
                    sensor_data[sensor_idx] <= read_byte_out;
                    if (sensor_idx < (NUM_SENSORS - 1)) begin
                        sensor_idx <= sensor_idx + 1'b1;
                        state <= 4'h1;
                    end else begin
                        state <= 4'h3;  // All sensors read
                    end
                end
            end
        endcase
    end
end
```

### Example 3: Register-Based Configuration

```verilog
// Register interface for dynamic configuration
reg [9:0] reg_slave_addr;
reg [7:0] reg_num_bytes;
reg reg_start;

wire [15:0] status_reg = {
    4'h0,
    read_error,
    read_done,
    read_busy,
    8'h0
};

// Register read/write logic
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        reg_slave_addr <= 10'h24A;
        reg_num_bytes <= 8'h01;
        reg_start <= 1'b0;
    end else begin
        // Write logic from system bus
        if (reg_write && reg_addr == 8'h00) begin
            reg_slave_addr <= reg_data[9:0];
        end
        
        if (reg_write && reg_addr == 8'h01) begin
            reg_num_bytes <= reg_data[7:0];
        end
        
        if (reg_write && reg_addr == 8'h02) begin
            reg_start <= reg_data[0];
        end else begin
            reg_start <= 1'b0;
        end
    end
end

assign slave_addr_cfg = reg_slave_addr;
assign num_bytes_cfg = reg_num_bytes;
assign start_read = reg_start;
```

---

## Pin Configuration (Vivado)

### TCL Script for Pin Assignment

```tcl
# Set I2C pins as open-drain with pull-ups
set_property -dict {IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 4} [get_ports sda]
set_property -dict {IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 4} [get_ports scl]

# Configure as open-drain by using pullup
set_property PULLUP TRUE [get_ports sda]
set_property PULLUP TRUE [get_ports scl]
```

### Manual Pin Assignment

1. Right-click port in Vivado
2. Select "I/O Ports"
3. Set IOSTANDARD to LVCMOS33
4. Set SLEW to SLOW (minimize switching noise)
5. Set DRIVE to 4 or less
6. Apply constraints

---

## Hardware Integration

### I2C Bus Topology

```
        VCC (3.3V/5V)
          |
      [R1][R2]  (1.5k-4.7k Ω pull-ups)
          |
      +---+---+
      |       |
      |       |
    SCL     SDA
      |       |
      |       |
   FPGA    Slave
   Board   Device
      |       |
      └───┬───┘
          |
    (Physical Bus)
```

### PCB Layout Considerations

1. **Pull-up Resistors:** Place close to FPGA
2. **Trace Length:** Keep SCL/SDA traces short and equal length
3. **Decoupling:** Add 100nF capacitors near FPGA I/O
4. **Termination:** Optional 100-200Ω series resistors for fast rise times

### External Components Needed

```
Per I2C Line (SCL and SDA):
- Pull-up Resistor: 2.2k-4.7k Ω (1/4W)
- 0.1µF Decoupling Capacitor (optional)
- 100-200Ω Series Resistor (optional, for protection)

Recommended for 3.3V System:
- 2.2k Ω pull-ups
- 0.1µF caps to GND
- 150Ω series resistors
```

---

## Timing Considerations

### Clock Domain Analysis

```
System Clock: 50 MHz (20 ns period)
I2C Clock: 3.4 MHz (294 ns period)
Divider: 4 (generates quarter-period clock)

I2C Timing:
- Quarter Period: ~73.5 ns
- SCL High Time: ~147 ns
- SCL Low Time: ~147 ns
- SDA Setup: < 20 ns
- SDA Hold: > 0 ns
```

### Timing Path Verification

Check timing reports after synthesis:

```bash
# In Vivado
report_timing -delay_type max -max_paths 10
report_timing -from [get_clocks clk] -to [get_ports scl]
report_timing -from [get_clocks clk] -to [get_ports sda]
```

---

## Debugging and Verification

### Simulation Waveform Analysis

Key signals to monitor in waveform:

```
1. clk - System clock
2. scl - I2C clock line
3. sda - I2C data line
4. read_busy - Master busy signal
5. read_done - Transaction complete
6. read_error - Error indicator
7. read_byte_out[7:0] - Read data
8. data_valid_out - Data valid pulse
```

### Logic Analyzer Capture

Connect logic analyzer to I2C lines:

1. **Trigger:** SCL falling edge
2. **Sample Rate:** Min 10 MHz (preferably 50 MHz+)
3. **Capture Length:** 100-200 µs
4. **Decode:** I2C protocol analyzer

Expected capture for single byte read:
- START condition
- 10-bit address (11 bits with ACK)
- 8-bit data
- 1-bit ACK/NACK
- STOP condition

### Oscilloscope Measurements

1. **SCL Rise Time:** < 200 ns
2. **SDA Rise Time:** < 200 ns
3. **SCL Low Time:** ~147 ns
4. **SCL High Time:** ~147 ns
5. **Data Setup Time:** > 20 ns
6. **Data Hold Time:** > 20 ns

---

## Parameterization Examples

### High-Speed Mode (3.4 Mbps)

```verilog
i2c_master #(
    .CLK_FREQ_MHZ(50),
    .I2C_FREQ_KHZ(3400)
) i2c (...)
```

### Standard Mode (100 kHz)

```verilog
i2c_master #(
    .CLK_FREQ_MHZ(50),
    .I2C_FREQ_KHZ(100)
) i2c (...)
```

### Fast Mode (400 kHz)

```verilog
i2c_master #(
    .CLK_FREQ_MHZ(50),
    .I2C_FREQ_KHZ(400)
) i2c (...)
```

---

## Common Issues and Solutions

### Issue 1: I2C Bus Stuck LOW

**Symptoms:** SCL or SDA always LOW on logic analyzer

**Causes:**
- FPGA output driving instead of releasing
- Slave device holding line LOW
- Missing pull-up resistors

**Solution:**
- Check `scl_en` and `sda_en` logic in RTL
- Verify pull-up resistors installed
- Test with multimeter in analog mode

### Issue 2: Data Corruption

**Symptoms:** Read data doesn't match expected value

**Causes:**
- Timing violations
- EMI interference
- Incorrect slave address

**Solution:**
- Reduce I2C frequency
- Add shielding to I2C lines
- Verify address matches hardware
- Check waveforms on oscilloscope

### Issue 3: NACK on Address

**Symptoms:** Transaction fails at address ACK phase

**Causes:**
- Slave not responding
- Wrong address
- Slave device powered off

**Solution:**
- Verify slave device power
- Check slave address configuration
- Test slave independently
- Use I2C scanner tool

---

## Testing Checklist

Before deployment:

- [ ] Simulation passes all tests
- [ ] Synthesis completes without errors
- [ ] No timing violations reported
- [ ] Place & Route successful
- [ ] Bitstream generated without warnings
- [ ] FPGA programs successfully
- [ ] SCL/SDA lines measured at correct voltage
- [ ] I2C transactions visible on logic analyzer
- [ ] Data matches expected values
- [ ] Multiple transactions tested
- [ ] Error handling verified

---

## Performance Tuning

### Optimization Strategies

1. **Reduce Clock Divider:** Increases I2C speed (up to 3400 kHz)
2. **Pipeline Logic:** Add registers for timing closure
3. **Place & Route:** Use interactive P&R for critical paths
4. **Constraints:** Relax non-critical path constraints

### Area Optimization

- Remove unused status signals
- Simplify FSM (combine states if possible)
- Reduce data width if not needed

### Power Optimization

- Lower I2C clock frequency if possible
- Use deep power-down between transactions
- Disable unused I/O banks

---

## References

- I2C Specification v6.0 (NXP UM10204)
- Xilinx Vivado User Guide
- FTDI MorphIC II Documentation
- IEEE 1364-2005 (Verilog HDL)

---

**Document Version:** 1.0  
**Last Updated:** 2025
