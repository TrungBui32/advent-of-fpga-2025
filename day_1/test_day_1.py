import cocotb
from cocotb.triggers import Timer

@cocotb.test()
async def test(dut):
    await Timer(1, units='ns')
    
