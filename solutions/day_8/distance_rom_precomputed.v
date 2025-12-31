module day_8(
    input clk,
    input rst,
    input start,
    output reg finished,
    output reg [63:0] result
);
    localparam PARALLEL = 62;
    localparam NUM_ELEMENTS = 1000;
    localparam ITEM_WIDTH = 36 + 10 + 10; // 56
    localparam TABLE_HEIGHT = (NUM_ELEMENTS - 1) * NUM_ELEMENTS / 2;       // 499500
    localparam DISTANCE_WIDTH = 36;
    localparam INDEX_WIDTH = 10;
    localparam COORDINATE_WIDTH = 17;

    reg [DISTANCE_WIDTH-1:0] temp_dist [0:PARALLEL-1];
    reg [INDEX_WIDTH-1:0] temp_src [0:PARALLEL-1];
    reg [INDEX_WIDTH-1:0] temp_dst [0:PARALLEL-1];

    integer i;

    reg [ITEM_WIDTH-1:0] rom [0:TABLE_HEIGHT-1];

    reg [COORDINATE_WIDTH-1:0] x_ref [0:NUM_ELEMENTS-1];
    reg [COORDINATE_WIDTH-1:0] y_ref [0:NUM_ELEMENTS-1];
    reg [COORDINATE_WIDTH-1:0] z_ref [0:NUM_ELEMENTS-1];

    reg signed [COORDINATE_WIDTH:0] dx, dy, dz; 

    reg [NUM_ELEMENTS-1:0] box_valid;

    reg [INDEX_WIDTH:0] circuit_table [0:NUM_ELEMENTS-1][0:NUM_ELEMENTS-1];
    reg [INDEX_WIDTH:0] circuit_size [0:NUM_ELEMENTS-1];
    reg [INDEX_WIDTH:0] box_circuit [0:NUM_ELEMENTS-1];


    integer batch, k, m;
    integer s, d;
    reg [DISTANCE_WIDTH-1:0] dist_sq;
    reg [ITEM_WIDTH-1:0] temp_line;
    reg [18:0] rom_addr;

    reg [INDEX_WIDTH-1:0] num_circuits;
    reg [INDEX_WIDTH-1:0] last_src, last_dst;

    reg [INDEX_WIDTH-1:0] dest_circuit_index;
    reg [INDEX_WIDTH-1:0] src_circuit_index;

    wire all_connected;
    assign all_connected = (num_circuits == 1);

    initial begin
        $readmemb("x.mem", x_ref);
        $readmemb("y.mem", y_ref);
        $readmemb("z.mem", z_ref);

        s = 0;
        d = 1;

        for (batch = 0; batch < TABLE_HEIGHT; batch = batch + 1) begin
            temp_line = 0;
            dx = x_ref[s] - x_ref[d];
            dy = y_ref[s] - y_ref[d];
            dz = z_ref[s] - z_ref[d];

            dist_sq = (dx*dx) + (dy*dy) + (dz*dz);

            temp_line = {dist_sq, s, d};

            if (d == NUM_ELEMENTS - 1) begin
                s = s + 1;
                d = s + 1;
            end else begin
                d = d + 1;
            end
            rom[batch] = temp_line;
        end

        for (k = 0; k < NUM_ELEMENTS; k = k + 1) begin
            circuit_size[k] = 1;
            box_circuit[k] = k;
            for (m = 0; m < NUM_ELEMENTS; m = m + 1) begin 
                circuit_table[k][m] = 0;
            end
            circuit_table[k][0] = k; 
        end
    end

    reg [2:0] state;

    localparam IDLE = 3'd0;
    localparam FETCH = 3'd1;
    localparam LOAD = 3'd2;
    localparam SORT = 3'd3;
    localparam WRITEBACK = 3'd6;
    localparam CONNECT_BOX = 3'd4;
    localparam DONE = 3'd5;

    reg [31:0] iter1, iter2, sort_iter;

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            state <= IDLE;
            rom_addr <= 0;
            finished <= 0;
            result <= 0;
            sort_iter <= 0;
            num_circuits <= NUM_ELEMENTS;
        end else begin
            case(state)
                IDLE: begin
                    if(start) begin
                        state <= LOAD;
                        rom_addr <= 0;
                        num_circuits <= NUM_ELEMENTS;
                        iter1 <= 0;
                        iter2 <= 0;
                        $display("Starting Day 8 Computation");
                    end
                    finished <= 0;
                end
                LOAD: begin
                    for(i=0; i<PARALLEL; i=i+1) begin
                        temp_dist[i] <= rom[rom_addr + i][55:20];
                        temp_src[i] <= rom[rom_addr + i][19:10];
                        temp_dst[i] <= rom[rom_addr + i][9:0];
                    end
                    if(rom_addr % 100 == 0)
                        $display("Loaded batch at address %d", rom_addr);
                    if(iter1 == 8612) begin         
                        state <= CONNECT_BOX;
                        iter1 <= 0;
                    end else begin
                        state <= SORT;
                    end
                end
                SORT: begin
                    if(sort_iter[0] == 0) begin
                        for(i = 0; i < PARALLEL-1; i = i + 2) begin
                            if(temp_dist[i] > temp_dist[i+1]) begin
                                {temp_dist[i], temp_dist[i+1]} <= {temp_dist[i+1], temp_dist[i]};
                                {temp_src[i], temp_src[i+1]} <= {temp_src[i+1], temp_src[i]};
                                {temp_dst[i], temp_dst[i+1]} <= {temp_dst[i+1], temp_dst[i]};
                            end
                        end
                    end else begin
                        for(i = 1; i < PARALLEL-1; i = i + 2) begin
                            if(temp_dist[i] > temp_dist[i+1]) begin
                                {temp_dist[i], temp_dist[i+1]} <= {temp_dist[i+1], temp_dist[i]};
                                {temp_src[i], temp_src[i+1]} <= {temp_src[i+1], temp_src[i]};
                                {temp_dst[i], temp_dst[i+1]} <= {temp_dst[i+1], temp_dst[i]};
                            end
                        end
                    end 
                    if(sort_iter == PARALLEL-1) begin
                        sort_iter <= 0;
                        state <= WRITEBACK;
                    end else begin
                        sort_iter <= sort_iter + 1;
                    end 
                end
                WRITEBACK: begin
                    for(i = 0; i < PARALLEL && (rom_addr + i) < TABLE_HEIGHT; i = i + 1) begin
                        rom[rom_addr + i] <= {temp_dist[i], temp_src[i], temp_dst[i]};
                    end
                    if(rom_addr + PARALLEL >= TABLE_HEIGHT) begin
                        rom_addr <= 0;
                        iter1 <= iter1 + 1;
                        $display("Completed pass %d of sorting", iter1);
                    end else begin
                        rom_addr <= rom_addr + PARALLEL - 4;
                    end
                    state <= LOAD;
                end
                CONNECT_BOX: begin
                    $display("Connecting boxes, iteration %d", iter1);
                    if(!all_connected && iter1 < TABLE_HEIGHT) begin
                        src_circuit_index = box_circuit[rom[iter1][19:10]];
                        dest_circuit_index = box_circuit[rom[iter1][9:0]];
                        if(src_circuit_index != dest_circuit_index) begin
                            last_src <= rom[iter1][19:10];
                            last_dst <= rom[iter1][9:0];
                            for(i = 0; i < NUM_ELEMENTS; i = i + 1) begin
                                if(box_circuit[i] == dest_circuit_index) begin
                                    box_circuit[i] <= src_circuit_index;
                                end
                            end
                            num_circuits <= num_circuits - 1;
                        end
                        iter1 <= iter1 + 1;
                    end else begin
                        state <= DONE;
                    end
                end
                DONE: begin
                    $display("Computation Finished");
                    finished <= 1;
                    result <= x_ref[last_src] * x_ref[last_dst];
                end
            endcase
        end
    end
endmodule
