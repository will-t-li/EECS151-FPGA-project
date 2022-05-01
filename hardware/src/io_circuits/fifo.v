module fifo #(
    parameter WIDTH = 32,
    parameter DEPTH = 8,
    parameter POINTER_WIDTH = $clog2(DEPTH)
) (
    input clk, rst,

    // Write side
    input wr_en,
    input [WIDTH-1:0] din,
    output full,

    // Read side
    input rd_en,
    output [WIDTH-1:0] dout,
    output empty
);
    reg [WIDTH-1:0] ram [0:DEPTH-1];
    reg [POINTER_WIDTH:0] cnt;
    reg [POINTER_WIDTH-1:0] read_ptr;
    reg [POINTER_WIDTH-1:0] write_ptr;
    reg [WIDTH-1:0] data;

    assign empty = (cnt == 0) ? 1'b1 : 1'b0; 
    assign full = (cnt >= DEPTH) ? 1'b1 : 1'b0; 
    assign dout = data;
    //assign dout = ram[read_ptr];

    // COUNT
    always @(negedge clk) begin
        if (rst) begin
            cnt <= 0;
        end else if (wr_en && !rd_en && !full) begin
            cnt <= cnt + 1;
        end else if (!wr_en && rd_en && !empty) begin
            cnt <= cnt - 1;
        end else if (wr_en && rd_en && empty) begin
            cnt <= cnt + 1;
        end else if (wr_en && rd_en && full) begin
            cnt <= cnt - 1;
        end else begin
            cnt <= cnt;
        end
    end

    always @(negedge clk) begin
        if (rst) begin
            write_ptr <= 0;  
            read_ptr <= 0;
        end else begin
            if (wr_en && rd_en && !empty && !full) begin
                ram[write_ptr] = din;
                data = ram[read_ptr];
                write_ptr <= write_ptr + 1;
                read_ptr <= read_ptr + 1;
            end else if (wr_en && !full) begin
                ram[write_ptr] = din;
                write_ptr <= write_ptr + 1;
                read_ptr <= read_ptr;
            end else if (rd_en && !empty) begin
                data = ram[read_ptr];
                write_ptr <= write_ptr;
                read_ptr <= read_ptr + 1;
            end else begin
                write_ptr <= write_ptr;
                read_ptr <= read_ptr;
            end
        end
    end
endmodule
