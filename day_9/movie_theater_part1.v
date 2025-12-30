module movie_theater_part1(
    input clk,
    input rst,
    input start,
    output reg finished,
    output reg [63:0] result
);

    localparam NUM_ELEMENTS = 496;
    localparam DATA_WIDTH = 64;
    localparam NUM_ENGINES = 8;

    reg [DATA_WIDTH-1:0] x [0:NUM_ELEMENTS-1];
    reg [DATA_WIDTH-1:0] y [0:NUM_ELEMENTS-1];

    localparam IDLE = 2'd0;
    localparam PROCESS = 2'd1; 
    localparam DRAIN = 2'd2;
    reg [1:0] state;
    reg [15:0] i, j;
    reg [63:0] global_max;

    reg [DATA_WIDTH-1:0] s1_xi;
    reg [DATA_WIDTH-1:0] s1_yi;
    reg [DATA_WIDTH-1:0] s1_xj[0:7];
    reg [DATA_WIDTH-1:0] s1_yj[0:7];
    reg [7:0] s1_vld;

    reg [DATA_WIDTH-1:0] s2_dx[0:7];
    reg [DATA_WIDTH-1:0] s2_dy[0:7];
    reg [7:0] s2_vld;

    reg [DATA_WIDTH-1:0] s3_w[0:7];
    reg [DATA_WIDTH-1:0] s3_h[0:7];
    reg [7:0] s3_vld;

    reg [63:0] s4_area[0:7];
    reg [63:0] s5_area[0:7];
    reg [63:0] s6_area[0:7];
    reg [7:0] s4_vld;
    reg [7:0] s5_vld;
    reg [7:0] s6_vld;

    reg [63:0] s7_max[0:3];
    reg s7_vld;

    reg [63:0] s8_max[0:1];
    reg s8_vld;

    reg [63:0] s9_winner;
    reg s9_vld;

    initial begin
        $readmemb("x.mem", x);
        $readmemb("y.mem", y);
    end

    always @(posedge clk) begin
        for (k = 0; k < 8; k = k + 1) begin
            s2_dx[k] <= (s1_xi > s1_xj[k]) ? (s1_xi - s1_xj[k]) : (s1_xj[k] - s1_xi);
            s2_dy[k] <= (s1_yi > s1_yj[k]) ? (s1_yi - s1_yj[k]) : (s1_yj[k] - s1_yi);
        end
        s2_vld <= s1_vld;

        for (k = 0; k < 8; k = k + 1) begin
            s3_w[k] <= s2_dx[k] + 1; 
            s3_h[k] <= s2_dy[k] + 1;
        end
        s3_vld <= s2_vld;

        for (k = 0; k < 8; k = k + 1) begin
            s4_area[k] <= s3_w[k] * s3_h[k]; 
            s4_vld[k] <= s3_vld[k];
            s5_area[k] <= s4_area[k];        
            s5_vld[k] <= s4_vld[k];
            s6_area[k] <= s5_area[k];        
            s6_vld[k] <= s5_vld[k];
        end

        for (k = 0; k < 4; k = k + 1) begin
            s7_max[k] <= (s6_area[2*k] > s6_area[2*k + 1]) ? s6_area[2*k] : s6_area[2*k + 1];
        end
        s7_vld <= |s6_vld;

        s8_max[0] <= (s7_max[0] > s7_max[1]) ? s7_max[0] : s7_max[1];
        s8_max[1] <= (s7_max[2] > s7_max[3]) ? s7_max[2] : s7_max[3];
        s8_vld    <= s7_vld;

        s9_winner <= (s8_max[0] > s8_max[1]) ? s8_max[0] : s8_max[1];
        s9_vld    <= s8_vld;

        if (s9_vld && (s9_winner > global_max)) begin
            global_max <= s9_winner;
        end
    end

    integer k;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            s1_vld <= 0;
            s2_vld <= 0;
            s3_vld <= 0;
            s4_vld <= 0;
            s5_vld <= 0;
            s6_vld <= 0;
            s7_vld <= 0;
            s8_vld <= 0;
            s9_vld <= 0;
            global_max <= 0; 
            finished <= 0; 
            result <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin 
                        state <= PROCESS; 
                        i <= 0; 
                        j <= 1; 
                        global_max <= 0; 
                        finished <= 0; 
                    end
                    s1_vld <= 0;
                end
                PROCESS: begin
                    s1_xi <= x[i]; 
                    s1_yi <= y[i];
                    for (k = 0; k < 8; k = k + 1) begin
                        if (j + k < NUM_ELEMENTS) begin
                            s1_xj[k] <= x[j + k]; 
                            s1_yj[k] <= y[j + k];
                            s1_vld[k] <= 1;
                        end else begin
                            s1_vld[k] <= 0;
                        end
                    end
                    if (j + 8 < NUM_ELEMENTS) begin
                        j <= j + 8;
                    end else if (i < NUM_ELEMENTS - 2) begin 
                        i <= i + 1; j <= i + 2; 
                    end else state <= DRAIN;
                end
                DRAIN: begin
                    s1_vld <= 0;
                    if (!( |{s1_vld, s2_vld, s3_vld, s4_vld, s5_vld, s6_vld, s7_vld, s8_vld, s9_vld} )) begin
                        finished <= 1; 
                        result <= global_max;
                        if (!start) begin 
                            state <= IDLE;
                        end
                    end
                end
            endcase
        end
    end
endmodule