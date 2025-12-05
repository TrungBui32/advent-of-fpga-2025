module day_4(
    input clk,
    input rst,
    input start,
    output reg finished,
    output reg [14:0] result
);

    localparam WIDTH = 140;
    localparam HEIGHT = 140;
    
    localparam IDLE = 3'd0;
    localparam CHECK = 3'd1;
    localparam COPY = 3'd2;
    localparam HEIGHT_LOOP = 3'd3;
    localparam WIDTH_LOOP = 3'd4;
    localparam COUNT = 3'd5;
    localparam REMOVE = 3'd6;
    localparam DONE = 3'd7;

    reg [2:0] state;

    reg [WIDTH-1:0] bank [0:HEIGHT-1];
    reg [WIDTH-1:0] next_bank [0:HEIGHT-1];

    reg [14:0] sum;
    reg [14:0] pre_sum;
    reg [3:0] count;

    initial begin
        $readmemb("input.mem", bank);
        $readmemb("input.mem", next_bank);
    end

    reg [8:0] x, y;

    // height - x, width - y
    wire at_north_edge = (x == 0);
    wire at_south_edge = (x >= HEIGHT - 1);  
    wire at_west_edge = (y == 0);
    wire at_east_edge = (y >= WIDTH - 1);  

    wire x_valid = (x < HEIGHT);
    wire y_valid = (y < WIDTH);

    wire north = (at_north_edge || !x_valid) ? 1'b0 : bank[x-1][y];
    wire south = (at_south_edge || !x_valid) ? 1'b0 : bank[x+1][y];
    wire west  = (at_west_edge || !y_valid) ? 1'b0 : bank[x][y-1];
    wire east  = (at_east_edge || !y_valid) ? 1'b0 : bank[x][y+1];
    wire north_east = (at_north_edge || at_east_edge || !x_valid || !y_valid) ? 1'b0 : bank[x-1][y+1];
    wire north_west = (at_north_edge || at_west_edge || !x_valid || !y_valid) ? 1'b0 : bank[x-1][y-1];
    wire south_east = (at_south_edge || at_east_edge || !x_valid || !y_valid) ? 1'b0 : bank[x+1][y+1];
    wire south_west = (at_south_edge || at_west_edge || !x_valid || !y_valid) ? 1'b0 : bank[x+1][y-1];

    wire [3:0] surrounded = north + south + west + east + north_east + north_west + south_east + south_west;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            finished <= 0;
            result <= 0;
            state <= IDLE;
            sum <= 0;
            pre_sum <= 0;
            x <= 0;
            y <= 0;
        end else begin
            case(state)
                IDLE: begin
                    if(start) begin
                        state <= HEIGHT_LOOP;
                        sum <= 0;
                        pre_sum <= 0;
                        x <= 0;
                        y <= 0;
                    end
                end
                CHECK: begin
                    if(sum - pre_sum > 0) begin
                        state <= COPY;
                        pre_sum <= sum;
                        x <= 0;
                        y <= 0;
                    end else begin
                        state <= DONE;
                    end
                end

                COPY: begin
                    if(x < HEIGHT) begin
                        bank[x] <= next_bank[x];
                        x <= x + 1;
                    end else begin
                        x <= 0;
                        state <= HEIGHT_LOOP;
                    end
                end
                HEIGHT_LOOP: begin
                    if(x < HEIGHT) begin
                        y <= 0;
                        state <= WIDTH_LOOP;
                    end else begin
                        state <= CHECK;
                        x <= 0;
                    end
                end
                WIDTH_LOOP: begin
                    if(y < WIDTH) begin
                        state <= COUNT;
                        count <= 0;
                    end else begin
                        state <= HEIGHT_LOOP;
                        x <= x + 1;
                    end
                end
                COUNT: begin
                    if (bank[x][y] == 1'b1) begin
                        count <= surrounded;
                        state <= REMOVE;
                    end else begin
                        next_bank[x][y] <= bank[x][y];
                        state <= WIDTH_LOOP;
                        y <= y + 1;
                    end
                end
                REMOVE: begin
                    if(count < 4) begin
                        sum <= sum + 1;
                        next_bank[x][y] <= 1'b0;
                    end else begin
                        next_bank[x][y] <= bank[x][y];
                    end
                    state <= WIDTH_LOOP;
                    y <= y + 1;
                end
                DONE: begin
                    result <= sum;
                    finished <= 1;
                end
            endcase
        end
    end

endmodule