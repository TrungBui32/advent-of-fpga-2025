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
    
    ids = []
    with open("input.mem", "r") as f:
        for line in f:
            line = line.strip()
            if line:
                ids.append(int(line, 2))
    
    for idx, id_val in enumerate(ids):
        while not dut.ready.value:
            await RisingEdge(dut.clk)
        
        low_bits = id_val & 0xFFFFFFFF
        dut.data_in.value = low_bits
        dut.valid_in.value = 1
        await RisingEdge(dut.clk)
        
        high_bits = (id_val >> 32) & 0x3FFFF
        dut.data_in.value = high_bits
        dut.valid_in.value = 1
        await RisingEdge(dut.clk)
        
        dut.valid_in.value = 0
    
    while not dut.finished.value:
        await RisingEdge(dut.clk)
    
    print(f"Final result: {int(dut.result.value)}")
    