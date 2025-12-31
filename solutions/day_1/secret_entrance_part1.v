module secret_entrance_part1(
    input clk,
    input rst,
    input start,
    input valid_in,
    input [10:0] operation,
    output reg ready,
    output reg finished,
    output reg [31:0] result
);
    reg [31:0] counter;  
    reg [31:0] sum;
    
    reg stage1_valid;
    reg [9:0] stage1_rotation_amount;
    reg stage1_direction;
    
    reg [6:0] stage2_reduced_rotation;
    reg stage2_direction;
    reg stage2_valid;
    
    reg [31:0] stage3_new_position;
    reg stage3_valid;
    
    reg [31:0] dial_position;
    
    wire [31:0] current_position;
    
    assign current_position = stage3_valid ? stage3_new_position : dial_position;
    
    localparam IDLE = 2'd0;
    localparam RUNNING = 2'd1;
    localparam FLUSH = 2'd2;
    localparam DONE = 2'd3;

    reg [1:0] state;
    reg [2:0] flush_counter;

    always @(posedge clk) begin
        if(state == RUNNING) begin
            if (valid_in && ready) begin
                stage1_rotation_amount <= operation[9:0];
                stage1_direction <= operation[10];
                stage1_valid <= 1;
                counter <= counter + 1;
            end else begin
                stage1_valid <= 0;
            end
        end
    end

    always @(posedge clk) begin
        if(state == FLUSH || state == RUNNING) begin
            stage2_valid <= stage1_valid;
            stage2_direction <= stage1_direction;
            if (stage1_valid) begin
                stage2_reduced_rotation <= stage1_rotation_amount % 100;
            end
                    
            stage3_valid <= stage2_valid;
            if (stage2_valid) begin
                if (stage2_direction) begin
                    if (current_position + stage2_reduced_rotation >= 100) begin
                        stage3_new_position <= current_position + stage2_reduced_rotation - 100;
                    end else begin
                        stage3_new_position <= current_position + stage2_reduced_rotation;
                    end
                end else begin
                    if (current_position >= stage2_reduced_rotation) begin
                        stage3_new_position <= current_position - stage2_reduced_rotation;
                    end else begin
                        stage3_new_position <= current_position + 100 - stage2_reduced_rotation;
                    end
                end
            end
                        
            if (stage3_valid) begin
                dial_position <= stage3_new_position;
                if (stage3_new_position == 0) begin
                    sum <= sum + 1;
                end
            end
        end
    end

    always @(posedge clk) begin
        if(state == FLUSH) begin
            stage1_valid <= 0;
            flush_counter <= flush_counter + 1;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            finished <= 0;
            result <= 0;
            ready <= 0;
            state <= IDLE;
            counter <= 0;
            sum <= 0;
            dial_position <= 50;
            stage1_valid <= 0;
            stage1_rotation_amount <= 0;
            stage1_direction <= 0;
            stage2_valid <= 0;
            stage2_reduced_rotation <= 0;
            stage2_direction <= 0;
            stage3_valid <= 0;
            stage3_new_position <= 0;
            flush_counter <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        state <= RUNNING;
                        ready <= 1;
                        counter <= 0;
                        sum <= 0;
                        dial_position <= 50;
                        finished <= 0;
                        flush_counter <= 0;
                    end
                end
                RUNNING: begin
                    if (!valid_in && !stage1_valid && counter > 0) begin
                        ready <= 0;
                        state <= FLUSH;
                        flush_counter <= 0;
                    end
                end
                FLUSH: begin
                    if (flush_counter >= 3) begin
                        state <= DONE;
                    end
                end
                DONE: begin
                    result <= sum;
                    finished <= 1;
                    ready <= 0;
                end
            endcase
        end
    end
endmodule