module day_1();
    localparam LENGTH = 4186;
    reg [10:0] ops [0:LENGTH-1]; 
    reg signed [31:0] dial_position = 50; 
    reg [31:0] counter = 0;  

    integer i, j;
    integer rotation_amount;
    integer current_pos;

    initial begin
        $readmemh("input.mem", ops);
        
        for(i = 0; i < LENGTH; i = i + 1) begin
            rotation_amount = ops[i][9:0];
            current_pos = dial_position;
            
            for(j = 0; j < rotation_amount; j = j + 1) begin
                if(ops[i][10] == 1'b1) begin  
                    current_pos = (current_pos + 1) % 100;
                end else begin  
                    current_pos = (current_pos - 1 + 100) % 100;
                end
                
                if(current_pos == 0) begin
                    counter = counter + 1;
                end
            end
            
            dial_position = current_pos;
        end
        
        $display("Password: %0d", counter);
    end
endmodule
