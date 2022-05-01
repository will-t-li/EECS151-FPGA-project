module debouncer #(
    parameter WIDTH              = 1,
    parameter SAMPLE_CNT_MAX     = 62500,
    parameter PULSE_CNT_MAX      = 200,
    parameter WRAPPING_CNT_WIDTH = $clog2(SAMPLE_CNT_MAX),
    parameter SAT_CNT_WIDTH      = $clog2(PULSE_CNT_MAX) + 1
) (
    input clk,
    input [WIDTH-1:0] glitchy_signal,
    output [WIDTH-1:0] debounced_signal
);

    /*
     * Framework
     */

    reg [WIDTH-1:0] debounced = 0;
    assign debounced_signal = debounced;

    /*
     * Sample Pulse Generator
     */

    reg [WRAPPING_CNT_WIDTH-1:0] wrapping_counter = 0;
    reg sample_cnt = 0;

    always @(posedge clk) begin
        if (wrapping_counter < SAMPLE_CNT_MAX) begin
            wrapping_counter <= wrapping_counter + 1'b1;
            sample_cnt <= 1'b0;
        end else begin
            wrapping_counter <= 0;
            sample_cnt <= 1'b1;
        end
    end

    /*
     * Debouncer
     */

    reg [SAT_CNT_WIDTH-1:0] saturating_counter [WIDTH-1:0];
    integer i;
    initial begin
        for (i = 0; i < WIDTH; i = i + 1) begin
            saturating_counter[i] = 0;
        end
    end

    integer j;
    always @(posedge clk) begin
        for (j = 0; j < WIDTH; j = j + 1) begin
            if (sample_cnt == 1) begin
                if (glitchy_signal[j]) begin
                    if (saturating_counter[j] < PULSE_CNT_MAX)
                        saturating_counter[j] <= saturating_counter[j] + 1;
                end else begin
                    saturating_counter[j] <= 0;
                end
            end
        end
    end

    integer k;
    always @(posedge clk) begin
        for (k = 0; k < WIDTH; k = k + 1) begin
            debounced[k] <= saturating_counter[k] >= PULSE_CNT_MAX ? 1'b1 : 1'b0;
        end
    end

endmodule
