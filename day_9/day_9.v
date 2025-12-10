module day_9(
    input clk,
    input rst,
    input start,
    output reg finished,
    output reg [63:0] result
);

    localparam NUM_ELEMENTS = 496;
    localparam COMPRESSED_MAP = NUM_ELEMENTS / 2;
    
    reg [31:0] x [0:NUM_ELEMENTS-1];
    reg [31:0] y [0:NUM_ELEMENTS-1];

    reg [31:0] x_compressed [0:NUM_ELEMENTS-1];
    reg [31:0] y_compressed [0:NUM_ELEMENTS-1];

    reg [31:0] x_unique [0:NUM_ELEMENTS/2-1];
    reg [31:0] y_unique [0:NUM_ELEMENTS/2-1];

    reg [COMPRESSED_MAP-1:0] is_green [0:COMPRESSED_MAP-1];
    reg is_inside, is_on_edge;
    reg [3:0] state;
    localparam IDLE = 4'd0;
    localparam SORT_X = 4'd1;
    localparam SORT_Y = 4'd2;
    localparam MAP = 4'd3;
    localparam MARK_GREEN = 4'd4;
    localparam TEST_RECTANGLE = 4'd5;
    localparam CHECK_EDGES = 4'd6;
    localparam DONE = 4'd7;
    
    reg [31:0] corner1_idx, corner2_idx; 
    reg [31:0] rect_x1, rect_y1, rect_x2, rect_y2;
    reg [63:0] current_area;
    reg [63:0] largest_area;
    
    reg rect_valid;
    reg sorted;
    reg [31:0] sort_iter_x, sort_iter_y;
    reg [31:0] original_x, original_y;
    reg [31:0] iter1, iter2;
    reg [31:0] dx, dy;

    integer i, j;
    
    initial begin
        $readmemb("x.mem", x);
        $readmemb("y.mem", y);
    end

    function automatic integer count_crossings;
        input [31:0] px, py;
        integer m;
        reg [31:0] x1, y1, x2, y2;
        reg [31:0] intersect_x;
        integer count;
        begin
            count = 0;
            for(m = 0; m < NUM_ELEMENTS; m = m + 1) begin
                x1 = x_compressed[m];
                y1 = y_compressed[m];
                x2 = (m == NUM_ELEMENTS - 1) ? x_compressed[0] : x_compressed[m + 1];
                y2 = (m == NUM_ELEMENTS - 1) ? y_compressed[0] : y_compressed[m + 1];
                
                if(y1 > y2) begin
                    x1 = x2; 
                    x2 = x_compressed[m];
                    y1 = y2; 
                    y2 = y_compressed[m];
                end
                
                if(py >= y1 && py < y2 && y1 != y2) begin
                    intersect_x = x1 + ((py - y1) * (x2 - x1)) / (y2 - y1);
                    if(intersect_x > px) begin
                        count = count + 1;
                    end
                end
            end
            count_crossings = count;
        end
    endfunction

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            finished <= 0;
            result <= 0;
            largest_area <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        corner1_idx <= 0;
                        corner2_idx <= 0;
                        largest_area <= 0;
                        state <= SORT_X;
                        sorted <= 0;
                        sort_iter_x <= 0;
                        sort_iter_y <= 0;
                        iter1 <= 0;
                        iter2 <= 0;
                        for(i = 0; i < NUM_ELEMENTS; i = i + 2) begin
                            x_unique[i/2] = x[i];
                            y_unique[(i+1)/2] = y[i];
                        end
                    end
                end
                SORT_X: begin
                    if(sort_iter_x[0] == 0) begin
                        sorted = 1;
                        for(i = 0; i < NUM_ELEMENTS / 2 - 1; i = i + 2) begin
                            if(x_unique[i] > x_unique[i + 1]) begin
                                x_unique[i] <= x_unique[i + 1];
                                x_unique[i + 1] <= x_unique[i];
                                sorted <= 0;
                            end
                        end 
                    end else begin
                        sorted = 1;
                        for(i = 1; i < NUM_ELEMENTS / 2 - 1; i = i + 2) begin
                            if(x_unique[i] > x_unique[i + 1]) begin
                                x_unique[i] <= x_unique[i + 1];
                                x_unique[i + 1] <= x_unique[i];
                                sorted <= 0;
                            end
                        end
                    end
                    if(sort_iter_x == NUM_ELEMENTS - 1) begin
                        sort_iter_x <= 0;
                        sort_iter_y <= 0;
                        sorted <= 0;
                        state <= SORT_Y;
                    end else begin
                        sort_iter_x <= sort_iter_x + 1;
                    end
                end
                
                SORT_Y: begin
                    if(sort_iter_y[0] == 0) begin
                        sorted = 1;
                        for(i = 0; i < NUM_ELEMENTS / 2 - 1; i = i + 2) begin
                            if(y_unique[i] > y_unique[i + 1]) begin
                                y_unique[i] <= y_unique[i + 1];
                                y_unique[i + 1] <= y_unique[i];
                                sorted <= 0;
                            end
                        end
                    end else begin
                        sorted = 1;
                        for(i = 1; i < NUM_ELEMENTS / 2 - 1; i = i + 2) begin
                            if(y_unique[i] > y_unique[i + 1]) begin
                                y_unique[i] <= y_unique[i + 1];
                                y_unique[i + 1] <= y_unique[i];
                                sorted <= 0;
                            end
                        end
                    end
                    if(sort_iter_y == NUM_ELEMENTS - 1) begin
                        iter1 <= 0;
                        state <= MAP;
                    end else begin
                        sort_iter_y <= sort_iter_y + 1;
                    end
                end
                
                MAP: begin
                    original_x = x[iter1];
                    original_y = y[iter1];

                    for(i = 0; i < NUM_ELEMENTS / 2; i = i + 1) begin
                        if(original_x == x_unique[i]) begin
                            x_compressed[iter1] <= i;
                        end
                    end
                    for(i = 0; i < NUM_ELEMENTS / 2; i = i + 1) begin
                        if(original_y == y_unique[i]) begin
                            y_compressed[iter1] <= i;
                        end
                    end

                    if(iter1 == NUM_ELEMENTS - 1) begin
                        iter1 <= 0;
                        iter2 <= 0;
                        state <= MARK_GREEN;
                    end else begin
                        iter1 <= iter1 + 1;
                    end
                end
                
                MARK_GREEN: begin
                    if(iter1 < COMPRESSED_MAP) begin
                        if(iter2 < COMPRESSED_MAP) begin
                            is_inside = (count_crossings(iter2, iter1) & 1);
                            is_on_edge = 0;
                            for(i = 0; i < NUM_ELEMENTS; i = i + 1) begin
                                j = (i == NUM_ELEMENTS - 1) ? 0 : i + 1;
                                if(y_compressed[i] == y_compressed[j] && y_compressed[i] == iter1) begin
                                    if((x_compressed[i] <= iter2 && iter2 <= x_compressed[j]) ||
                                    (x_compressed[j] <= iter2 && iter2 <= x_compressed[i])) begin
                                        is_on_edge = 1;
                                    end
                                end
                                if(x_compressed[i] == x_compressed[j] && x_compressed[i] == iter2) begin
                                    if((y_compressed[i] <= iter1 && iter1 <= y_compressed[j]) ||
                                    (y_compressed[j] <= iter1 && iter1 <= y_compressed[i])) begin
                                        is_on_edge = 1;
                                    end
                                end
                            end
                            is_green[iter1][iter2] <= is_inside || is_on_edge;
                            iter2 <= iter2 + 1;
                        end else begin
                            iter2 <= 0;
                            iter1 <= iter1 + 1;
                        end
                    end else begin
                        corner1_idx <= 0;
                        corner2_idx <= 0;
                        state <= TEST_RECTANGLE;
                    end
                end
                TEST_RECTANGLE: begin
                    if(corner1_idx < NUM_ELEMENTS) begin
                        if(corner2_idx < NUM_ELEMENTS) begin
                            if(corner1_idx != corner2_idx) begin
                                rect_x1 <= (x_compressed[corner1_idx] < x_compressed[corner2_idx]) ? x_compressed[corner1_idx] : x_compressed[corner2_idx];
                                rect_y1 <= (y_compressed[corner1_idx] < y_compressed[corner2_idx]) ? y_compressed[corner1_idx] : y_compressed[corner2_idx];
                                rect_x2 <= (x_compressed[corner1_idx] > x_compressed[corner2_idx]) ? x_compressed[corner1_idx] : x_compressed[corner2_idx];
                                rect_y2 <= (y_compressed[corner1_idx] > y_compressed[corner2_idx]) ? y_compressed[corner1_idx] : y_compressed[corner2_idx];

                                if(rect_x1 == rect_x2 || rect_y1 == rect_y2) begin
                                    corner2_idx <= corner2_idx + 1;
                                end else begin
                                    dx = (x[corner1_idx] > x[corner2_idx]) ? (x[corner1_idx] - x[corner2_idx]) : (x[corner2_idx] - x[corner1_idx]);
                                    dy = (y[corner1_idx] > y[corner2_idx]) ? (y[corner1_idx] - y[corner2_idx]) : (y[corner2_idx] - y[corner1_idx]);
                                    current_area = (dx + 1 ) * (dy + 1);
                                    if(current_area <= largest_area) begin
                                        corner2_idx <= corner2_idx + 1;
                                    end else begin
                                        state <= CHECK_EDGES;
                                    end
                                end
                            end else begin
                                corner2_idx <= corner2_idx + 1;
                            end
                        end else begin
                            corner2_idx <= 0;
                            corner1_idx <= corner1_idx + 1;
                        end
                    end else begin
                        state <= DONE;
                    end
                end
                CHECK_EDGES: begin
                    rect_valid = 1;
                    for(i = rect_x1; i <= rect_x2; i = i + 1) begin
                        if(!is_green[rect_y1][i] || !is_green[rect_y2][i]) begin
                            rect_valid = 0;
                        end
                    end
                    for(j = rect_y1; j <= rect_y2; j = j + 1) begin
                        if(!is_green[j][rect_x1] || !is_green[j][rect_x2]) begin
                            rect_valid = 0;
                        end
                    end
                    
                    if(rect_valid && current_area > largest_area) begin
                        largest_area <= current_area;
                    end
                    
                    corner2_idx <= corner2_idx + 1;
                    state <= TEST_RECTANGLE;
                end
                DONE: begin
                    result <= largest_area;
                    finished <= 1;
                end
            endcase
        end
    end

endmodule
