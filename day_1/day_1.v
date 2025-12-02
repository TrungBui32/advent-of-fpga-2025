module day_1();
    localparam LENGTH = 4186;
    reg [10:0] ops [0:LENGTH-1]; 
    reg [31:0] dial_position = 50; 
    reg [31:0] counter = 0;  
    
    integer i;
    integer rotation_amount;
    integer new_position;

    initial begin
        $readmemh("input.mem", ops);
        
        for(i = 0; i < LENGTH; i = i + 1) begin
            rotation_amount = ops[i][9:0];

            counter = counter + (rotation_amount / 100);
            rotation_amount = rotation_amount % 100;

            if(ops[i][10] == 1'b1) begin  
                new_position = dial_position + rotation_amount;
                counter = counter + new_position / 100;
            end else begin  
                new_position = dial_position - rotation_amount;
                counter = counter + (dial_position > 0 && new_position <= 0);
            end
            
            dial_position = (100 + new_position) % 100;
        end
        $display("Final Counter Value: %d", counter);
    end
endmodule
