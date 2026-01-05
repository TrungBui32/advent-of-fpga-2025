import cocotb
from cocotb.triggers import Timer, RisingEdge
from cocotb.clock import Clock

def read_input_lines(filename):
    lines = []
    with open(filename, 'r') as f:
        for line in f:
            line = line.strip()
            if line:
                lines.append(line)
    return lines

def pack_bcd_digits_msb_first(digits):
    word = 0
    for i, digit in enumerate(digits):
        shift = (7 - i) * 4
        word |= (int(digit) << shift)
    return word

def string_to_packed_bcd_stream(lines):
    bcd_stream = []
    
    for line in lines:
        total_digits = len(line)
        digits_per_word = 8
        remainder = total_digits % digits_per_word
        
        if remainder != 0:
            padding_needed = digits_per_word - remainder
            line = '0' * padding_needed + line
        
        for i in range(0, len(line), 8):
            chunk = line[i:i+8]
            packed = pack_bcd_digits_msb_first(chunk)
            bcd_stream.append(packed)
    
    return bcd_stream

@cocotb.test()
async def test_pipelined_battery_processor(dut):
    
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    dut.rst.value = 1
    dut.valid_in.value = 0
    dut.data_in.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst.value = 0
    await RisingEdge(dut.clk)
    
    lines = read_input_lines("input.txt")
    
    data_stream = string_to_packed_bcd_stream(lines)
    
    for i, bcd_word in enumerate(data_stream):
        while not dut.ready.value:
            await RisingEdge(dut.clk)
        
        dut.data_in.value = bcd_word
        dut.valid_in.value = 1
        await RisingEdge(dut.clk)
    
    dut.valid_in.value = 0
    
    while not dut.finished.value:
        await RisingEdge(dut.clk)
    
    final_result = int(dut.result.value)
    dut._log.info(f"Final Result: {final_result}")