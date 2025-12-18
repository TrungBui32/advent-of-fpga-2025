module lobby_part1(
    input clk,
    input rst,
    input start,
    output reg finished,
    output reg [14:0] result
);
    localparam WIDTH = 333;
    localparam HEIGHT = 200;

    reg [WIDTH-1:0] bank [0:HEIGHT-1];
    wire [6:0] highest_array [0:HEIGHT-1];
    
    initial begin
        $readmemb("input1.mem", bank);
        finished = 1'b0;
    end

    function [6:0] find_highest;
        input [WIDTH-1:0] num;
        reg [3:0] highest;
        reg [3:0] second_highest;
        reg [3:0] current_digit;
        reg [WIDTH-1:0] temp_num;
        begin
            second_highest = num % 10;
            temp_num = num / 10;
            highest = temp_num % 10;
            temp_num = temp_num / 10;
            
            while(temp_num > 0) begin
                current_digit = temp_num % 10;
                
                if (current_digit >= highest) begin
                    if(second_highest < highest) begin
                        second_highest = highest;
                    end
                    highest = current_digit;
                end 
                temp_num = temp_num / 10;
            end
            
            find_highest = highest * 10 + second_highest;
        end
    endfunction

    genvar i;
    generate 
        for(i = 0; i < HEIGHT; i = i + 1) begin : gen_highest
            assign highest_array[i] = find_highest(bank[i]);
        end
    endgenerate

    always @(*) begin
        integer j;
        result = 0;
        for (j = 0; j < HEIGHT; j = j + 1) begin
            result = result + highest_array[j];
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            finished <= 1'b0;
        end else begin
            finished <= 1'b1;
        end
    end

endmodule