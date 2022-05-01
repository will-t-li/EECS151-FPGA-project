module uart_transmitter #(
    parameter CLOCK_FREQ = 125_000_000,
    parameter BAUD_RATE = 115_200)
(
    input clk,
    input reset,

    input [7:0] data_in,
    input data_in_valid,
    output data_in_ready,

    output serial_out
);
    // See diagram in the lab guide
    localparam  SYMBOL_EDGE_TIME    =   CLOCK_FREQ / BAUD_RATE;
    localparam SAMPLE_TIME = SYMBOL_EDGE_TIME / 2;
    localparam  CLOCK_COUNTER_WIDTH =   $clog2(SYMBOL_EDGE_TIME);

    wire tx_running;
    wire symbol_edge;
    wire sample;
    wire start;

    reg [3:0] bit_counter = 11;
    reg [7:0] data;
    reg [CLOCK_COUNTER_WIDTH-1:0] clock_counter;
    reg out;

    assign tx_running = bit_counter < 10;
    

    assign symbol_edge = clock_counter == (SYMBOL_EDGE_TIME - 1);
    assign sample = clock_counter == SAMPLE_TIME;
    assign start = data_in_valid && !tx_running;
    assign data_in_ready = !tx_running;
    assign serial_out = out;

    // Tick the clock
    always @ (posedge clk) begin
        clock_counter <= (data_in_valid || reset || symbol_edge) ? 0 : clock_counter + 1;
    end

    // Counts down from 10 bits for every character
    always @ (posedge clk) begin
        if (reset) begin
            bit_counter <= 10;
        end else if (start) begin
            bit_counter <= 0;
        end else if (symbol_edge && tx_running) begin
            bit_counter <= bit_counter + 1;
        end
    end

    // Consume new data
    always @ (posedge clk) begin
        if (reset)
            data <= 8'b0;
        else if (data_in_valid && !tx_running)
            data <= data_in;
        else
            data <= data;
    end
    
    // Send the packet
    always @ (posedge clk) begin
        if (tx_running) begin
            if (bit_counter == 0) begin
                out <= 0; // START_BIT
            end else if (bit_counter > 0 && bit_counter < 9) begin
                out <= data[bit_counter - 1];
            end else if (bit_counter == 9) begin
                out <= 1; // STOP_BIT
            end
        end 
        else 
            out <= 1;    
    end
endmodule
