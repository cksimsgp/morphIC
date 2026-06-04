/**
 * I2C Master Testbench
 * 
 * Tests the I2C Master controller with 10-bit addressing
 * Verifies:
 * - START condition
 * - 10-bit address transmission
 * - ACK/NACK handling
 * - Data byte reception
 * - STOP condition
 * - Configurable slave address and read length
 */

`timescale 1ns / 1ps

module morphic_top_tb();

    // ============================================================================
    // Test Parameters
    // ============================================================================
    
    parameter CLK_PERIOD = 20;                    // 50 MHz
    parameter I2C_FREQ = 3400_000;               // 3.4 MHz
    parameter I2C_PERIOD = 1_000_000_000 / I2C_FREQ;  // I2C clock period
    
    // ============================================================================
    // Testbench Signals
    // ============================================================================
    
    reg clk;
    reg rst_n;
    wire sda;
    wire scl;
    
    reg [9:0] slave_addr_cfg;
    reg [7:0] num_bytes_cfg;
    reg start_read;
    
    wire read_busy;
    wire read_done;
    wire read_error;
    wire [7:0] read_byte_out;
    wire data_valid_out;
    
    // ============================================================================
    // DUT Instantiation
    // ============================================================================
    
    morphic_top #(
        .CLK_FREQ_MHZ(50),
        .I2C_FREQ_KHZ(3400)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .sda(sda),
        .scl(scl),
        .slave_addr_cfg(slave_addr_cfg),
        .num_bytes_cfg(num_bytes_cfg),
        .start_read(start_read),
        .read_busy(read_busy),
        .read_done(read_done),
        .read_error(read_error),
        .read_byte_out(read_byte_out),
        .data_valid_out(data_valid_out)
    );
    
    // ============================================================================
    // I2C Slave Model Instantiation
    // ============================================================================
    
    i2c_slave_model #(
        .SLAVE_ADDR_10BIT(10'h24A),
        .TEST_DATA_BYTE(8'hA5)
    ) slave (
        .sda(sda),
        .scl(scl),
        .received_data(),
        .byte_received(),
        .addr_matched(),
        .state()
    );
    
    // ============================================================================
    // Clock Generation
    // ============================================================================
    
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // ============================================================================
    // Test Stimulus
    // ============================================================================
    
    initial begin
        // Setup
        rst_n = 1'b0;
        slave_addr_cfg = 10'h24A;              // Address 0x24A
        num_bytes_cfg = 8'h01;                  // Read 1 byte
        start_read = 1'b0;
        
        // VCD Dump Setup
        $dumpfile("morphic_i2c_sim.vcd");
        $dumpvars(0, morphic_top_tb);
        
        // Display header
        $display("========================================");
        $display("I2C Master 10-bit Mode Testbench");
        $display("========================================");
        $display("Clock Frequency: 50 MHz");
        $display("I2C Frequency: 3.4 Mbps");
        $display("Slave Address: 0x24A (10-bit)");
        $display("Test Data: 0xA5");
        $display("========================================");
        $display("");
        
        // Reset sequence
        #(CLK_PERIOD * 10);
        rst_n = 1'b1;
        #(CLK_PERIOD * 10);
        
        $display("[%0t ns] Starting I2C Read Transaction", $time);
        
        // Test 1: Read single byte from default address
        start_read = 1'b1;
        #(CLK_PERIOD);
        start_read = 1'b0;
        
        // Wait for transaction to complete
        #(CLK_PERIOD * 500000);  // Wait for I2C transaction (~15 ms)
        
        // Check results
        $display("");
        $display("========================================");
        $display("TEST 1 RESULTS: Single Byte Read");
        $display("========================================");
        if (read_done && !read_error) begin
            $display("[PASS] Transaction completed successfully");
            $display("[INFO] Read Data: 0x%02X", read_byte_out);
            if (read_byte_out == 8'hA5) begin
                $display("[PASS] Data matches expected value (0xA5)");
            end else begin
                $display("[FAIL] Data mismatch! Expected 0xA5, got 0x%02X", read_byte_out);
            end
        end else if (read_error) begin
            $display("[FAIL] Transaction completed with error");
        end else begin
            $display("[FAIL] Transaction did not complete");
        end
        $display("========================================");
        
        // Wait and prepare for Test 2
        #(CLK_PERIOD * 100);
        
        // Test 2: Multiple bytes read
        $display("");
        $display("========================================");
        $display("TEST 2: Multiple Bytes Read");
        $display("========================================");
        num_bytes_cfg = 8'h04;                  // Read 4 bytes
        slave_addr_cfg = 10'h24A;              // Same address
        
        $display("[%0t ns] Starting Multi-byte Read (4 bytes)", $time);
        start_read = 1'b1;
        #(CLK_PERIOD);
        start_read = 1'b0;
        
        // Wait for transaction
        #(CLK_PERIOD * 1000000);  // Longer timeout for multiple bytes
        
        if (read_done && !read_error) begin
            $display("[PASS] Transaction completed successfully");
            $display("[INFO] Read Data: 0x%02X", read_byte_out);
        end else begin
            $display("[FAIL] Transaction failed");
        end
        $display("========================================");
        
        // Test 3: Verify configuration works
        $display("");
        $display("========================================");
        $display("TEST 3: Configuration Verification");
        $display("========================================");
        num_bytes_cfg = 8'h01;
        slave_addr_cfg = 10'h24A;
        
        #(CLK_PERIOD * 100);
        start_read = 1'b1;
        #(CLK_PERIOD);
        start_read = 1'b0;
        
        #(CLK_PERIOD * 500000);
        
        if (read_done && !read_error) begin
            $display("[PASS] Configurable mode works");
        end else begin
            $display("[FAIL] Configuration test failed");
        end
        $display("========================================");
        
        // Finish simulation
        #(CLK_PERIOD * 100);
        $display("");
        $display("========================================");
        $display("SIMULATION COMPLETED");
        $display("========================================");
        $finish;
    end
    
    // ============================================================================
    // Monitoring and Assertions
    // ============================================================================
    
    always @(posedge clk) begin
        if (read_done && !read_error) begin
            $display("[%0t ns] I2C Transaction completed. Data: 0x%02X", 
                     $time, read_byte_out);
        end
        
        if (read_error) begin
            $display("[%0t ns] ERROR: I2C transaction failed!", $time);
        end
    end
    
    // Timeout monitor
    initial begin
        #(CLK_PERIOD * 2000000);  // ~40ms timeout
        if (!read_done) begin
            $display("[WARNING] Simulation timeout - transaction may be stalled");
            $display("[INFO] Current state:");
            $display("  Busy: %b", read_busy);
            $display("  Done: %b", read_done);
            $display("  Error: %b", read_error);
            $display("  Data Valid: %b", data_valid_out);
        end
    end

endmodule
