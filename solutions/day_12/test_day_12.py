import cocotb
from cocotb.triggers import Timer, RisingEdge
from cocotb.clock import Clock

def parse_input(filename):
    regions = []
    
    with open(filename, 'r') as f:
        lines = f.readlines()
    
    for line in lines:
        line = line.strip()
        if not line:
            continue
        
        if 'x' in line and ':' in line:
            parts = line.split(':')
            dimensions = parts[0].strip()
            counts = parts[1].strip()
            
            width, height = map(int, dimensions.split('x'))
            
            shape_counts = list(map(int, counts.split()))
            
            regions.append((width, height, shape_counts))
    
    return regions

def encode_region_to_words(width, height, shape_counts):
    words = []
    
    while len(shape_counts) < 6:
        shape_counts.append(0)
    
    word1 = (shape_counts[0] & 0xFF) | \
            ((shape_counts[1] & 0xFF) << 8) | \
            ((width & 0xFF) << 16) | \
            ((height & 0xFF) << 24)
    
    word2 = (shape_counts[2] & 0xFF) | \
            ((shape_counts[3] & 0xFF) << 8) | \
            ((shape_counts[4] & 0xFF) << 16) | \
            ((shape_counts[5] & 0xFF) << 24)
    
    words.append(word1)
    words.append(word2)
    
    return words

def read_and_chunk_input(filename):
    regions = parse_input(filename)
    chunks = []
    
    for width, height, shape_counts in regions:
        words = encode_region_to_words(width, height, shape_counts)
        chunks.extend(words)
    
    return chunks

@cocotb.test()
async def test_christmas_tree_farm(dut):
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
    
    for word in data_stream:
        dut.data_in.value = word
        dut.valid_in.value = 1
        await RisingEdge(dut.clk)
    
    dut.valid_in.value = 0
    while not dut.finished.value:
        await RisingEdge(dut.clk)
    
    final_result = int(dut.result.value)
    dut._log.info(f"Final Result: {final_result}")