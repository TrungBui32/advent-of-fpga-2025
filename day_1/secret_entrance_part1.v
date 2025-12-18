module secret_entrance_part1(
    input clk,
    input rst,
    input start,
    output reg finished,
    output reg [31:0] result
);
    localparam LENGTH = 4186;
    reg [10:0] ops [0:LENGTH-1]; 
    reg [31:0] dial_position;  
    reg [31:0] counter;  

    reg [31:0] rotation_amount;
    reg direction;
    reg [31:0] sum;
    
    reg [31:0] temp_position; 
    reg [6:0] reduced_rotation;

    localparam IDLE = 3'd0;
    localparam LOAD = 3'd1;
    localparam PROCESS = 3'd2;
    localparam CHECK = 3'd3;
    localparam DONE = 3'd4;

    reg [2:0] state;

    initial begin
        $readmemh("input.mem", ops);
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            finished <= 0;
            result <= 0;
            dial_position <= 50;
            counter <= 0;
            state <= IDLE;
            sum <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        state <= LOAD;
                        counter <= 0;
                        sum <= 0;
                        dial_position <= 50;
                    end
                end
                LOAD: begin
                    rotation_amount <= ops[counter][9:0];
                    direction <= ops[counter][10];
                    reduced_rotation <= ops[counter][9:0] % 100; 
                    state <= PROCESS;
                end
                PROCESS: begin
                    if (direction) begin
                        if (dial_position + reduced_rotation >= 100) begin
                            dial_position <= dial_position + reduced_rotation - 100;
                        end else begin
                            dial_position <= dial_position + reduced_rotation;
                        end
                    end else begin
                        if (dial_position >= reduced_rotation) begin
                            dial_position <= dial_position - reduced_rotation;
                        end else begin
                            dial_position <= dial_position + 100 - reduced_rotation;
                        end
                    end
                    state <= CHECK;
                end
                CHECK: begin
                    if (dial_position == 0) begin
                        sum <= sum + 1;
                    end
                    if (counter == LENGTH - 1) begin
                        state <= DONE;
                    end else begin
                        state <= LOAD;
                        counter <= counter + 1;
                    end
                end
                DONE: begin
                    result <= sum;
                    finished <= 1;
                    state <= IDLE; 
                end
            endcase
        end
    end
endmodule
