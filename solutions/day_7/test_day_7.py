import cocotb
from cocotb.triggers import Timer, RisingEdge, FallingEdge
from cocotb.clock import Clock

@cocotb.test()
async def test(dut):
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    dut.rst.value = 1
    dut.valid_in.value = 0
    dut.data_in.value = 0
    await RisingEdge(dut.clk)
    dut.rst.value = 0
    await RisingEdge(dut.clk)
    
    with open('input.txt', 'r') as f:
        lines = f.readlines()
    
    for row_idx, line in enumerate(lines):
        line = line.rstrip('\n')
        
        binary_str = line.replace('.', '0').replace('^', '1').replace('S', '1')
        
        bits_per_chunk = 32
        total_bits = len(binary_str)
        
        for chunk_idx in range(5):
            start_bit = chunk_idx * bits_per_chunk
            end_bit = min(start_bit + bits_per_chunk, total_bits)
            
            chunk_str = binary_str[start_bit:end_bit]
            chunk_str = chunk_str.ljust(bits_per_chunk, '0')
            
            chunk_str_reversed = chunk_str[::-1]
            data_value = int(chunk_str_reversed, 2)
            
            while not dut.ready.value:
                await RisingEdge(dut.clk)
            
            dut.data_in.value = data_value
            dut.valid_in.value = 1
            await RisingEdge(dut.clk)
            dut.valid_in.value = 0
    
    while not dut.finished.value:
        await RisingEdge(dut.clk)
    
    print(f"Final result: {int(dut.result.value)}")