import cocotb
from cocotb.triggers import Timer, RisingEdge
from cocotb.clock import Clock

@cocotb.test()
async def test(dut):
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    dut.rst.value = 1
    dut.start.value = 0
    await Timer(20, units='ns')
    dut.rst.value = 0
    await Timer(20, units='ns')
    
    dut.start.value = 1
    await RisingEdge(dut.clk)
    dut.start.value = 0
    
    while not dut.finished.value:
        await RisingEdge(dut.clk)
    
    print(f"Final result: {int(dut.result.value)}")