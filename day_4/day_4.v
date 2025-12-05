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
    localparam DONE = 3'd2;

    reg [2:0] state;

    reg [WIDTH-1:0] bank [0:HEIGHT-1];
    
    wire [WIDTH-1:0] keep_mask [0:HEIGHT-1];

    reg [14:0] current_count;
    reg [14:0] start_count;
    
    integer x, y;
    reg diff_found;
    reg [14:0] temp_sum;

    initial begin
        $readmemb("input.mem", bank);
    end

    genvar i, j;
    generate
        for(i = 0; i < HEIGHT; i = i + 1) begin : row
            for(j = 0; j < WIDTH; j = j + 1) begin : col
                
                wire n, s, w, e, nw, ne, sw, se;

                if (i == 0) begin
                    assign n = 1'b0;
                    assign nw = 1'b0;
                    assign ne = 1'b0;
                end else begin
                    assign n = bank[i-1][j];
                    assign nw = (j == 0) ? 1'b0 : bank[i-1][j-1];
                    assign ne = (j == WIDTH-1) ? 1'b0 : bank[i-1][j+1];
                end

                if (i == HEIGHT-1) begin
                    assign s = 1'b0;
                    assign sw = 1'b0;
                    assign se = 1'b0;
                end else begin
                    assign s = bank[i+1][j];
                    assign sw = (j == 0) ? 1'b0 : bank[i+1][j-1];
                    assign se = (j == WIDTH-1) ? 1'b0 : bank[i+1][j+1];
                end

                assign w = (j == 0) ? 1'b0 : bank[i][j-1];
                assign e = (j == WIDTH-1) ? 1'b0 : bank[i][j+1];

                wire [3:0] surrounded = n + s + w + e + nw + ne + sw + se;

                assign keep_mask[i][j] = (surrounded < 4) ? 1'b0 : 1'b1;
            end
        end
    endgenerate

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            finished <= 0;
            result <= 0;
            state <= IDLE;
            start_count <= 0;
            current_count <= 0;
        end else begin
            case(state)
                IDLE: begin
                    if(start) begin
                        temp_sum = 0;
                        for(x = 0; x < HEIGHT; x = x + 1) begin
                            for(y = 0; y < WIDTH; y = y + 1) begin
                                if(bank[x][y]) begin
                                    temp_sum = temp_sum + 1;
                                end
                            end
                        end
                        start_count <= temp_sum;
                        state <= CHECK;
                    end
                end
                CHECK: begin
                    diff_found = 0;
                    temp_sum = 0;
                    for(x = 0; x < HEIGHT; x = x + 1) begin
                        for(y = 0; y < WIDTH; y = y + 1) begin
                            if (bank[x][y] == 1'b1 && keep_mask[x][y] == 1'b0) begin
                                diff_found = 1;
                            end
                            bank[x][y] <= bank[x][y] & keep_mask[x][y];
                            if (bank[x][y] & keep_mask[x][y]) begin
                                temp_sum = temp_sum + 1;
                            end
                        end
                    end
                    current_count <= temp_sum;
                    if (!diff_found) begin
                        state <= DONE;
                    end
                end
                DONE: begin
                    result <= start_count - current_count;
                    finished <= 1;
                end
            endcase
        end
    end
endmodule