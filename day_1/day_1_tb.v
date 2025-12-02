module day_1_tb;
    reg clk;
    reg process;
    
    wire finished;
    wire [31:0] result;
    
    day_1 uut (
        .clk(clk),
        .process(process),
        .finished(finished),
        .result(result)
    );
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    initial begin
        process = 0;
                
        #100;
        
        $display("Starting day_1 processing at time %0t", $time);
        process = 1;
        
        wait(finished);
        
        $display("Processing completed at time %0t", $time);
        $display("Final result: %d", result);
        $display("Number of clock cycles: %d", (($time - 100) / 10));
        
        #50;
        process = 0;
        
        #100;
        $finish;
    end
    
    initial begin
        #1000000; 
        $display("ERROR: Testbench timeout!");
        $finish;
    end
endmodule
