import cocotb
from cocotb.triggers import RisingEdge
from cocotb.clock import Clock

def decimal_to_bcd(value):
    bcd = 0
    for i in range(4):
        digit = value % 10
        bcd |= (digit << (i * 4))
        value //= 10
    return bcd

def parse_input(filename):
    with open(filename, 'r') as f:
        lines = f.readlines()
    
    param_lines = [lines[i].rstrip('\n') for i in range(4)]
    operator_line = lines[4].rstrip('\n')
    
    max_length = max(len(line) for line in param_lines + [operator_line])
    param_lines = [line.ljust(max_length) for line in param_lines]
    operator_line = operator_line.ljust(max_length)
    
    problems = []
    col = 0
    current_problem = ['', '', '', '']
    in_problem = False
    
    while col < max_length:
        has_digit = any(col < len(line) and line[col].isdigit() for line in param_lines)
        
        if has_digit:
            in_problem = True
            for i in range(4):
                if col < len(param_lines[i]) and param_lines[i][col].isdigit():
                    current_problem[i] += param_lines[i][col]
                else:
                    current_problem[i] += '0'
        else:
            if in_problem:
                values = [int(p) if p else 0 for p in current_problem]
                
                problem_start = col - len(current_problem[0])
                op_char = None
                for op_col in range(problem_start, col):
                    if op_col < len(operator_line) and operator_line[op_col] in ['*', '+']:
                        op_char = operator_line[op_col]
                        break
                
                op_value = 1 if op_char == '+' else 0
                problems.append((values[0], values[1], values[2], values[3], op_value))
                
                current_problem = ['', '', '', '']
                in_problem = False
        
        col += 1
    
    if in_problem and any(current_problem):
        values = [int(p) if p else 0 for p in current_problem]
        problem_start = col - len(current_problem[0])
        op_char = None
        for op_col in range(problem_start, col):
            if op_col < len(operator_line) and operator_line[op_col] in ['*', '+']:
                op_char = operator_line[op_col]
                break
        op_value = 1 if op_char == '+' else 0
        problems.append((values[0], values[1], values[2], values[3], op_value))
    
    return problems

def encode_problem_to_words(line1, line2, line3, line4, op):
    bcd1 = decimal_to_bcd(line1)
    bcd2 = decimal_to_bcd(line2)
    bcd3 = decimal_to_bcd(line3)
    bcd4 = decimal_to_bcd(line4)
    
    word1 = (bcd2 << 16) | bcd1
    word2 = (bcd4 << 16) | bcd3
    
    return word1, word2, op

def read_and_chunk_input(filename):
    problems = parse_input(filename)
    data_stream = []
    
    for line1, line2, line3, line4, op in problems:
        word1, word2, op_val = encode_problem_to_words(line1, line2, line3, line4, op)
        data_stream.append((word1, op_val))
        data_stream.append((word2, op_val))
    
    return data_stream

@cocotb.test()
async def test_trash_compactor(dut):
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    dut.rst.value = 1
    dut.valid_in.value = 0
    dut.data_in.value = 0
    dut.op.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst.value = 0
    await RisingEdge(dut.clk)
    
    data_stream = read_and_chunk_input("input.txt")
    
    for word, op_val in data_stream:
        dut.data_in.value = word
        dut.op.value = op_val
        dut.valid_in.value = 1
        await RisingEdge(dut.clk)
    
    dut.valid_in.value = 0
    
    while not dut.finished.value:
        await RisingEdge(dut.clk)
    
    final_result = int(dut.result.value)
    dut._log.info(f"Final Result: {final_result}")