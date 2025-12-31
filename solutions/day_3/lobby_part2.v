module lobby_part2(
    input clk,
    input rst,
    input start,
    output reg finished,
    output reg [47:0] result
);
    localparam WIDTH = 400;
    localparam HEIGHT = 200;

    localparam IDLE = 2'd0;
    localparam SUM = 2'd1;
    localparam DONE = 2'd2;

    reg [WIDTH-1:0] bank [0:HEIGHT-1];
    wire [HEIGHT-1:0] fh_finished;
    reg [1:0] bank_index;
    reg [1:0] state;

    wire [39:0] highest_array [0:HEIGHT-1];
    
    initial begin
        $readmemh("input2.mem", bank);
    end

    genvar i;
    generate
        for (i = 0; i < HEIGHT; i = i + 1) begin: gen_find_highest
            find_highest #(WIDTH) fh (
                .clk(clk),
                .rst(rst),
                .start(start),
                .num(bank[i]),
                .finished(fh_finished[i]),
                .result_1(highest_array[i])
            );
        end
    endgenerate

    wire all_finished = &fh_finished;

    reg [7:0] j;    // 200

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            finished <= 1'b0;
            bank_index <= 0;
            result <= 48'd0;
            state <= IDLE;
            j <= 8'd0;
        end else begin
            case (state)
                IDLE: begin
                    if(all_finished) begin
                        state <= SUM;
                        j <= 0;
                        result <= 0;
                    end
                    finished <= 0;
                end
                SUM: begin
                    if( j < HEIGHT) begin
                        result <= result + highest_array[j];
                        j <= j + 1;
                    end else begin
                        state <= DONE;
                    end
                end
                DONE: begin
                    finished <= 1'b1;
                end
            endcase
        end
    end
endmodule
