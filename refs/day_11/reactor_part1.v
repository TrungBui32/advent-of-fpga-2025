module reactor_part1(
    input clk,
    input rst, 
    input start, 
    output reg finished,
    output reg [63:0] result
);

    localparam ASCII_WIDTH = 8;
    localparam DEVICE_WIDTH = 3*ASCII_WIDTH;  
    localparam MAX_DEST = 20;
    localparam NUM_DEVICES = 581;
    localparam OUT = 24'b01101111_01110101_01110100;
    localparam YOU = 24'b01111001_01101111_01110101;
    localparam DATA_WIDTH = 32;

    localparam IDLE = 3'd0;
    localparam LOOP1 = 3'd1;
    localparam LOOP2 = 3'd2;
    localparam UPDATE = 3'd3;
    localparam DONE = 3'd4;

    reg [2:0] state;

    reg [DEVICE_WIDTH-1:0] sources [0:NUM_DEVICES-1];
    reg [DEVICE_WIDTH*MAX_DEST-1:0] destinations [0:NUM_DEVICES-1];
    reg [MAX_DEST*DATA_WIDTH-1:0] dest_counts [0:NUM_DEVICES-1];  // count of reached destinations for each source
    reg [DATA_WIDTH-1:0] sum_dest_counts [0:NUM_DEVICES-1]; // total reached destinations for each source
    reg [DATA_WIDTH-1:0] dest_reached [0:NUM_DEVICES-1]; // count number of destinations connected
    reg [5:0] num_dests [0:NUM_DEVICES-1];              // initially store number of destination of each source
    reg [NUM_DEVICES-1:0] updated;                     // set to 1 if a source's destination count was updated for other source

    reg [DATA_WIDTH-1:0] iter1, iter2, iter3;
    reg [DEVICE_WIDTH-1:0] current_source, current_dest;
    reg [DATA_WIDTH-1:0] you_index;
    reg [DATA_WIDTH-1:0] current_count;

    integer i;
    initial begin
        $readmemb("source.mem", sources);
        $readmemb("destination.mem", destinations);
        $readmemb("count.mem", num_dests);
        for(i = 0; i < NUM_DEVICES; i = i + 1) begin
            if(destinations[i][DEVICE_WIDTH-1:0] == OUT) begin
                dest_reached[i] = 32'd1;
                dest_counts[i][DATA_WIDTH-1:0] = 1;
                sum_dest_counts[i] = 1;
            end else begin
                dest_reached[i] = 32'd0;
                dest_counts[i] = 0;
                sum_dest_counts[i] = 0;
            end
            updated[i] = 1'b0;
            if(sources[i] == YOU) begin
                you_index = i;
            end
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            finished <= 1'b0;
            result <= 64'd0;
            state <= IDLE; 
        end else begin
            case(state)
                IDLE: begin
                    if (start) begin
                        iter1 <= 0;
                        state <= LOOP1;
                    end
                end
                LOOP1: begin              
                    if(num_dests[you_index] == dest_reached[you_index]) begin
                        state <= DONE;
                    end else if(num_dests[iter1] == dest_reached[iter1] && !updated[iter1]) begin
                        iter2 <= 0;
                        state <= LOOP2;
                        current_source <= sources[iter1];
                        current_count <= sum_dest_counts[iter1];
                    end else begin
                        iter1 <= iter1 + 1;
                    end
                end
                LOOP2: begin
                    if(iter2 == NUM_DEVICES -1) begin
                        state <= LOOP1;
                        iter1 <= 0;
                    end else begin
                        iter2 <= iter2 + 1;
                        iter3 <= 0;
                        state <= UPDATE;
                    end
                end
                UPDATE: begin
                    current_dest = destinations[iter2][(iter3+1)*DEVICE_WIDTH-1 -: DEVICE_WIDTH];
                    if(current_dest == current_source) begin
                        dest_counts[iter2][(iter3+1)*DEVICE_WIDTH-1 -: DEVICE_WIDTH] <= current_count;
                        dest_reached[iter2] <= dest_reached[iter2] + 1;
                        sum_dest_counts[iter2] <= sum_dest_counts[iter2] + current_count;
                    end
                    if(iter3 == num_dests[iter2] -1) begin
                        state <= LOOP2;
                        updated[iter1] <= 1'b1;
                    end else begin
                        iter3 <= iter3 + 1;
                    end
                end
                DONE: begin
                    finished <= 1'b1;
                    result <= sum_dest_counts[you_index];
                end
            endcase    
        end
    end

endmodule