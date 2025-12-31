module christmas_tree_farm(
    input clk,
    input rst,
    input start,
    output reg finished,
    output [63:0] result
);
    localparam NUM_REGIONS = 1000;
    
    localparam IDLE = 2'd0;
    localparam RUN  = 2'd1;
    localparam DONE = 2'd2;

    reg [1:0] state;
    
    reg [9:0] count_down;
    
    reg [47:0] quantities [0:NUM_REGIONS-1];
    reg [15:0] sizes [0:NUM_REGIONS-1];

    reg [47:0] q_s1;
    reg [15:0] s_s1;
    reg v_s1;

    reg [15:0] sum_s2;
    reg [7:0] w_div_s2, h_div_s2;
    reg v_s2;
    reg [15:0] area_s3, sum_s3;
    reg v_s3;
    reg inc_s4, v_s4;

    reg [31:0] res_low, res_high;
    reg carry_to_high, v_s5;

    assign result = {res_high, res_low};

    initial begin
        $readmemb("sizes.mem", sizes);
        $readmemb("quantities.mem", quantities);
    end

    always @(posedge clk) begin
        sum_s2   <= q_s1[47:40] + q_s1[39:32] + q_s1[31:24] + q_s1[23:16] + q_s1[15:8]  + q_s1[7:0];
        w_div_s2 <= s_s1[15:8] / 3; 
        h_div_s2 <= s_s1[7:0] / 3;

        area_s3 <= w_div_s2 * h_div_s2;
        sum_s3  <= sum_s2;

        inc_s4 <= (sum_s3 <= area_s3);

        if (v_s4 && inc_s4) begin
            {carry_to_high, res_low} <= res_low + 1'b1;
        end else begin
            carry_to_high <= 1'b0;
        end

        if (carry_to_high) begin
            res_high <= res_high + 1'b1;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            count_down <= 0;
            finished <= 0;
            v_s1 <= 0; v_s2 <= 0; v_s3 <= 0; v_s4 <= 0; v_s5 <= 0;
        end else begin
            case (state)
                IDLE: begin
                    finished <= 0;
                    if (start) begin
                        state <= RUN;
                        count_down <= NUM_REGIONS - 1;
                        v_s1 <= 0;
                    end
                end
                RUN: begin
                    q_s1 <= quantities[count_down];
                    s_s1 <= sizes[count_down];
                    v_s1 <= 1'b1;

                    if (count_down == 0) begin
                        state <= DONE;
                    end else begin
                        count_down <= count_down - 1'b1;
                    end
                end
                DONE: begin
                    v_s1 <= 1'b0;
                    if (!v_s1 && !v_s2 && !v_s3 && !v_s4 && !v_s5 && !carry_to_high) begin
                        finished <= 1'b1;
                        state <= IDLE;
                    end
                end
            endcase

            v_s2 <= v_s1;
            v_s3 <= v_s2;
            v_s4 <= v_s3;
            v_s5 <= v_s4;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            {res_low, res_high} <= 64'b0;
        end else if (state == IDLE && start) begin
            {res_low, res_high} <= 64'b0;
        end
    end
endmodule