module cafeteria_part1(
    input clk,
    input rst,
    input [31:0] data_in,
    input valid_in,
    output ready,
    output reg finished,
    output reg [10:0] result
);
    localparam NUM_RANGE = 182;
    localparam NUM_ID = 1000;
    localparam WIDTH = 50;
    localparam CHUNK1 = 1'b0;
    localparam CHUNK2 = 1'b1;

    reg [WIDTH-1:0] start_range [0:NUM_RANGE-1];
    reg [WIDTH-1:0] end_range [0:NUM_RANGE-1];

    initial begin
        $readmemb("start_range.mem", start_range);
        $readmemb("end_range.mem", end_range);
    end

    reg word_cnt;
    reg [WIDTH-1:0] buffer;
    reg input_ready;

    reg stage2_valid;
    reg [WIDTH-1:0] stage2_id;
    wire [NUM_RANGE-1:0] compare_start;
    wire [NUM_RANGE-1:0] compare_end;

    reg stage3_valid;
    reg [NUM_RANGE-1:0] stage3_compare_start;
    reg [NUM_RANGE-1:0] stage3_compare_end;
    wire [NUM_RANGE-1:0] in_range_stage3;

    reg stage4_valid;
    reg stage4_in_range;

    reg [10:0] count_valid;
    reg [10:0] count_result;

    assign ready = 1'b1;

    always @(posedge clk) begin
        if (rst) begin
            word_cnt <= CHUNK1;
            input_ready <= 0;
            buffer <= 0;
        end else begin
            input_ready <= 0;
            if (valid_in) begin
                if (word_cnt == CHUNK1) begin
                    buffer[31:0] <= data_in;
                    word_cnt <= CHUNK2;
                end else begin
                    buffer[49:32] <= data_in[17:0];
                    word_cnt <= CHUNK1;
                    input_ready <= 1;
                end
            end
        end
    end

    genvar i;
    generate
        for(i = 0; i < NUM_RANGE; i = i + 1) begin : compare_stage
            assign compare_start[i] = (stage2_id >= start_range[i]);
            assign compare_end[i] = (stage2_id <= end_range[i]);
        end
    endgenerate

    always @(posedge clk) begin
        if(rst) begin
            stage2_valid <= 0;
            stage2_id <= 0;
        end else begin
            stage2_valid <= input_ready;
            if(input_ready) begin
                stage2_id <= buffer;
            end
        end
    end

    generate
        for(i = 0; i < NUM_RANGE; i = i + 1) begin : and_stage
            assign in_range_stage3[i] = stage3_compare_start[i] && stage3_compare_end[i];
        end
    endgenerate

    always @(posedge clk) begin
        if(rst) begin
            stage3_valid <= 0;
            stage3_compare_start <= 0;
            stage3_compare_end <= 0;
        end else begin
            stage3_valid <= stage2_valid;
            if(stage2_valid) begin
                stage3_compare_start <= compare_start;
                stage3_compare_end <= compare_end;
            end
        end
    end

    wire is_in_range = |in_range_stage3;

    always @(posedge clk) begin
        if(rst) begin
            stage4_valid <= 0;
            stage4_in_range <= 0;
        end else begin
            stage4_valid <= stage3_valid;
            if(stage3_valid) begin
                stage4_in_range <= is_in_range;
            end
        end
    end

    always @(posedge clk) begin
        if(rst) begin
            count_valid <= 0;
            count_result <= 0;
            finished <= 0;
            result <= 0;
        end else if(stage4_valid) begin
            count_valid <= count_valid + 1;
            if(stage4_in_range) begin
                count_result <= count_result + 1;
            end

            if(count_valid == NUM_ID - 1) begin
                finished <= 1;
                result <= count_result + (stage4_in_range ? 1 : 0);
            end
        end
    end
endmodule