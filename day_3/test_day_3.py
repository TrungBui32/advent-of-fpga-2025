import cocotb
from cocotb.triggers import Timer, RisingEdge
from cocotb.clock import Clock

@cocotb.test()
async def test(dut):
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    while not dut.finished.value:
        await RisingEdge(dut.clk)
    
    print(f"Final result: {int(dut.output_sum.value)}")
