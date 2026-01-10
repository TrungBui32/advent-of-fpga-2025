import cocotb
from cocotb.triggers import Timer, RisingEdge
from cocotb.clock import Clock

def decimal_to_bcd(decimal_num):
    if decimal_num == 0:
        return 0
    
    bcd = 0
    shift = 0
    
    while decimal_num > 0:
        digit = decimal_num % 10
        bcd |= (digit << shift)
        shift += 4
        decimal_num //= 10
    
    return bcd

def read_and_chunk_input(filename):
    chunks = []
    with open(filename, 'r') as f:
        content = f.read().strip()
        ranges = content.split(',')
        for r in ranges:
            start, end = map(int, r.split('-'))
            
            start_bcd = decimal_to_bcd(start)
            end_bcd = decimal_to_bcd(end)
            
            combined = (start_bcd << 40) | end_bcd
            
            chunks.append(combined & 0xFFFFFFFF)         
            chunks.append((combined >> 32) & 0xFFFFFFFF)  
            chunks.append((combined >> 64) & 0xFFFF)     
            
    return chunks

@cocotb.test()
async def test_pipelined_gift_shop(dut):
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    dut.rst.value = 1
    dut.valid_in.value = 0
    dut.data_in.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst.value = 0
    await RisingEdge(dut.clk)
    
    data_stream = read_and_chunk_input("input.txt")
    
    for i, word in enumerate(data_stream):
        while not dut.ready.value:
            await RisingEdge(dut.clk)
        
        dut.data_in.value = word
        dut.valid_in.value = 1
        await RisingEdge(dut.clk)
    
    dut.valid_in.value = 0
    while not dut.finished.value:
        await RisingEdge(dut.clk)
    
    final_result = int(dut.result.value)
    dut._log.info(f"Final Result: {final_result}")
    
