module trash_compactor_part1 (
    input clk,
    input rst,
    input [31:0] data_in,
    input valid_in,
    output ready,
    output reg finished,
    output reg [63:0] result  
);
    localparam DATA_WIDTH = 16;
    localparam NUM_ELEMENTS = 1000;  
    localparam RESULT_WIDTH = 64;
    localparam PARALLEL = 10; 
    
    reg [DATA_WIDTH-1:0] line1 [0:NUM_ELEMENTS-1];
    reg [DATA_WIDTH-1:0] line2 [0:NUM_ELEMENTS-1];
    reg [DATA_WIDTH-1:0] line3 [0:NUM_ELEMENTS-1];
    reg [DATA_WIDTH-1:0] line4 [0:NUM_ELEMENTS-1];
    reg op [0:NUM_ELEMENTS-1];
    
    reg [1:0] state;
    reg [15:0] idx [0:PARALLEL-1];
    reg [RESULT_WIDTH-1:0] sum_accumulator;
    
    reg [RESULT_WIDTH-1:0] stage1_results [0:PARALLEL-1];
    reg stage1_valid;
    
    reg [RESULT_WIDTH-1:0] stage2_sum;
    reg stage2_valid;

    reg [DATA_WIDTH-1:0] pipeline_line1 [0:PARALLEL-1];
    reg [DATA_WIDTH-1:0] pipeline_line2 [0:PARALLEL-1];
    reg [DATA_WIDTH-1:0] pipeline_line3 [0:PARALLEL-1];
    reg [DATA_WIDTH-1:0] pipeline_line4 [0:PARALLEL-1];
    reg pipeline_op [0:PARALLEL-1];
    reg [15:0] pipeline_idx [0:PARALLEL-1][0:1];
    reg pipeline_valid;

    reg [RESULT_WIDTH-1:0] stage1a_results [0:PARALLEL-1];
    reg [RESULT_WIDTH-1:0] stage1b_results [0:PARALLEL-1];
    reg stage1a_valid, stage1b_valid;

    reg pipeline_op_stage1a [0:PARALLEL-1];
    reg pipeline_op_stage1b [0:PARALLEL-1];
    
    reg [DATA_WIDTH-1:0] pipeline_line3_stage1a [0:PARALLEL-1];
    reg [DATA_WIDTH-1:0] pipeline_line4_stage1a [0:PARALLEL-1];
    reg [DATA_WIDTH-1:0] pipeline_line4_stage1b [0:PARALLEL-1];
    
    localparam IDLE = 2'd0;
    localparam RUNNING = 2'd1;
    localparam DRAIN = 2'd2;
    localparam DONE = 2'd3;

    initial begin
        $readmemh("line1_1.mem", line1);
        $readmemh("line2_1.mem", line2);
        $readmemh("line3_1.mem", line3);
        $readmemh("line4_1.mem", line4);
        $readmemh("op.mem", op);
    end

    wire [RESULT_WIDTH-1:0] tree_level1 [0:4];  
    wire [RESULT_WIDTH-1:0] tree_level2 [0:1];  
    wire [RESULT_WIDTH-1:0] tree_level3;        
    wire [RESULT_WIDTH-1:0] parallel_sum;
    
    genvar g;
    generate
        for (g = 0; g < 5; g = g + 1) begin : gen_tree_level1
            assign tree_level1[g] = stage1_results[g*2] + stage1_results[g*2+1];
        end
        for (g = 0; g < 2; g = g + 1) begin : gen_tree_level2
            assign tree_level2[g] = tree_level1[g*2] + tree_level1[g*2+1];
        end
        assign tree_level3 = tree_level2[0] + tree_level2[1];
        assign parallel_sum = tree_level3 + tree_level1[4];
    endgenerate

    integer i;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            for (i = 0; i < PARALLEL; i = i + 1) idx[i] <= 0;
            sum_accumulator <= 0;
            stage1_valid <= 0;
            stage2_valid <= 0;
            finished <= 0;
            result <= 0;
            pipeline_valid <= 0;
            stage1a_valid <= 0;
            stage1b_valid <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        state <= RUNNING;
                        for (i = 0; i < PARALLEL; i = i + 1) idx[i] <= i;
                        sum_accumulator <= 0;
                        stage1_valid <= 0;
                        stage2_valid <= 0;
                        finished <= 0;
                    end
                end
                RUNNING: begin
                    // read mem
                    if (idx[0] < NUM_ELEMENTS) begin
                        for (i = 0; i < PARALLEL; i = i + 1) begin
                            if (idx[i] < NUM_ELEMENTS) begin
                                pipeline_line1[i] <= line1[idx[i]];
                                pipeline_line2[i] <= line2[idx[i]];
                                pipeline_line3[i] <= line3[idx[i]];
                                pipeline_line4[i] <= line4[idx[i]];
                                pipeline_op[i] <= op[idx[i]];
                            end else begin
                                pipeline_line1[i] <= 0;
                                pipeline_line2[i] <= 0;
                                pipeline_line3[i] <= 0;
                                pipeline_line4[i] <= 0;
                                pipeline_op[i] <= 0;
                            end
                        end
                        pipeline_valid <= 1;
                        for (i = 0; i < PARALLEL; i = i + 1) 
                            idx[i] <= idx[i] + PARALLEL;
                    end else begin
                        pipeline_valid <= 0;
                        state <= DRAIN;
                    end
                    
                    // first op
                    if (pipeline_valid) begin
                        for (i = 0; i < PARALLEL; i = i + 1) begin
                            if (pipeline_op[i] == 1'b0) begin 
                                stage1a_results[i] <= pipeline_line1[i] * pipeline_line2[i];
                            end else begin  
                                stage1a_results[i] <= pipeline_line1[i] + pipeline_line2[i];
                            end
                            pipeline_op_stage1a[i] <= pipeline_op[i];
                            pipeline_line3_stage1a[i] <= pipeline_line3[i];
                            pipeline_line4_stage1a[i] <= pipeline_line4[i];
                        end
                        stage1a_valid <= 1;
                    end else begin
                        stage1a_valid <= 0;
                    end
                    // second op
                    if (stage1a_valid) begin
                        for (i = 0; i < PARALLEL; i = i + 1) begin
                            if (pipeline_op_stage1a[i] == 1'b0) begin 
                                stage1b_results[i] <= stage1a_results[i] * pipeline_line3_stage1a[i];
                            end else begin  
                                stage1b_results[i] <= stage1a_results[i] + pipeline_line3_stage1a[i];
                            end
                            pipeline_op_stage1b[i] <= pipeline_op_stage1a[i];  
                            pipeline_line4_stage1b[i] <= pipeline_line4_stage1a[i];
                        end
                        stage1b_valid <= 1; 
                    end else begin
                        stage1b_valid <= 0;  
                    end
                    // third op
                    if (stage1b_valid) begin
                        for (i = 0; i < PARALLEL; i = i + 1) begin
                            if (pipeline_op_stage1b[i] == 1'b0) begin 
                                stage1_results[i] <= stage1b_results[i] * pipeline_line4_stage1b[i];
                            end else begin  
                                stage1_results[i] <= stage1b_results[i] + pipeline_line4_stage1b[i];
                            end
                        end
                        stage1_valid <= 1;  
                    end else begin
                        stage1_valid <= 0;  
                    end
                    
                    if (stage1_valid) begin
                        stage2_sum <= parallel_sum;
                        stage2_valid <= 1;
                    end else begin
                        stage2_valid <= 0;
                    end
                    
                    if (stage2_valid) begin
                        sum_accumulator <= sum_accumulator + stage2_sum;
                    end
                end
                DRAIN: begin
                    if (pipeline_valid) begin
                        for (i = 0; i < PARALLEL; i = i + 1) begin
                            if (pipeline_op[i] == 1'b0) begin 
                                stage1a_results[i] <= pipeline_line1[i] * pipeline_line2[i];
                            end else begin  
                                stage1a_results[i] <= pipeline_line1[i] + pipeline_line2[i];
                            end
                            pipeline_op_stage1a[i] <= pipeline_op[i];
                            pipeline_line3_stage1a[i] <= pipeline_line3[i];
                            pipeline_line4_stage1a[i] <= pipeline_line4[i];
                        end
                        stage1a_valid <= 1;
                    end else begin
                        stage1a_valid <= 0;
                    end

                    if (stage1a_valid) begin
                        for (i = 0; i < PARALLEL; i = i + 1) begin
                            if (pipeline_op_stage1a[i] == 1'b0) begin 
                                stage1b_results[i] <= stage1a_results[i] * pipeline_line3_stage1a[i];
                            end else begin  
                                stage1b_results[i] <= stage1a_results[i] + pipeline_line3_stage1a[i];
                            end
                            pipeline_op_stage1b[i] <= pipeline_op_stage1a[i];
                            pipeline_line4_stage1b[i] <= pipeline_line4_stage1a[i];
                        end
                        stage1b_valid <= 1;
                    end else begin
                        stage1b_valid <= 0;
                    end

                    if (stage1b_valid) begin
                        for (i = 0; i < PARALLEL; i = i + 1) begin
                            if (pipeline_op_stage1b[i] == 1'b0) begin 
                                stage1_results[i] <= stage1b_results[i] * pipeline_line4_stage1b[i];
                            end else begin  
                                stage1_results[i] <= stage1b_results[i] + pipeline_line4_stage1b[i];
                            end
                        end
                        stage1_valid <= 1;
                    end else begin
                        stage1_valid <= 0;
                    end
                    
                    if (stage1_valid) begin
                        stage2_sum <= parallel_sum;
                        stage2_valid <= 1;
                    end else begin
                        stage2_valid <= 0;
                    end
                    
                    if (stage2_valid) begin
                        sum_accumulator <= sum_accumulator + stage2_sum;
                    end
                    
                    if (!pipeline_valid && !stage1a_valid && !stage1b_valid && !stage1_valid && !stage2_valid) begin
                        state <= DONE;
                    end
                end
                DONE: begin
                    result <= sum_accumulator;
                    finished <= 1;
                end
            endcase
        end
    end
endmodule