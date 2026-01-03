module laboratories_part1(
    input clk,
    input rst,
    input start,
    output reg finished,
    output reg [31:0] result
);
    localparam HEIGHT = 141;
    localparam WIDTH = 141;
    localparam MIDDLE = 70;
    localparam PIPELINE_DEPTH = 6;

    localparam IDLE = 2'd0;
    localparam RUNNING = 2'd1;
    localparam DRAINING = 2'd2;
    localparam DONE = 2'd3;

    reg [WIDTH-1:0] map [0:HEIGHT-1];
    reg [WIDTH-1:0] previous_path;
    wire [WIDTH-1:0] next_path;
    wire [WIDTH-1:0] splits;
    
    reg [1:0] level1 [0:70];
    reg [2:0] level2 [0:35];
    reg [3:0] level3 [0:17];
    reg [4:0] level4 [0:8];
    reg [5:0] level5 [0:2];   
    reg [6:0] level6;   
    
    reg [31:0] sum;
    reg [7:0] y;
    reg [7:0] cycle_count;
    reg [1:0] state;
    
    integer i, j;
    initial begin
        $readmemb("input.mem", map);
    end

    genvar g;
    generate
        for(g = 0; g < WIDTH; g = g + 1) begin : gen_paths
            wire left_beam = (g > 0) ? previous_path[g-1] && map[y][g-1] : 1'b0;
            wire right_beam = (g < WIDTH-1) ? previous_path[g+1] && map[y][g+1] : 1'b0;
            wire straight_beam = previous_path[g] && !map[y][g];
            assign next_path[g] = left_beam || right_beam || straight_beam;
            assign splits[g] = previous_path[g] && map[y][g];
        end
    endgenerate
    
    always @(posedge clk) begin
        for(j = 0; j < 70; j = j + 1) begin
            level1[j] <= splits[j*2] + splits[j*2+1];
        end
        level1[70] <= {1'b0, splits[140]};
        
        for(j = 0; j < 35; j = j + 1) begin
            level2[j] <= level1[j*2] + level1[j*2+1];
        end
        level2[35] <= {1'b0, level1[70]};
        
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
            result <= 32'd0;
            finished <= 1'b0;
            state <= IDLE;
            sum <= 32'd0;
            y <= 8'd0;
            cycle_count <= 8'd0;
            previous_path <= {WIDTH{1'b0}};
        end else begin
            case(state)
                IDLE: begin
                    if(start) begin
                        state <= RUNNING;
                        y <= 8'd1;
                        cycle_count <= 8'd0;
                        sum <= 32'd0;
                        previous_path <= {WIDTH{1'b0}};
                        previous_path[MIDDLE] <= 1'b1;
                    end
                end
                RUNNING: begin
                    cycle_count <= cycle_count + 1;
                    previous_path <= next_path;
                    
                    if(cycle_count >= PIPELINE_DEPTH) begin
                        sum <= sum + level6;
                    end
                    
                    if(y == HEIGHT - 1) begin
                        state <= DRAINING;
                        y <= 8'd0;
                    end else begin
                        y <= y + 1;
                    end
                end
                DRAINING: begin
                    sum <= sum + level6;
                    y <= y + 1;
                    
                    if(y == PIPELINE_DEPTH - 1) begin
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