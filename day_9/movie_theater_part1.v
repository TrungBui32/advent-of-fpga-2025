module movie_theater_part1(
    input clk,
    input rst,
    input start,
    output reg finished,
    output reg [64:0] result
);

    localparam NUM_ELEMENTS = 496;
    localparam DATA_WIDTH = 64;
    localparam NUM_ENGINES = 8;

    reg [DATA_WIDTH-1:0] x [0:NUM_ELEMENTS-1];
    reg [DATA_WIDTH-1:0] y [0:NUM_ELEMENTS-1];

    reg [1:0] state;
    localparam IDLE = 2'd0;
    localparam PROCESS = 2'd1;
    localparam DRAIN = 2'd2;

    reg [15:0] i, j;
    reg [63:0] largest_area;

    reg [DATA_WIDTH-1:0] s1_xi, s1_yi;
    reg [DATA_WIDTH-1:0] s1_xj [0:NUM_ENGINES-1];
    reg [DATA_WIDTH-1:0] s1_yj [0:NUM_ENGINES-1];
    reg [NUM_ENGINES-1:0] s1_valid;

    reg [DATA_WIDTH-1:0] s2_dx [0:NUM_ENGINES-1];
    reg [DATA_WIDTH-1:0] s2_dy [0:NUM_ENGINES-1];
    reg [NUM_ENGINES-1:0] s2_valid;

    reg [DATA_WIDTH-1:0] s3_area [0:NUM_ENGINES-1];
    reg [NUM_ENGINES-1:0] s3_valid;

    initial begin
        $readmemb("x.mem", x);
        $readmemb("y.mem", y);
    end

    always @(posedge clk) begin
        for (k=0; k<NUM_ENGINES; k=k+1) begin
            s2_dx[k] <= (s1_xi > s1_xj[k]) ? (s1_xi - s1_xj[k]) : (s1_xj[k] - s1_xi);
            s2_dy[k] <= (s1_yi > s1_yj[k]) ? (s1_yi - s1_yj[k]) : (s1_yj[k] - s1_yi);
        end
        s2_valid <= s1_valid;

        for (k=0; k<NUM_ENGINES; k=k+1) begin
            s3_area[k] <= (s2_dx[k] + 1) * (s2_dy[k] + 1);
                
            if (s2_valid[k] && (s3_area[k] > largest_area)) begin
                largest_area <= s3_area[k];
            end
        end
        s3_valid <= s2_valid;
    end 

    integer k;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            finished <= 0;
            result <= 0;
            largest_area <= 0;
            s1_valid <= 0; s2_valid <= 0; s3_valid <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        state <= PROCESS;
                        i <= 0; j <= 1;
                        largest_area <= 0;
                        finished <= 0;
                    end
                    s1_valid <= 0;
                end
                PROCESS: begin
                    s1_xi <= x[i];
                    s1_yi <= y[i];
                    for (k=0; k<NUM_ENGINES; k=k+1) begin
                        if (j + k < NUM_ELEMENTS) begin
                            s1_xj[k] <= x[j+k];
                            s1_yj[k] <= y[j+k];
                            s1_valid[k] <= 1'b1;
                        end else begin
                            s1_valid[k] <= 1'b0;
                        end
                    end

                    if (j + NUM_ENGINES < NUM_ELEMENTS) begin
                        j <= j + NUM_ENGINES;
                    end else begin
                        if (i < NUM_ELEMENTS - 2) begin
                            i <= i + 1;
                            j <= i + 2;
                        end else begin
                            state <= DRAIN;
                        end
                    end
                end
                DRAIN: begin
                    s1_valid <= 0;
                    if (s2_valid == 0 && s3_valid == 0) begin
                        finished <= 1;
                        result <= largest_area;
                        if (!start) state <= IDLE;
                    end
                end
            endcase
        end
    end
endmodule