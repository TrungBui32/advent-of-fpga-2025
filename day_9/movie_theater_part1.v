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
    reg [DATA_WIDTH-1:0] largest_area;
    reg [DATA_WIDTH-1:0] current_area;
    reg [15:0] i, j;
    reg [DATA_WIDTH-1:0] dx, dy;
    
    initial begin
        $readmemb("x.mem", x);
        $readmemb("y.mem", y);
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            finished <= 0;
            result <= 0;
            state <= IDLE;
            largest_area <= 0;
            i <= 0;
            j <= 0;
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
                    dx = (x[i] > x[j]) ? (x[i] - x[j]) : (x[j] - x[i]);
                    dy = (y[i] > y[j]) ? (y[i] - y[j]) : (y[j] - y[i]);
                    current_area = (dx + 1) * (dy + 1);
                    if (current_area > largest_area) begin
                        largest_area <= current_area;
                    end
                    
                    if (j < NUM_ELEMENTS - 1) begin
                        j <= j + 1;
                    end else begin
                        if (i < NUM_ELEMENTS - 2) begin
                            i <= i + 1;
                            j <= i + 2;
                        end else begin
                            state <= DONE;
                        end
                    end
                end
                
                DONE: begin
                    finished <= 1;
                    result <= largest_area;
                    if (!start) begin
                        state <= IDLE;
                    end
                end
            endcase
        end
    end

endmodule