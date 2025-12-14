module day_11(
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
    localparam SVR = 24'b01110011_01110110_01110010;
    localparam FFT = 24'b01100110_01100110_01110100;
    localparam DAC = 24'b01100100_01100001_01100011;
    localparam DATA_WIDTH = 64;

    localparam IDLE = 3'd0;
    localparam LOOP1 = 3'd1;
    localparam LOOP2 = 3'd2;
    localparam UPDATE = 3'd3;
    localparam DONE = 3'd4;

    reg [2:0] state;

    reg [DEVICE_WIDTH-1:0] sources [0:NUM_DEVICES-1];
    reg [DEVICE_WIDTH*MAX_DEST-1:0] destinations [0:NUM_DEVICES-1];
    reg [MAX_DEST*DATA_WIDTH-1:0] dest_counts [0:NUM_DEVICES-1];  // count of reached destinations for each source
    reg [MAX_DEST*2-1:0] dest_path [0:NUM_DEVICES-1]; // 0: no path, 1: fft/dac, 2: both
    reg [1:0] source_path [0:NUM_DEVICES-1]; // total paths for each source
    reg [DATA_WIDTH-1:0] sum_dest_counts [0:NUM_DEVICES-1]; // total reached destinations for each source
    reg [DATA_WIDTH-1:0] dest_reached [0:NUM_DEVICES-1]; // count number of destinations connected
    reg [5:0] num_dests [0:NUM_DEVICES-1];              // initially store number of destination of each source
    reg [NUM_DEVICES-1:0] updated;                     // set to 1 if a source's destination count was updated for other source

    reg [DATA_WIDTH-1:0] iter1, iter2, iter3;
    reg [DEVICE_WIDTH-1:0] current_source, current_dest;
    reg [1:0] current_path;
    reg [DATA_WIDTH-1:0] svr_index;
    reg [DATA_WIDTH-1:0] current_count;

    integer i, j;
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
            if(sources[i] == SVR) begin
                svr_index = i;
            end
            dest_path[i] = 0;
            source_path[i] = 0;
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
                    if(num_dests[svr_index] == dest_reached[svr_index]) begin
                        state <= DONE;
                    end else if(num_dests[iter1] == dest_reached[iter1] && !updated[iter1]) begin
                        iter2 <= 0;
                        state <= LOOP2;
                        current_source <= sources[iter1];
                        current_count <= sum_dest_counts[iter1];
                        if(sources[iter1] == FFT || sources[iter1] == DAC) begin
                            current_path <= source_path[iter1] + 1;
                        end else begin
                            current_path <= source_path[iter1];
                        end
                    end else begin
                        iter1 <= iter1 + 1;
                    end
                end
                LOOP2: begin
                    if(iter2 < NUM_DEVICES) begin
                        state <= UPDATE;
                        iter3 <= 0;
                    end else begin
                        iter2 <= 0;
                        iter1 <= 0;
                        state <= LOOP1;
                    end
                end
                UPDATE: begin
                    current_dest = destinations[iter2][(iter3+1)*DEVICE_WIDTH-1 -: DEVICE_WIDTH];
                    if(current_dest == current_source) begin
                        dest_counts[iter2][(iter3+1)*DATA_WIDTH-1 -: DATA_WIDTH] <= current_count;
                        dest_reached[iter2] <= dest_reached[iter2] + 1;
                        dest_path[iter2][(iter3+1)*2-1 -: 2] <= current_path;
                        
                        if(source_path[iter2] == 0) begin
                            if(current_path == 2) begin
                                source_path[iter2] <= 2;
                                sum_dest_counts[iter2] <= current_count;
                            end else if(current_path == 1) begin
                                sum_dest_counts[iter2] <= current_count;
                                if (destinations[iter2][(iter3+1)*DEVICE_WIDTH-1 -: DEVICE_WIDTH] == FFT || destinations[iter2][(iter3+1)*DEVICE_WIDTH-1 -: DEVICE_WIDTH] == DAC) begin
                                    source_path[iter2] <= source_path[iter2] + 1;
                                end else begin
                                    source_path[iter2] <= 1;
                                end
                            end else begin
                                if (destinations[iter2][(iter3+1)*DEVICE_WIDTH-1 -: DEVICE_WIDTH] == FFT || destinations[iter2][(iter3+1)*DEVICE_WIDTH-1 -: DEVICE_WIDTH] == DAC) begin
                                    source_path[iter2] <= 1;
                                    sum_dest_counts[iter2] <= current_count;
                                end
                                sum_dest_counts[iter2] <= sum_dest_counts[iter2] + current_count;
                            end
                        end else if(source_path[iter2] == 1)begin
                            if(current_path == 2) begin
                                source_path[iter2] <= 2;
                                sum_dest_counts[iter2] <= current_count;
                            end else if(current_path == 1) begin
                                if (destinations[iter2][(iter3+1)*DEVICE_WIDTH-1 -: DEVICE_WIDTH] == FFT || destinations[iter2][(iter3+1)*DEVICE_WIDTH-1 -: DEVICE_WIDTH] == DAC) begin
                                    source_path[iter2] <= 2;
                                    sum_dest_counts[iter2] <= current_count;
                                end else begin
                                    sum_dest_counts[iter2] <= sum_dest_counts[iter2] + current_count;
                                end
                            end else begin
                                if (destinations[iter2][(iter3+1)*DEVICE_WIDTH-1 -: DEVICE_WIDTH] == FFT || destinations[iter2][(iter3+1)*DEVICE_WIDTH-1 -: DEVICE_WIDTH] == DAC) begin
                                    source_path[iter2] <= 1;
                                    sum_dest_counts[iter2] <= sum_dest_counts[iter2] + current_count;
                                end
                            end
                        end else begin
                            if(current_path == 2) begin
                                sum_dest_counts[iter2] <= sum_dest_counts[iter2] + current_count;
                            end
                        end
                    end
                    if(iter3 == num_dests[iter2] -1) begin
                        state <= LOOP2;
                        iter2 <= iter2 + 1;
                        updated[iter1] <= 1'b1;
                    end else begin
                        iter3 <= iter3 + 1;
                    end
                end
                DONE: begin
                    finished <= 1'b1;
                    result <= sum_dest_counts[svr_index];
                end
            endcase    
        end
    end

endmodule