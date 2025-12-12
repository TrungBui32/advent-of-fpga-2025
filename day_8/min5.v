module min5 #(
    parameter DATA_WIDTH = 64
)(
    input [DATA_WIDTH-1:0] val0, val1, val2, val3, val4,
    input valid0, valid1, valid2, valid3, valid4,
    output reg [DATA_WIDTH-1:0] min_val,
    output reg [2:0] min_idx,
    output reg min_valid
);
    localparam MAX_VAL = {DATA_WIDTH{1'b1}};

    always @(*) begin
        min_val = MAX_VAL;
        min_idx = 3'd0;
        min_valid = 1'b0;

        if (valid0 || valid1 || valid2 || valid3 || valid4) begin
            min_valid = 1'b1;
            
            if (valid0) begin
                min_val = val0;
                min_idx = 3'd0;
            end

            if (valid1 && (val1 < min_val || !valid0)) begin
                min_val = val1;
                min_idx = 3'd1;
            end

            if (valid2 && (val2 < min_val || (!valid0 && !valid1))) begin
                min_val = val2;
                min_idx = 3'd2;
            end

            if (valid3 && (val3 < min_val || (!valid0 && !valid1 && !valid2))) begin
                min_val = val3;
                min_idx = 3'd3;
            end

            if (valid4 && (val4 < min_val || (!valid0 && !valid1 && !valid2 && !valid3))) begin
                min_val = val4;
                min_idx = 3'd4;
            end
        end
    end
endmodule
