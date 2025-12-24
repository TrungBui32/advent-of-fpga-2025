# Advent of FPGA 2025

A collection of Verilog solutions based on Advent of Code 2025 problems implemented for [Advent of FPGA](https://blog.janestreet.com/advent-of-fpga-challenge-2025/). 

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

**Input Handling**: Raw input data is stored in `input.txt` files, then converted to memory files (`.mem`) using Python scripts (`convert_input.py`).

## Problems Overview

### Day 1: [Secret Entrance](https://adventofcode.com/2025/day/1)
- **Part 1**:
- **Part 2**: 

### Day 2: [Gift Shop](https://adventofcode.com/2025/day/2)
- **Part 1**: this solution takes advantage of the fact that all the input ranges have start and end numbers with roughly the same number of digits, they never differ by more than one digit (which tbh helps me saving a lot of effort to address that case =). Instead of doing expensive division and modulo operations in hardware, I use binary-coded decimal (BCD) where each digit takes exactly 4 bits, making it easy to grab individual digits through bit-shifting. The main idea is to split each number in half and work with just the first half, I count from the start's first half to the end's first half, sum them up, then multiply by the right power of 10 (using shifts instead of actual multiplication since shifting is way faster, but the trade-off is a few more cycles). After that, I add the sum again to account for the second half. I also check the second halves of the start and end numbers to adjust the boundaries if needed like if the start number's second half is bigger than its first half, I bump up the first half by one. Actually, using shifts instead of multiply saves about 0.2 ns in the hardware implementation.
- **Part 2**: It is basically brute force approach which is not optimal (I guess?) but I still trying to use approach of part 1 in this. 

### Day 3: [Lobby](https://adventofcode.com/2025/day/3)
- **Part 1**: 
- **Part 2**: 

### Day 4: [Printing Department](https://adventofcode.com/2025/day/4)
- **Part 1**:
- **Part 2**: 

### Day 5: [Cafeteria](https://adventofcode.com/2025/day/5)
- **Part 1**:
- **Part 2**:

### Day 6: [Trash Compactor](https://adventofcode.com/2025/day/6)
- **Part 1**: 
- **Part 2**:

### Day 7: [Laboratories](https://adventofcode.com/2025/day/7)
- **Part 1**: 
- **Part 2**:

### Day 8: [Playground](https://adventofcode.com/2025/day/8)
- **Part 1**: 
- **Part 2**: 

### Day 9: [Movie Theater](https://adventofcode.com/2025/day/9) 
- **Part 1**: 
- **Part 2**: 

### Day 10: [Factory](https://adventofcode.com/2025/day/10)
- **Part 1**: 
- **Part 2**: 

### Day 11: [Reactor](https://adventofcode.com/2025/day/11)
- **Part 1**:
- **Part 2**:

### Day 12: [Christmas Tree Farm](https://adventofcode.com/2025/day/12)
- **Part 1**: 
- **Part 2**: 

### File Structure (per day)
```
day_X/
├── input.txt                   # Raw problem input
├── convert_input.py            # Input preprocessing script
├── *.mem                       # Memory initialization files
├── *_part1.v                   # Part 1 Verilog implementation
├── *_part2.v                   # Part 2 Verilog implementation
├── test_day_X.py               # Cocotb test file (supporting print result)
└── Makefile                    # Build configuration
```

