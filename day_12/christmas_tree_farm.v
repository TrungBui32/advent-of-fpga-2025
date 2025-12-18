module christmas_tree_farm(
    input clk,
    input rst,
    input start,
    output reg finished,
    output reg [63:0] result
);
    localparam NUM_PRESENTS = 6;
    localparam NUM_REGIONS = 1000;
    localparam DATA_WIDTH = 32;

    localparam IDLE = 3'd0;
    localparam SUM = 3'd1;
    localparam DONE = 3'd2;

    reg [2:0] state;

    reg [8:0] presents_temp [0:NUM_PRESENTS-1];
    reg presents [0:5][0:2][0:2];  
    reg [47:0] quantities [0:NUM_REGIONS-1];
    reg [15:0] sizes [0:NUM_REGIONS-1];
    
    reg [DATA_WIDTH-1:0] sum;
    reg [DATA_WIDTH-1:0] multiplication;
    reg [DATA_WIDTH-1:0] quant;

    integer i;

    initial begin
        $readmemb("sizes.mem", sizes);
        $readmemb("presents.mem", presents_temp);
        $readmemb("quantities.mem", quantities);
        for(i = 0; i < NUM_PRESENTS; i = i + 1) begin
            presents[i][0][0] = presents_temp[i][8:6];
            presents[i][0][1] = presents_temp[i][5:3];
            presents[i][0][2] = presents_temp[i][2:0];
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            finished <= 0;
            result <= 0;
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        state <= SUM;
                        result <= 0;
                        quant <= 0;
                        sum <= 0;
                        multiplication <= 0;
                    end
                end
                SUM: begin
                    sum = quantities[quant][47:40] + quantities[quant][39:32] + quantities[quant][31:24] +
                           quantities[quant][23:16] + quantities[quant][15:8] + quantities[quant][7:0];
                    multiplication = (sizes[quant][15:8]/3) * (sizes[quant][7:0]/3);
                    if(sum <= multiplication) begin
                        result <= result + 1;
                    end
                    if(quant < NUM_REGIONS - 1) begin
                        quant <= quant + 1;
                        sum <= 0;
                        multiplication <= 0;
                    end else begin
                        state <= DONE;
                    end
                end
                DONE: begin
                    finished <= 1;
                end
            endcase
        end
    end
endmodule