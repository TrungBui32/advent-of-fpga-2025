module laboratories_part2(
    input clk,
    input rst,
    input start,
    output reg finished,
    output reg [48:0] result
);
    localparam HEIGHT = 141;
    localparam WIDTH = 141;
    localparam MIDDLE = 70;
    localparam PIPELINE_DEPTH = 6;

    localparam IDLE = 2'd0;
    localparam RUNNING = 2'd1;
    localparam SUMMING = 2'd2;
    localparam DONE = 2'd3;

    reg [WIDTH-1:0] map [0:HEIGHT-1];
    reg [48:0] current_path [0:WIDTH-1];
    wire [48:0] next_path_wire [0:WIDTH-1];
    
    reg [45:0] level1 [0:70];
    reg [46:0] level2 [0:35];
    reg [47:0] level3 [0:17];
    reg [47:0] level4 [0:8];
    reg [48:0] level5 [0:2];
    reg [48:0] level6;
    
    reg [48:0] sum;
    reg [7:0] y;
    reg [7:0] cycle_count;
    reg [1:0] state;
    
    integer i, j, x;
    initial begin
        $readmemb("input.mem", map);
    end

    genvar g;
    generate
        for(g = 0; g < WIDTH; g = g + 1) begin : gen_paths
            wire [48:0] left_contribution = (g > 0 && map[y][g-1]) ? current_path[g-1] : 0;
            wire [48:0] right_contribution = (g < WIDTH-1 && map[y][g+1]) ? current_path[g+1] : 0;
            wire [48:0] straight_contribution = (!map[y][g]) ? current_path[g] : 0;
            assign next_path_wire[g] = left_contribution + right_contribution + straight_contribution;
        end
    endgenerate
    
    always @(posedge clk) begin
        for(j = 0; j < 70; j = j + 1) begin
            level1[j] <= current_path[j*2] + current_path[j*2+1];
        end
        level1[70] <= current_path[140];
        
        for(j = 0; j < 35; j = j + 1) begin
            level2[j] <= level1[j*2] + level1[j*2+1];
        end
        level2[35] <= level1[70];
        
        for(j = 0; j < 18; j = j + 1) begin
            level3[j] <= level2[j*2] + level2[j*2+1];
        end
        
        for(j = 0; j < 9; j = j + 1) begin
            level4[j] <= level3[j*2] + level3[j*2+1];
        end
        
        level5[0] <= level4[0] + level4[1] + level4[2];
        level5[1] <= level4[3] + level4[4] + level4[5];
        level5[2] <= level4[6] + level4[7] + level4[8];
        
        level6 <= level5[0] + level5[1] + level5[2];
    end

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            result <= 0;
            finished <= 1'b0;
            state <= IDLE;
            sum <= 0;
            y <= 8'd0;
            cycle_count <= 8'd0;
            for(i = 0; i < WIDTH; i = i + 1) begin
                current_path[i] <= 0;
            end
        end else begin
            case(state)
                IDLE: begin
                    if(start) begin
                        state <= RUNNING;
                        y <= 8'd1;
                        cycle_count <= 8'd0;
                        sum <= 0;
                        for(i = 0; i < WIDTH; i = i + 1) begin
                            if(i == MIDDLE) begin
                                current_path[i] <= 1;
                            end else begin
                                current_path[i] <= 0;
                            end
                        end
                    end
                end
                RUNNING: begin
                    cycle_count <= cycle_count + 1;
                    for(x = 0; x < WIDTH; x = x + 1) begin
                        current_path[x] <= next_path_wire[x];
                    end
                    
                    if(y == HEIGHT - 1) begin
                        state <= SUMMING;
                        y <= 8'd0;
                    end else begin
                        y <= y + 1;
                    end
                end
                SUMMING: begin
                    y <= y + 1;
                    if(y == PIPELINE_DEPTH) begin
                        sum <= level6;
                        state <= DONE;
                    end
                end
                DONE: begin
                    finished <= 1'b1;
                    result <= sum;
                end
            endcase
        end
    end
endmodule