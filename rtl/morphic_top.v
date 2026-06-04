/**
 * FTDI MorphIC II I2C Master Top-Level Module
 * 
 * This module provides:
 * - I2C Master Controller instantiation
 * - GPIO interface for user control
 * - Configuration registers
 * - Status monitoring
 * 
 * Target: FTDI MorphIC II FPGA Board
 */

module morphic_top #(
    parameter CLK_FREQ_MHZ = 50,
    parameter I2C_FREQ_KHZ = 3400
) (
    // System Clock and Reset
    input wire clk,
    input wire rst_n,
    
    // I2C Interface (open-drain, pulled up externally)
    inout wire sda,
    inout wire scl,
    
    // Control Interface (GPIO or register-based)
    input wire [9:0] slave_addr_cfg,          // Configurable slave address
    input wire [7:0] num_bytes_cfg,           // Number of bytes to read
    input wire start_read,                    // Start transaction
    
    // Status Interface
    output wire read_busy,
    output wire read_done,
    output wire read_error,
    
    // Data Interface
    output wire [7:0] read_byte_out,
    output wire data_valid_out
);

    // ============================================================================
    // I2C Master Instantiation
    // ============================================================================
    
    i2c_master #(
        .CLK_FREQ_MHZ(CLK_FREQ_MHZ),
        .I2C_FREQ_KHZ(I2C_FREQ_KHZ),
        .SLAVE_ADDR(10'h24A),                 // Default address
        .NUM_BYTES(8'h01)                      // Default 1 byte
    ) i2c_master_inst (
        .clk(clk),
        .rst_n(rst_n),
        
        // I2C Lines
        .sda(sda),
        .scl(scl),
        
        // Configuration
        .cfg_slave_addr(slave_addr_cfg),
        .cfg_num_bytes(num_bytes_cfg),
        
        // Control
        .start_transaction(start_read),
        
        // Status
        .busy(read_busy),
        .done(read_done),
        .error(read_error),
        .read_data(read_byte_out),
        .data_valid(data_valid_out),
        
        // Debug
        .state()
    );

endmodule
