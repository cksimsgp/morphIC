/**
 * I2C Slave Model for Simulation/Testing
 * 
 * Simulates a simple I2C slave device with 10-bit addressing
 * Responds to master requests and provides test data
 */

module i2c_slave_model #(
    parameter SLAVE_ADDR_10BIT = 10'h24A,
    parameter TEST_DATA_BYTE = 8'hA5               // Test data: 10100101
) (
    // I2C Lines
    inout wire sda,
    inout wire scl,
    
    // Debug outputs
    output reg [7:0] received_data,
    output reg byte_received,
    output reg addr_matched,
    output reg [3:0] state
);

    // FSM States
    localparam STATE_IDLE        = 4'h0;
    localparam STATE_RX_ADDR_HI  = 4'h1;
    localparam STATE_RX_ADDR_LO  = 4'h2;
    localparam STATE_TX_ACK      = 4'h3;
    localparam STATE_TX_DATA     = 4'h4;
    localparam STATE_RX_ACK      = 4'h5;
    
    // Internal signals
    wire sda_in = sda;
    wire scl_in = scl;
    reg sda_out;
    reg scl_out;
    
    reg [9:0] rx_addr;
    reg [7:0] tx_byte;
    reg [3:0] bit_count;
    reg [4:0] next_state;
    
    // Synchronization
    reg scl_r1, scl_r2;
    reg sda_r1, sda_r2;
    
    // I2C Lines - Open Drain
    assign sda = sda_out ? 1'bz : 1'b0;
    assign scl = scl_out ? 1'bz : 1'b0;
    
    // Edge detection
    always @(posedge scl_in) begin
        scl_r1 <= scl_in;
        scl_r2 <= scl_r1;
    end
    
    always @(posedge scl_in) begin
        sda_r1 <= sda_in;
        sda_r2 <= sda_r1;
    end
    
    wire scl_rising = ~scl_r1 & scl_in;
    wire sda_falling = sda_r1 & ~sda_in;     // START condition
    wire sda_rising = ~sda_r1 & sda_in;      // STOP condition
    
    // Main FSM
    always @(posedge scl_in or negedge scl_in) begin
        case (state)
            STATE_IDLE: begin
                sda_out <= 1'b1;
                scl_out <= 1'b1;
                addr_matched <= 1'b0;
                bit_count <= 4'h0;
                
                // Detect START condition (SDA falls while SCL high)
                if (sda_falling && scl_in) begin
                    state <= STATE_RX_ADDR_HI;
                    rx_addr <= 10'h0;
                end
            end
            
            STATE_RX_ADDR_HI: begin
                if (scl_rising) begin
                    // Receive 8 bits of address high byte
                    if (bit_count < 4'd8) begin
                        rx_addr[9] <= sda_in;
                        if (bit_count < 4'd7) begin
                            rx_addr[8:1] <= rx_addr[8:0];
                        end
                        bit_count <= bit_count + 1'b1;
                    end else begin
                        // Done with addr_hi, prepare ACK
                        sda_out <= 1'b0;     // Pull SDA LOW for ACK
                        bit_count <= 4'h0;
                        state <= STATE_RX_ADDR_LO;
                    end
                end
            end
            
            STATE_RX_ADDR_LO: begin
                if (!scl_in) begin
                    // SCL falling - release SDA after ACK
                    sda_out <= 1'b1;
                end
                
                if (scl_rising) begin
                    // Receive 8 bits of address low byte + R/W bit
                    if (bit_count < 4'd8) begin
                        if (bit_count == 4'h0) begin
                            // First bit is read bit
                            rx_addr[4:0] <= sda_in ? rx_addr[4:0] : rx_addr[4:0];
                        end else begin
                            rx_addr[bit_count + 4'd3] <= sda_in;
                        end
                        bit_count <= bit_count + 1'b1;
                    end else begin
                        // Check address match (10-bit)
                        if (rx_addr[9:1] == SLAVE_ADDR_10BIT[9:1] && sda_in == 1'b0) begin
                            addr_matched <= 1'b1;
                            sda_out <= 1'b0;  // Pull SDA LOW for ACK
                        end else begin
                            addr_matched <= 1'b0;
                        end
                        bit_count <= 4'h0;
                        state <= STATE_TX_ACK;
                    end
                end
            end
            
            STATE_TX_ACK: begin
                if (!scl_in) begin
                    sda_out <= 1'b1;        // Release SDA after ACK
                    if (addr_matched) begin
                        tx_byte <= TEST_DATA_BYTE;
                        state <= STATE_TX_DATA;
                    end else begin
                        state <= STATE_IDLE;
                    end
                end
            end
            
            STATE_TX_DATA: begin
                if (scl_rising) begin
                    if (bit_count < 4'd8) begin
                        // Output bit MSB first
                        sda_out <= ~tx_byte[7 - bit_count[2:0]];
                        bit_count <= bit_count + 1'b1;
                    end else begin
                        sda_out <= 1'b1;    // Release for ACK/NACK bit
                        bit_count <= 4'h0;
                        state <= STATE_RX_ACK;
                    end
                end
            end
            
            STATE_RX_ACK: begin
                if (scl_rising) begin
                    byte_received <= 1'b1;
                    received_data <= tx_byte;
                    
                    if (sda_in) begin
                        // NACK received - end of transaction
                        state <= STATE_IDLE;
                    end else begin
                        // ACK received - wait for STOP
                        state <= STATE_IDLE;
                    end
                end
            end
            
            default: state <= STATE_IDLE;
        endcase
    end

endmodule
