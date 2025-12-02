module day_1(
    input clk,
    input process,
    output reg finished,
    output reg [31:0] result
);
    localparam LENGTH = 4186;
    
    reg [10:0] ops [0:LENGTH-1]; 
    reg [31:0] dial_position; 
    reg [31:0] counter;  
    reg [31:0] i;
    
    reg signed [31:0] rotation_amount;
    reg signed [31:0] new_position;

    initial begin
        $readmemh("input.mem", ops);
        dial_position = 50;
        counter = 0;
        i = 0;
        finished = 1'b0;
        result = 0;
    end

    always @(posedge clk) begin
        if(process && !finished) begin
            if(i < LENGTH) begin
                rotation_amount = ops[i][9:0];
                
                counter = counter + (rotation_amount / 100);
                rotation_amount = rotation_amount % 100;
                
                if(ops[i][10] == 1'b1) begin  
                    new_position = dial_position + rotation_amount;
                    counter <= counter + (new_position / 100);
                end else begin  
                    new_position = dial_position - rotation_amount;
                    counter <= counter + (dial_position > 0 && new_position <= 0);
                end
                
                dial_position <= (100 + new_position) % 100;
                
                i <= i + 1;
            end else begin
                finished <= 1'b1;
                result <= counter;
            end
        end
    end
endmodule
