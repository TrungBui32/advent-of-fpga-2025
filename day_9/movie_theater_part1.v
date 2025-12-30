module movie_theater_part1(
    input clk,
    input rst,
    input start,
    output reg finished,
    output reg [64:0] result
);

    localparam NUM_ELEMENTS = 496;
    localparam DATA_WIDTH = 64;

    localparam IDLE = 2'd0;
    localparam PROCESS = 2'd1;
    localparam DONE = 2'd2;
    
    reg [DATA_WIDTH-1:0] x [0:NUM_ELEMENTS-1];
    reg [DATA_WIDTH-1:0] y [0:NUM_ELEMENTS-1];

    reg [1:0] state;
    reg [15:0] i, j;
    
    reg [DATA_WIDTH-1:0] stage1_x_i, stage1_x_j;
    reg [DATA_WIDTH-1:0] stage1_y_i, stage1_y_j;
    reg stage1_valid;
    
    reg [DATA_WIDTH-1:0] stage2_dx, stage2_dy;
    reg stage2_valid;
    
    reg [DATA_WIDTH-1:0] stage3_area;
    reg stage3_valid;
    
    reg [DATA_WIDTH-1:0] largest_area;
    
    initial begin
        $readmemb("x.mem", x);
        $readmemb("y.mem", y);
    end

    always @(posedge clk) begin
        stage2_dx <= (stage1_x_i > stage1_x_j) ? (stage1_x_i - stage1_x_j) : (stage1_x_j - stage1_x_i);
        stage2_dy <= (stage1_y_i > stage1_y_j) ? (stage1_y_i - stage1_y_j) : (stage1_y_j - stage1_y_i);
        stage2_valid <= stage1_valid;
            
        stage3_area <= (stage2_dx + 1) * (stage2_dy + 1);
        stage3_valid <= stage2_valid;
            
        if (stage3_valid && stage3_area > largest_area) begin
            largest_area <= stage3_area;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            finished <= 0;
            result <= 0;
            state <= IDLE;
            largest_area <= 0;
            i <= 0;
            j <= 0;
            stage1_valid <= 0;
            stage2_valid <= 0;
            stage3_valid <= 0;
        end else begin            
            case (state)
                IDLE: begin
                    if (start) begin
                        state <= PROCESS;
                        i <= 0;
                        j <= 1;
                        largest_area <= 0;
                        finished <= 0;
                    end
                end
                PROCESS: begin
                    stage1_x_i <= x[i];
                    stage1_x_j <= x[j];
                    stage1_y_i <= y[i];
                    stage1_y_j <= y[j];
                    stage1_valid <= 1;
                    
                    if (j < NUM_ELEMENTS - 1) begin
                        j <= j + 1;
                    end else begin
                        if (i < NUM_ELEMENTS - 2) begin
                            i <= i + 1;
                            j <= i + 2;
                        end else begin
                            state <= DONE;
                            stage1_valid <= 0;
                        end
                    end
                end
                DONE: begin
                    if (!stage1_valid && !stage2_valid && !stage3_valid) begin
                        finished <= 1;
                        result <= largest_area;
                        if (!start) begin
                            state <= IDLE;
                        end
                    end
                end
            endcase
        end
    end
endmodule