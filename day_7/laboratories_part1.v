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

    localparam IDLE = 3'd0;
    localparam RUNNING = 3'd1;
    localparam DONE = 3'd2;

    reg [WIDTH-1:0] map [0:HEIGHT-1];
    reg [WIDTH-1:0] current_path;
    reg [WIDTH-1:0] previous_path;

    reg [31:0] sum;
    
    integer i, j;
    initial begin
        $readmemb("input.mem", map);
    end 

    reg [7:0] y;
    integer x;
    integer m, n;

    reg [2:0] state;

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            result <= 0;
            finished <= 0;
            state <= IDLE;
            previous_path <= {WIDTH{1'b0}};
            current_path <= {WIDTH{1'b0}};
        end else begin
            case(state)
                IDLE: begin
                    if(start) begin
                        state <= RUNNING;
                        y <= 1;
                        sum <= 0;
                        previous_path <= {WIDTH{1'b0}};
                        previous_path[MIDDLE] <= 1'b1;
                        current_path <= {WIDTH{1'b0}};
                    end
                end
                RUNNING: begin
                    for(x = 0; x < WIDTH; x = x + 1) begin
                        if(previous_path[x] && map[y][x]) begin
                            if(x > 0) begin
                                current_path[x-1] = 1'b1;
                            end
                            if(x + 1 < WIDTH) begin
                                current_path[x+1] = 1'b1;
                            end
                            sum = sum + 1;
                        end  else if (previous_path[x]) begin
                            current_path[x] = 1'b1;
                        end
                    end
                    previous_path <= current_path;
                    current_path <= {WIDTH{1'b0}};

                    if(y == HEIGHT - 1) begin
                        state <= DONE;
                    end else begin
                        y <= y + 1;
                    end
                end
                DONE: begin
                    finished <= 1;
                    result <= sum;
                end
            endcase
        end
    end

endmodule