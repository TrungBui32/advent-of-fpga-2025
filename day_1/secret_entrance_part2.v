module secret_entrance_part2(
    input clk,
    input rst,
    input start,
    output reg finished,
    output reg [31:0] result
);
    localparam LENGTH = 4186;

    localparam IDLE = 3'd0;
    localparam LOAD = 3'd1;
    localparam PROCESS = 3'd2;
    localparam CHECK = 3'd3;
    localparam DONE = 3'd4;

    reg [2:0] state;
    
    reg [10:0] ops [0:LENGTH-1]; 
    reg [31:0] dial_position;
    reg [31:0] zero_crosses;  
    reg [12:0] counter;    
    
    reg [31:0] rotation_amount;
    reg [31:0] new_position;
    reg direction;

    initial begin
        $readmemh("input.mem", ops);
    end

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            dial_position <= 50;
            zero_crosses <= 0;
            counter <= 0;
            finished <= 0;
            result <= 0;
            state <= IDLE;
        end else begin
            case(state)
                IDLE: begin
                    if(start) begin
                        dial_position <= 50;
                        zero_crosses <= 0;
                        counter <= 0;
                        finished <= 0;
                        state <= LOAD;
                    end
                end
                LOAD: begin
                    rotation_amount <= ops[counter][9:0] % 100;
                    direction <= ops[counter][10];
                    zero_crosses <= zero_crosses + (ops[counter][9:0] / 100);
                    state <= PROCESS;
                end
                PROCESS: begin
                    if(direction) begin 
                        new_position <= dial_position + rotation_amount + 100;
                        if(dial_position + rotation_amount >= 100) begin
                            zero_crosses <= zero_crosses + 1;
                        end
                    end else begin  
                        new_position <= dial_position - rotation_amount + 100;
                        if(dial_position > 0 && dial_position <= rotation_amount) begin
                            zero_crosses <= zero_crosses + 1;
                        end
                    end
                    state <= CHECK;
                end
                CHECK: begin
                    dial_position <= new_position % 100;
                    if(counter == LENGTH - 1) begin
                        state <= DONE;
                    end else begin
                        counter <= counter + 1;
                        state <= LOAD;
                    end
                end
                DONE: begin
                    finished <= 1;
                    result <= zero_crosses;
                end
            endcase
        end
    end
endmodule
