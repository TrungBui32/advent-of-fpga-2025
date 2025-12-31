module day_10(
    input clk,
    input rst,
    input start,
    output reg finished,
    output reg [63:0] result
);

    localparam MAX_BUTTONS = 6;
    localparam MAX_JOLTAGES = 6;
    localparam TOTAL_MACHINES = 3;
    localparam DATA_WIDTH = 32;

    reg [DATA_WIDTH-1:0] joltages  [0:TOTAL_MACHINES*MAX_JOLTAGES-1];
    reg [DATA_WIDTH-1:0] configs [0:TOTAL_MACHINES-1];         // num buttons + num light
    reg [DATA_WIDTH-1:0] buttons [0:(TOTAL_MACHINES*MAX_BUTTONS)-1];

    initial begin
        $readmemb("joltage.mem", joltages);
        $readmemb("config.mem", configs);
        $readmemb("buttons.mem", buttons);
    end

    localparam IDLE = 3'd0;
    localparam LOAD = 3'd1;
    localparam FIND_PATTERN = 3'd2;
    localparam SUBTRACT_PATTERN = 3'd3;
    localparam DIVIDE_PATTERN = 3'd4;
    localparam FIND_MIN = 3'd5;
    localparam CALC_MIN = 3'd6;
    localparam DONE = 3'd7;

    reg [2:0] state;

    reg [DATA_WIDTH-1:0] current_joltages [0:MAX_JOLTAGES-1];
    reg [DATA_WIDTH-1:0] temp_joltages [0:MAX_JOLTAGES-1];
    reg [MAX_JOLTAGES-1:0] current_joltage_mask;
    reg [4:0] current_num_buttons; 
    reg [DATA_WIDTH-1:0] current_buttons [0:MAX_BUTTONS-1];

    reg [MAX_BUTTONS-1:0] pattern_table [0:(1<<MAX_BUTTONS)-1];         // 8192
    reg [DATA_WIDTH-1:0] pattern_count;
    reg [DATA_WIDTH-1:0] coefficients [0:(1<<MAX_BUTTONS)-1];

    reg [DATA_WIDTH-1:0] cost_table1 [0:(1<<MAX_BUTTONS)-1];         // 8192
    reg [DATA_WIDTH-1:0] cost_table2 [0:(1<<MAX_BUTTONS)-1];         // 8192

    integer iter1, iter2;
    reg [MAX_BUTTONS-1:0] combo_counter; 
    
    reg [DATA_WIDTH-1:0] min_presses [0:(1<<MAX_BUTTONS)-1];
    reg [DATA_WIDTH-1:0] final_min_presses;
    reg [2*DATA_WIDTH-1:0] sum_presses;
    reg diviable;
    reg similar;
    reg all_zero;

    reg [DATA_WIDTH-1:0] xor_result;
    reg [DATA_WIDTH-1:0] sum_result [0:MAX_JOLTAGES-1];
    reg [DATA_WIDTH-1:0] popcount;
    reg [DATA_WIDTH-1:0] sumcount;
    integer i, j;

    reg [DATA_WIDTH-1:0] press_count [0:MAX_BUTTONS-1]; 
    reg [DATA_WIDTH-1:0] max_presses; 

    function all_combinations_done;
        integer idx;
        begin
            all_combinations_done = 1'b1;
            for(idx = 0; idx < current_num_buttons; idx = idx + 1) begin
                if(press_count[idx] < max_presses) begin
                    all_combinations_done = 1'b0;
                end
            end
        end
    endfunction

    task increment_press_counter;
        integer idx;
        begin
            idx = 0;
            press_count[0] = press_count[0] + 1;
            
            while (idx < current_num_buttons && press_count[idx] > max_presses) begin
                press_count[idx] = 0;
                if (idx + 1 < current_num_buttons) begin
                    press_count[idx + 1] = press_count[idx + 1] + 1;
                end
                idx = idx + 1;
            end
        end
    endtask
    
    always @(*) begin
        xor_result = 0;
        popcount = 0;
        for (i = 0; i < MAX_BUTTONS; i = i + 1) begin
            if (i < current_num_buttons) begin
                if (combo_counter[i]) begin
                    xor_result = xor_result ^ current_buttons[i];
                    popcount = popcount + 1;
                end
            end
        end
    end

    always @(*) begin
        sumcount = 0;
        for(j = 0; j < MAX_JOLTAGES; j = j + 1) begin  
            sum_result[j] = 0;
        end
        for (i = 0; i < current_num_buttons; i = i + 1) begin
            for(j = 0; j < MAX_JOLTAGES; j = j + 1) begin  
                if(current_buttons[i][j] == 1'b1) begin
                    sum_result[j] = sum_result[j] + press_count[i];
                end
            end
            sumcount = sumcount + press_count[i];  
        end
        all_zero = 1'b1;
        for(i = 0; i < MAX_JOLTAGES; i = i + 1) begin
            if(temp_joltages[i] != 0) begin
                all_zero = 1'b0;
            end
        end
    end

    integer k;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            finished <= 0;
            result <= 0;
            iter1 <= 0;
            sum_presses <= 0;
            combo_counter <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        iter1 <= 0;
                        iter2 <= 0;
                        sum_presses <= 0;
                        state <= LOAD;
                        pattern_count <= 0;
                        for (i = 0; i < (1<<MAX_BUTTONS); i = i + 1) begin
                            coefficients[i] = 1;
                        end
                    end
                end
                LOAD: begin
                    if (iter1 < TOTAL_MACHINES) begin
                        for(i = 0; i < MAX_JOLTAGES; i = i + 1) begin
                            current_joltages[i] = joltages[(iter1 * MAX_JOLTAGES) + i];
                            current_joltage_mask[i] = (joltages[(iter1 * MAX_JOLTAGES) + i] % 2 != 0) ? 1'b1 : 1'b0;
                        end

                        current_num_buttons <= configs[iter1][31:16];

                        for (k = 0; k < MAX_BUTTONS; k = k + 1) begin
                            current_buttons[k] = buttons[(iter1 * MAX_BUTTONS) + k];
                        end

                        $display("Processing machine %0d with %0d buttons", iter1, configs[iter1][31:16]);
                        $display("Current joltages:");
                        for (i = 0; i < MAX_JOLTAGES; i = i + 1) begin
                            $display("  Joltage %0d: %0d", i, current_joltages[i]);
                        end
                        $display("Current buttons:");
                        for (k = 0; k < MAX_BUTTONS; k = k + 1) begin
                            $display("  Button %0d: %0d", k, current_buttons[k]);
                        end
                        $display("Current joltage mask: %b", current_joltage_mask);
                        combo_counter <= 0;
                        for(i = 0; i < (1<<MAX_BUTTONS); i = i + 1) begin
                            min_presses[i] = 32'hFFFFFFFF;
                            pattern_table[i] = 0;
                            cost_table1[i] = 0;
                            coefficients[i] = 1;
                        end
                        pattern_count <= 0; 
                        state <= FIND_PATTERN;
                    end else begin
                        state <= DONE;
                    end
                end
                FIND_PATTERN: begin
                    if (xor_result == current_joltage_mask) begin
                        pattern_table[pattern_count] = combo_counter;
                        cost_table1[pattern_count] = popcount;
                        pattern_count = pattern_count + 1;
                    end

                    combo_counter <= combo_counter + 1;
                    if (combo_counter == (1 << current_num_buttons) - 1) begin
                        state <= SUBTRACT_PATTERN;
                        iter2 <= 0;
                        combo_counter <= 0;
                        $display("Total valid patterns for machine %0d: %0d", iter1, pattern_count);
                        for(i=0; i < pattern_count; i = i + 1) begin
                            $display(" Pattern %0d: %b, Presses %0d", i, pattern_table[i], cost_table1[i]);
                        end
                    end
                end
                SUBTRACT_PATTERN: begin
                    for(i = 0; i < MAX_JOLTAGES; i = i + 1) begin
                        temp_joltages[i] = current_joltages[i];
                    end
                    for(i = 0; i < current_num_buttons; i = i + 1) begin
                        if(pattern_table[iter2][i] == 1'b1) begin           
                            for(j = 0; j < MAX_JOLTAGES; j = j + 1) begin  
                                if(current_buttons[i][j] == 1'b1) begin
                                    temp_joltages[j] = temp_joltages[j] - 1;
                                end
                            end
                        end
                    end

                    $display("temp_joltages after SUBTRACT_PATTERN for machine %0d:", iter1);
                    for (j = 0; j < MAX_JOLTAGES; j = j + 1) begin
                        $display("  Joltage %0d: %0d", j, temp_joltages[j]);
                    end
                    state <= DIVIDE_PATTERN;
                end
                DIVIDE_PATTERN: begin
                    diviable = 1'b1;
                    for(j = 0; j < MAX_JOLTAGES; j = j + 1) begin
                        if(temp_joltages[j] % 2 != 0 && !all_zero) begin
                            diviable = 1'b0;
                        end 
                    end

                    max_presses = 0;
                    for(j = 0; j < MAX_JOLTAGES; j = j + 1) begin
                        if(temp_joltages[j] > max_presses) begin
                            max_presses = temp_joltages[j];
                        end
                    end
                    // max_presses = max_presses + 2;

                    if(diviable == 1'b1) begin
                        for(j = 0; j < MAX_JOLTAGES; j = j + 1) begin
                            temp_joltages[j] = temp_joltages[j] / 2;
                        end
                        coefficients[iter2] = coefficients[iter2]*2;
                    end else begin
                        state <= FIND_MIN;
                        combo_counter <= 0;
                        for(i = 0; i < MAX_BUTTONS; i = i + 1) begin
                            press_count[i] <= 0; 
                        end
                        $display("max presses set to %0d for machine %0d", max_presses, iter1);
                        $display("Final joltages after DIVIDE_PATTERN for machine %0d:", iter1);
                        for (j = 0; j < MAX_JOLTAGES; j = j + 1) begin
                            $display("  Joltage %0d: %0d", j, temp_joltages[j]);
                        end
                        $display("Coefficients for patterns: %0d", coefficients[iter2]);
                    end
                end
                FIND_MIN: begin
                    similar = 1'b1;
                    
                    if(press_count[0] % 10 == 0 && press_count[1] == 0 && press_count[2] == 0) begin
                        $display("DEBUG: Current press_count = [%0d,%0d,%0d,%0d,%0d,%0d], max_presses=%0d", 
                                press_count[0], press_count[1], press_count[2], 
                                press_count[3], press_count[4], press_count[5], max_presses);
                    end

                    for(i = 0; i < MAX_JOLTAGES; i = i + 1) begin
                        if(sum_result[i] != temp_joltages[i]) begin
                            similar = 1'b0;
                        end
                        // $display(" sum_result[%0d]: %0d, current_joltages[%0d]: %0d", i, sum_result[i], i, temp_joltages[i]);
                    end
                    if(similar) begin
                        if(min_presses[iter2] > sumcount) begin
                            min_presses[iter2] = sumcount;
                            $display(" Found similar pattern with presses: %0d", sumcount);
                        end
                    end
                    increment_press_counter();
                    if(all_combinations_done()) begin
                        $display("DEBUG: Finished searching for pattern %0d. Final press_count = [%0d,%0d,%0d,%0d,%0d,%0d]", 
                                    iter2, press_count[0], press_count[1], press_count[2], 
                                    press_count[3], press_count[4], press_count[5]);
                        for(i = 0; i < MAX_BUTTONS; i = i + 1) begin
                            press_count[i] <= 0;
                        end
                        
                        if(iter2 == pattern_count - 1) begin
                            state <= CALC_MIN;
                        end else begin 
                            state <= SUBTRACT_PATTERN;
                            iter2 <= iter2 + 1;
                        end
                    end
                end
                CALC_MIN: begin
                    final_min_presses = 32'hFFFFFFFF;
                    for(i = 0; i < pattern_count; i = i + 1) begin
                        $display("min presses[%0d]: %0d, coefficients[%0d]: %0d, cost_table1[%0d]: %0d", i, min_presses[i], i, coefficients[i], i, cost_table1[i]);
                        if(min_presses[i] != 32'hFFFFFFFF) begin
                            if(final_min_presses > (min_presses[i]*coefficients[i] + cost_table1[i])) begin
                                final_min_presses = min_presses[i]*coefficients[i] + cost_table1[i];
                            end
                        end
                    end
                    sum_presses = sum_presses + final_min_presses;
                    $display("Final minimum presses for machine %0d: %0d", iter1, final_min_presses);

                    if(iter1 < TOTAL_MACHINES - 1) begin
                        iter1 <= iter1 + 1;
                        state <= LOAD;
                    end else begin
                        state <= DONE;
                    end
                end
                DONE: begin
                    result <= sum_presses;
                    finished <= 1;
                end
            endcase
        end
    end
endmodule