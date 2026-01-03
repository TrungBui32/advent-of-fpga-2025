# Advent of FPGA 2025

A collection of Verilog solutions based on Advent of Code 2025 problems implemented for [Advent of FPGA](https://blog.janestreet.com/advent-of-fpga-challenge-2025/). My target hardware is KV260 (K26C SOM) although I don't really have any board. To explain, I chose CocoTB in this challenge simply because I used it before, I see that I need to process input at first, and I just need the final answer, I don't think anything better than CocoTB in this context.

## How to run

Prerequisites before run:
- Icarus Verilog (iverilog) version 11.0 (stable)
- Python 3.10
- CocoTB v1.9.2
- Make

All solutions follow a consistent build system using Makefiles. To run any day's solution:

```bash
cd day_X
make
```

**Input Handling**: Raw input data is stored in `input.txt` files.

## Problems Overview

### Day 1: [Secret Entrance](https://adventofcode.com/2025/day/1)

**Part 1**: Pretty straightforward problem, but I ran into two fun surprises while optimizing.

I built a simple 3-stage pipeline with data forwarding to handle the dial rotations. The modulo operator (%) is usually expensive, so I expected that to be the bottleneck. But when I set an initial target of 500MHz, the timing report showed something weird:

![](pictures/day_1/pic_1.png)

Only two paths over 1ns, and neither of them were the arithmetic I was worried about. So I dug into the synthesis results to see what was going on:

<p align="center">
  <img src="pictures/day_1/pic_2.png" width="35%" />
  <img src="pictures/day_1/pic_3.png" width="55%" />
</p>

Turns out the critical path is actually in the FSM - the `ready` signal creates a long combinational path between state registers. The second-longest path is just bad routing that could probably be improved with better placement.

I got curious and cranked things up to 1GHz to see what would happen. The critical path dropped to 0.529ns, which seemed great until I realized I'd hit the BUFGCE pulse width limit at 1.379ns (~725MHz):

![](pictures/day_1/pic_5.png)

That's a hard silicon constraint, not something I can optimize around. So the final design just targets 725MHz.

![](pictures/day_1/pic_6.png)

**Optimizations:**
- 3-stage pipeline: input parsing → modulo reduction → position calculation
- Data forwarding to avoid stalls between operations
- Modulo by 100 gets optimized by the synthesizer into efficient subtract-and-compare logic
- Separate paths for left/right rotation to reduce mux depth
- 3-cycle pipeline flush to drain in-flight operations before finishing

**Part 2**: Almost identical to Part 1. Main differences are adding a division to count how many times we cross zero during a rotation (e.g., R1000 crosses zero 10 times), and tweaking the crossing detection logic to catch passes through zero mid-rotation instead of just at the end.

**Additional optimizations:**
- Division by 100 to count complete revolutions (basically the inverse of the modulo)
- Single-cycle logic to detect zero crossings based on direction and position
- Running accumulator for total crossings across the pipeline

**Performance:**
- **Critical Path**: 0.786ns
- **Max Frequency**: 724.6 MHz  
- **Execution Time**: 4,202 cycles (~5.8µs)

### Day 2: [Gift Shop](https://adventofcode.com/2025/day/2)

**Part 1**: This problem asks us to find "invalid" product IDs in ranges - specifically, IDs that are some digit sequence repeated exactly twice (like `123123` or `6464`).

The key insight is that instead of checking every number in a range individually, we can calculate the sum of all invalid IDs mathematically. For a range with even-length IDs, we can split each number into two halves and look for cases where the halves match.

The pipeline takes each range and:
1. Converts the start/end from BCD (Binary-Coded Decimal) to binary
2. Splits each number at the midpoint into high and low halves
3. Finds the range of "first halves" that could produce valid repeating numbers
4. Uses the arithmetic series formula to sum all matching IDs: `sum = n * (first + last) / 2`
5. Multiplies by `10^(half_length) + 1` to reconstruct the actual repeated numbers

For example, in range `11-22`, the first halves are `1` and `2`, giving us numbers `11` and `22`. The sum is `(2 * (1+2) / 2) * 11 = 33`.

**Optimizations:**
- BCD input format allows easy digit extraction without division
- 14-stage pipeline with tree adders for BCD-to-binary conversion
- Arithmetic series formula avoids iterating through every number
- Pipelined multipliers for the final reconstruction step
- Special handling for odd-length ranges (they get rounded up to even length)

**Performance:**
- **Critical Path**: 2.848ns
- **Max Frequency**: 333MHz 
- **Pipeline Depth**: 14 stages
- **Execution Time**: 120 cycles (~0.36 µs)

**Part 2**: It is basically brute force approach which is not optimal (I guess?) but I still trying to use approach of part 1 in this. 

### Day 3: [Lobby](https://adventofcode.com/2025/day/3)
- **Part 1**: 
- **Part 2**: 

### Day 5: [Cafeteria](https://adventofcode.com/2025/day/5)
- **Part 1**:
- **Part 2**:

### Day 6: [Trash Compactor](https://adventofcode.com/2025/day/6)
- **Part 1**: 
- **Part 2**:

### Day 8: [Playground](https://adventofcode.com/2025/day/8)
- **Part 1**: 
- **Part 2**: 

### Day 12: [Christmas Tree Farm](https://adventofcode.com/2025/day/12)

My goal here was to minimize the critical path as much as possible to push the clock frequency. I used a 32-bit input interface with AXI-like handshaking (valid/ready signals).

Since the actual present shapes don't matter for this puzzle (we only care about the counts), the testbench ignores them completely and just feeds in the region width, height, and six present counts. Each region needs 8×8 = 64 bits of data, which takes 2 clock cycles to stream in.

The pipeline has 6 stages (not counting input reception):
- 1 stage to load the data
- 3 stages for arithmetic operations  
- 2 stages for comparison and accumulating results

![](pictures/day_12/pic_1.png)

**Optimizations:**
- Bit shifts instead of multiplication wherever possible
- Pipelined multipliers for area calculations
- Tree adders to reduce addition latency

**Performance:**
- **Critical Path**: 1.402ns
- **Max Frequency**: 680 MHz  
- **Execution Time**: 2,009 cycles (~2.96µs)

### File Structure (per day)
```
day_X/
├── input.txt                   # Raw problem input
├── *_part1.v                   # Part 1 Verilog implementation
├── *_part2.v                   # Part 2 Verilog implementation
├── test_day_X.py               # Cocotb test file (supporting print result)
└── Makefile                    # Build configuration
```

