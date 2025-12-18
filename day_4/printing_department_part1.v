module printing_department_part1(
    input clk,
    input rst,
    input start,
    output reg finished,
    output reg [14:0] result
);

    localparam WIDTH = 140;
    localparam HEIGHT = 140;
    
    localparam IDLE = 2'd0;
    localparam PROCESS = 2'd1;
    localparam DONE = 2'd2;

    reg [1:0] state;

    reg [WIDTH-1:0] bank [0:HEIGHT-1];

    reg [14:0] accessible_count;
    reg [7:0] row_idx; 

    integer j;

    reg [WIDTH-1:0] row_n, row_c, row_s; 
    reg [7:0] row_accessible_count; 

    initial begin
        $readmemb("input.mem", bank);
    end

    reg n, s, w, e, nw, ne, sw, se;
    reg [3:0] surrounded;
    reg accessible;

    always @(*) begin
        if (row_idx == 0) row_n = {WIDTH{1'b0}};
        else row_n = bank[row_idx - 1];

        row_c = bank[row_idx];

        if (row_idx == HEIGHT - 1) row_s = {WIDTH{1'b0}};
        else row_s = bank[row_idx + 1];

        row_accessible_count = 0;
        
        for (j = 0; j < WIDTH; j = j + 1) begin
            if (row_c[j]) begin 
                n = row_n[j];
                s = row_s[j];
                w = (j == 0) ? 1'b0 : row_c[j-1];
                e = (j == WIDTH-1) ? 1'b0 : row_c[j+1];
                nw = (j == 0) ? 1'b0 : row_n[j-1];
                ne = (j == WIDTH-1) ? 1'b0 : row_n[j+1];
                sw = (j == 0) ? 1'b0 : row_s[j-1];
                se = (j == WIDTH-1) ? 1'b0 : row_s[j+1];

                surrounded = n + s + w + e + nw + ne + sw + se;
                accessible = (surrounded < 4) ? 1'b1 : 1'b0;
                
                if (accessible) begin
                    row_accessible_count = row_accessible_count + 1;
                end
            end
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            finished <= 0;
            result <= 0;
            state <= IDLE;
            accessible_count <= 0;
            row_idx <= 0;
        end else begin
            case(state)
                IDLE: begin
                    if(start) begin
                        accessible_count <= 0;
                        state <= PROCESS;
                        row_idx <= 0;
                    end
                end
                PROCESS: begin
                    accessible_count <= accessible_count + row_accessible_count;
                    
                    if (row_idx == HEIGHT - 1) begin
                        state <= DONE;
                    end else begin
                        row_idx <= row_idx + 1;
                    end
                end
                DONE: begin
                    result <= accessible_count;
                    finished <= 1;
                end
            endcase
        end
    end
endmodule
