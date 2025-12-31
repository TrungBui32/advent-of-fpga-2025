import cocotb
from cocotb.triggers import Timer, RisingEdge, FallingEdge
from cocotb.clock import Clock

def read_and_convert_input(filename):
    operations = []
    with open(filename, 'r') as f:
        for line in f:
            line = line.strip()
            if line:
                direction = line[0]
                value = int(line[1:])
                if direction == 'R':
                    hex_value = 0x400 | value  
                else:  
                    hex_value = value 
                operations.append(hex_value)
    return operations

@cocotb.test()
async def test(dut):
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    dut.rst.value = 1
    dut.start.value = 0
    dut.valid_in.value = 0
    dut.operation.value = 0
    await RisingEdge(dut.clk)
    dut.rst.value = 0
    await RisingEdge(dut.clk)
    
    operations = read_and_convert_input("input.txt")
    
    dut.start.value = 1
    await RisingEdge(dut.clk)
    dut.start.value = 0
    
    await RisingEdge(dut.clk)
    while not dut.ready.value:
        await RisingEdge(dut.clk)
    
    for i, op in enumerate(operations):
        dut.operation.value = op
        dut.valid_in.value = 1
        await RisingEdge(dut.clk)
        
    dut.valid_in.value = 0
    dut.operation.value = 0
    await RisingEdge(dut.clk)
    
    timeout = 0
    while not dut.finished.value and timeout < 1000:
        await RisingEdge(dut.clk)
        timeout += 1
    
    result = int(dut.result.value)
    
    dut._log.info(f"Final result: {result}")
    
    for _ in range(5):
        await RisingEdge(dut.clk)