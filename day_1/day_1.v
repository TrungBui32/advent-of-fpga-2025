module day_1();
    localparam LENGTH = 4186;
    reg [10:0] ops [0:LENGTH-1]; 
    reg [31:0] dial_position = 50; 
    reg [31:0] counter = 0;  
    
    integer i;
    integer rotation_amount;
    integer remaining_rotation;

    initial begin
        $readmemh("input.mem", ops);
        
        for(i = 0; i < LENGTH; i = i + 1) begin
            rotation_amount = ops[i][9:0];
            
            if(ops[i][10] == 1'b1) begin  
                if(dial_position + rotation_amount >= 100) begin
                    counter = counter + (dial_position + rotation_amount) / 100;
                    dial_position = (dial_position + rotation_amount) % 100;
                end else begin
                    dial_position = dial_position + rotation_amount;
                end
            end else begin  
                counter = counter + rotation_amount / 100;
                remaining_rotation = rotation_amount % 100;
                if(dial_position != 0) begin
                    if(dial_position <= remaining_rotation) begin
                        counter = counter + 1;
                        dial_position = (100 + (dial_position - remaining_rotation)) % 100;
                    end else begin
                        dial_position = dial_position - remaining_rotation;
                    end
                end else begin
                    dial_position = 100 - remaining_rotation;
                end
            end
        end
    end
endmodule
