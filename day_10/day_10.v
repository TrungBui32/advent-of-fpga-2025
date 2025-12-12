module day_10(
    input clk,
    input rst,
    input start,
    output reg finished,
    output reg [63:0] result
);

    localparam MAX_BUTTONS = 13;
    localparam TOTAL_MACHINES = 171;
    localparam DATA_WIDTH = 32;

    reg [DATA_WIDTH-1:0] light_diagram  [0:TOTAL_MACHINES-1];
    reg [DATA_WIDTH-1:0] configs [0:TOTAL_MACHINES-1];         // num buttons + num light
    reg [DATA_WIDTH-1:0] buttons [0:(TOTAL_MACHINES*MAX_BUTTONS)-1];

    initial begin
        $readmemb("light.mem", light_diagram);
        $readmemb("config.mem", configs);
        $readmemb("buttons.mem", buttons);
    end

    localparam IDLE = 3'd0;
    localparam LOAD = 3'd1;
    localparam COMPUTE = 3'd2;
    localparam NEXT = 3'd3;
    localparam DONE = 3'd4;

    reg [2:0] state;

    reg [DATA_WIDTH-1:0] current_light;
    reg [4:0] current_num_buttons; 
    reg [DATA_WIDTH-1:0] current_buttons [0:MAX_BUTTONS-1];

    integer iter_1;
    reg [MAX_BUTTONS-1:0] combo_counter; 
    
    reg [31:0] min_presses;
    reg [63:0] sum_presses;

    reg [DATA_WIDTH-1:0] xor_result;
    reg [4:0] popcount;
    integer i;

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

    integer k;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            finished <= 0;
            result <= 0;
            iter_1 <= 0;
            sum_presses <= 0;
            combo_counter <= 0;
            min_presses <= 32'hFFFF_FFFF;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        iter_1 <= 0;
                        sum_presses <= 0;
                        state <= LOAD;
                    end
                end
                LOAD: begin
                    if (iter_1 < TOTAL_MACHINES) begin
                        current_light <= light_diagram[iter_1];
                        current_num_buttons <= configs[iter_1][31:16];
                        for (k = 0; k < MAX_BUTTONS; k = k + 1) begin
                            current_buttons[k] <= buttons[(iter_1 * MAX_BUTTONS) + k];
                        end
                        combo_counter <= 0;
                        min_presses <= 32'hFFFFFFFF; 
                        state <= COMPUTE;
                    end else begin
                        state <= DONE;
                    end
                end
                COMPUTE: begin
                    if (xor_result == current_light) begin
                        if (popcount < min_presses) begin
                            min_presses <= popcount;
                        end
                    end
                    combo_counter <= combo_counter + 1;
                    if (combo_counter == (1 << current_num_buttons) - 1) begin
                        state <= NEXT;
                    end
                end
                NEXT: begin
                    if (min_presses != 32'hFFFFFFFF) begin
                        sum_presses <= sum_presses + min_presses;
                    end
                    iter_1 <= iter_1 + 1;
                    state <= LOAD;
                end
                DONE: begin
                    result <= sum_presses;
                    finished <= 1;
                end
            endcase
        end
    end
endmodule