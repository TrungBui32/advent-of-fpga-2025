# Advent of FPGA 2025

A collection of Verilog solutions based on Advent of Code 2025 problems implemented for [Advent of FPGA](https://blog.janestreet.com/advent-of-fpga-challenge-2025/). My language and tools are Verilog, CocoTB, and Makefile. I target the KV260C board, which has a maximum achievable frequency of approximately 725MHz. Therefore, I analyze both the theoretical best-case execution time (using max frequency from timing analysis) and the realistic target execution time (constrained by board limitations).

*Note: In these solutions, I focus primarily on algorithmic optimizations and timing aspects such as critical path reduction. There are many other opportunities for optimization - such as using pblocks, refining constraints, manual slice placement, and clock domain planning - but since the goal is to solve Advent of Code (AoC) problems, I do not explore these techniques in depth.*

To explain, I chose CocoTB in this challenge simply because I used it before, I see that I need to process input at first, and I just need the final answer, I don't think anything better than CocoTB in this context.

My goal for these solutions is to maximize clock frequency while minimizing redundant computation cycles. I implement mathematical approaches wherever possible to reduce unnecessary iterations or checks.

All inputs are handled via 32-bit streaming, which allows the design to scale naturally to 10×, 100×, or even 1000× larger input sizes. Double-buffering and ping-pong memory structures are used to keep pipelines fully utilized without stalls, while column-aligned storage ensures efficient data access.

Key techniques and optimizations include:

- Binary-Coded Decimal (BCD) for efficient digit extraction and arithmetic.

- Karatsuba-like multiplication to decompose large multiplications into smaller, faster stages.

- Shift-and-add multipliers to replace costly combinational multiplication.

- Tree adders and reduction trees to minimize latency for sums, min/max, and OR/AND operations.

- Deep pipelining with stage balancing to optimize the critical path, combined with data forwarding to prevent stalls.

- Optimized control paths to reduce combinational delays in state machines.

- Partial computation and early termination to avoid unnecessary calculations and accelerate streaming input.

- Data forwarding to avoid stalling

All solutions are fully synthesizable and implementable on an FPGA using Vivado 2025.1. Resource usage is not reported, as the target board provides ample capacity relative to these designs (the maximum amount of LUT used is around 25% as I remember :panda_face: ).

## How to run

Prerequisites before run:
- Icarus Verilog (iverilog) version 11.0 (stable)
- Python 3.10
- CocoTB v1.9.2
- Make

All solutions follow a consistent build system using Makefiles. To run any day's solution:

`bash
cd day_X
make
`

Because each day has 2 part, I set default is part 1. To run part 2 test, just simply change the name of the VERILOG_SOURCES and TOPLEVEL in Makefile from 1 to 2. However, there are some problem has 1 part solution only.

**Input Handling**: Raw input data is stored in `input.txt` files.

### Folder Structure 
*Note: I have solved most problems but some solutions should not be judged as they preloaded the whole input which is not suitable for realistic application. That is why I placed them in folder refs, although some of them actually quite good and optimized a lot. The solutions I write here are all in folder solutions*
```
advent-of-fpga-2025
├── pictures                     # pictures for README 
├── refs                         # other solution not for judgement
├── solutions                    # 32-bit streaming solutions
└── README.md                    
```

## Performance Metrics
To evaluate each FPGA solution, the following metrics are reported:
- **Worst Negative Slack**: Worst negative slack after implimentation on Vivado.
- **Target Frequency**: The frequency constrained in Vivado for the actual FPGA. Accounts for board and silicon limitations.
- **Number of Cycles**: Total clock cycles to complete the computation for a single input. Shows pipeline depth and algorithm efficiency.
- **Target Execution Time**: Execution time at Target Frequency (realistic board-limited speed):
`
Target Execution Time = Number of Cycles / Target Frequency
`

## Problems Overview

### Day 1: [Secret Entrance](https://adventofcode.com/2025/day/1)

**Part 1**: Pretty straightforward problem, the only action needed is calculating the next position with currentb position and movement, but I ran into two fun surprises while optimizing.

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

**Performance:**
- **Worst Negative Slack**: 0.466 ns
- **Target Frequency**: 725 MHz 
- **Number of Cycles**: 4,202 cycles
- **Target Execution Time**: 5.80 µs

**Part 2**: Almost identical to Part 1. Main differences are adding a division to count how many times we cross zero during a rotation (e.g., R1000 crosses zero 10 times), and tweaking the crossing detection logic to catch passes through zero mid-rotation instead of just at the end.

**Additional optimizations:**
- Division by 100 to count complete revolutions (basically the inverse of the modulo)
- Single-cycle logic to detect zero crossings based on direction and position
- Running accumulator for total crossings across the pipeline

**Performance:**
- **Worst Negative Slack**: 0.466 ns
- **Target Frequency**: 725 MHz 
- **Number of Cycles**: 4,202 cycles
- **Target Execution Time**: 5.80 µs

### Day 2: [Gift Shop](https://adventofcode.com/2025/day/2)

**Part 1**: The most intuitive solution is to iterate through every number in the given range and check whether it is invalid. However, after inspecting the actual inputs, it becomes clear that the ranges can be very large, meaning most cycles would be wasted checking values that are trivially valid.

Instead, I take a mathematical approach based on the observation that, in Part 1, a number is invalid only when its first half and second half are identical. This allows the problem to be reformulated as *generating* invalid values directly, rather than *searching* for them.

To support efficient digit-level operations in hardware, I use Binary-Coded Decimal (BCD), which allows decimal digit extraction without division or modulo operations. This approach is well suited to Part 1 but becomes overly complex for Part 2, where the invalidity rules are significantly more complicated. I implemented a reference solution for Part 2, but I do not consider it suitable for fair performance comparison.

I also write a simple program count roughly number of loops I need if I use intuitive solution by calculating all numbers of values needed to be checked in ranges. The intuitive solution will take ~2,303,925 cycles, while my current solution needs only 120 cycles (~19200 times less) but still can run at over 300MHz shows that this solution is much better.

For example, consider the range ` 986003–1032361 `. The lower bound has 6 digits, while the upper bound has ` 7 ` digits. Since invalid numbers must have an even number of digits with identical halves, the largest possible invalid value in this range is ` 999999 `. Therefore, instead of checking the full range ` 986003–1032361 `, the effective range can be reduced to ` 986003–999999 `.

Next, observe that in ` 986003 `, the second half is smaller than the first half. This implies that the first invalid value is obtained by duplicating the first half, yielding 986986. From there, all remaining invalid values can be generated by incrementing the first half and duplicating it (e.g., 987987, 988988, and so on).

However, iterating through all such values is unnecessary, since their structure is already known. Rather than looping, the entire set of invalid values can be computed directly using a simple closed-form arithmetic calculation.
```
sum = n * (first + last) / 2
```
That makes sense right? Instead of loop from 986 to 999, I just use 1 formula. Then after that, I need to multiply that value with 10^(half length) + 1 to construct the final value.

By analyzing all provided inputs, I observed that the digit-length difference between the start and end of each range is at most one. This eliminates the need to handle cases such as transitioning from 2-digit to 4-digit numbers, greatly simplifying the hardware control logic.

Range                    | Digits      | 
-------------------------|-------------|
288352-412983            | 6-6         |
743179-799185            | 6-6         | 
7298346751-7298403555    | 10-10       | 
3269-7729                | 4-4         | 
3939364590-3939433455    | 10-10       | 
867092-900135            | 6-6         | 
25259-67386              | 5-5         | 
95107011-95138585        | 8-8         | 
655569300-655755402      | 9-9         | 
9372727140-9372846709    | 10-10       | 
986003-1032361           | 6-7         | 
69689-125217             | 5-6         |
417160-479391            | 6-6         |
642-1335                 | 3-4         | 
521359-592037            | 6-6         | 
7456656494-7456690478    | 10-10       | 
38956690-39035309        | 8-8         | 
1-18                     | 1-2         | 
799312-861633            | 6-6         | 
674384-733730            | 6-6         | 
1684-2834                | 4-4         | 
605744-666915            | 6-6         | 
6534997-6766843          | 7-7         | 
4659420-4693423          | 7-7         |
6161502941-6161738969    | 10-10       |
932668-985784            | 6-6         | 
901838-922814            | 6-6         | 
137371-216743            | 6-6         | 
47446188-47487754        | 8-8         |
117-403                  | 3-3         |
32-77                    | 2-2         |
35299661-35411975        | 8-8         |
7778-14058               | 4-5         |
83706740-83939522        | 8-8         |

This property makes the math-heavy approach both safe and efficient for all inputs in Part 1.

For Part 2, the invalidity rules are more complex and do not lend themselves to a clean closed-form solution. In this case, an iteration approach may be more appropriate, with optimizations such as skipping ahead by powers of 10 when detecting repeated digit patterns (e.g., jumping by 10 instead of 1 when encountering 121212). While further edge-case handling is required, this approach may offer a reasonable balance between simplicity and performance.

**Optimizations:**
- BCD input format allows easy digit extraction without division and modulo
- 14-stage pipeline with tree adders for BCD-to-binary conversion
- Arithmetic series formula avoids iterating through every number
- Pipelined multipliers for the final reconstruction step
- Special handling for odd-length ranges (they get rounded up to even length)

**Performance:**
- **Worst Negative Slack**: 0.014 ns
- **Target Frequency**: 333 MHz 
- **Number of Cycles**: 120 cycles
- **Target Execution Time**: 0.36 µs

### Day 3: [Lobby](https://adventofcode.com/2025/day/3)

**Part 1**: Conceptually simple problem: for each line of digits, pick two digits (in order) that form the largest possible 2-digit number, then sum across all lines. But mapping this cleanly to hardware ended up being more interesting than expected.

My first instinct was to buffer the whole line and do some kind of selection logic, but that felt wasteful. Instead, I treated each bank as a stream of digits and tried to maintain the best 2-digit combination on the fly.

The core idea is that at any point, I only need to remember the current best pair and compare it against combinations involving the next digit. So the whole design becomes a streaming max-pair problem instead of a sorting problem.

I built a deep pipeline where each stage consumes one digit (4 bits) and conditionally updates the best pair seen so far. Each stage compares the incoming digit against the existing pair and decides whether replacing one or both digits would yield a larger 2-digit number.

By the time the pipeline finishes scanning a line, it has already converged to the maximum valid pair.

One tricky part was merging partial results. When combining two candidate pairs (a, b) and (c, d), you can’t just compare ab and cd. You have to consider all ordered combinations:
ab, ac, ad, bc, bd, cd.

I implemented this as a small combinational comparison tree that picks the maximum legal pair while preserving order. It looks ugly on paper, but synthesizes nicely I guess.

After that, converting the final digit pair into a decimal number is trivial:
10a + b, implemented as ` (a << 3) + (a << 1) + b ` to avoid multipliers.

Finally, each bank’s result is accumulated into a running sum. A counter tracks how many banks have completed, and once the last one exits the pipeline, the finished flag is asserted.

**Optimizations:**
- BCD input format allows easy digit extraction without division
- One digit consumed per pipeline stage
- Comparison tree instead of nested conditionals
- Shift-add decimal conversion instead of multiplication
- One bank processed per cycle after pipeline fill
- Fixed latency regardless of digit values

**Performance:**
- **Worst Negative Slack**: 0.010 ns
- **Target Frequency**: ~714 MHz 
- **Number of Cycles**: 2,614 cycles
- **Target Execution Time**: 3.66 µs

**Part 2**:  This is not much harder version of Part 1 but hard to optimize (one reason is I want to use 32-bit data in so the number of cycle each state is different). Instead of picking 2 digits to form the largest 2-digit number, I now need to pick 12 digits from each bank to form the largest 12-digit number.
The challenge is figuring out which 12 digits to keep. The key insight is that I want to build the number left-to-right, always trying to put the biggest possible digit in each position. But there's a constraint: I can only pick a digit if there are still enough digits left after it to complete our 12-digit number.
For example, if I're looking at a bank like 987654321111111 and I've already selected 10 digits, I need at least 2 more digits. So I can only consider digits that have at least 2 digits remaining after them (including themselves).
The algorithm works like this: scan through the digits one by one, and whenever I find a digit that's larger than what I currently have in a position AND there are enough digits remaining, I update our selection. If I replace an earlier position with a better digit, I throw away everything after it and start fresh from there.
My implementation uses a three-stage pipelined architecture:
Stage 1 (Input Buffering): Uses ping pong buffers that alternate roles. While one buffer receives incoming digits from the input stream (8 BCD digits per 32-bit word), the other buffer feeds digits to Stage 2 for processing. When Stage 1 finishes filling a buffer and Stage 2 finishes reading the previous buffer, they swap roles. This keeps the pipeline moving without stalls.

Stage 2 (Digit Selection): This is where the main logic lives. It maintains a 48-bit register that holds our current best 12-digit number (4 bits per digit). As each new digit arrives, the stage asks: "Can this digit improve my number?"
It checks all 12 positions from left to right:

Position 0: Is this digit bigger than my first digit? And are there at least 12 digits left (including this one)?
Position 1: If not position 0, is this digit bigger than my second digit? And are there at least 11 digits left?
...and so on through position 11.

When I find a position where the new digit is better AND I have enough digits remaining, I put the new digit there and clear everything to the right (since I're building a new number from this point forward).
For the example 987654321111111: I scan left to right, keep the 9, then keep the 8, then the 7, and so on. 

Stage 3 (BCD to Binary Conversion): The 12 selected digits are in BCD format (4 bits each), but I need a standard binary number for arithmetic. This stage converts by processing one digit at a time: multiply the current result by 10 and add the next digit. After 12 iterations, I have our binary number.
The multiplication by 10 is implemented as (value << 3) + (value << 1) which is equivalent to value × 8 + value × 2 = value × 10, avoiding hardware multipliers.

I scan left-to-right, so I naturally prioritize larger digits in higher-value positions
The "remaining digits" check ensures I can always complete a valid 12-digit number
Once I place a large digit early, I only consider digits that come after it (maintaining order)
The cascaded comparison structure efficiently finds the best position for each new digit

**Optimizations:**
- Double-buffering enables overlapped input/processing
- BCD input format simplifies digit extraction
- Shift-add multiplication avoids dedicated multiplier units

**Performance:**
- **Worst Negative Slack**: 0.000 ns
- **Target Frequency**: ~303 MHz 
- **Number of Cycles**: 21,430 cycles
- **Target Execution Time**: 70.719 µs


### Day 5: [Cafeteria](https://adventofcode.com/2025/day/5)

**Part 1**: My goal here was to maximize throughput while maintaining a clean pipeline structure. I used a 32-bit input interface with AXI-like handshaking (valid/ready signals). My solution is a bit tricky as I preloaded ranges into program :) but generally it is quite simple and straightforword.

Since each ingredient ID is 50 bits wide, the testbench streams each ID over 2 clock cycles (32 bits + 18 bits). The module continuously accepts input while simultaneously processing previously received IDs through the comparison pipeline.

The pipeline has 4 stages (not counting input reception):
- 1 stage to assemble the complete 50-bit ID
- 1 stage for parallel range comparisons (182 comparisons)
- 1 stage for AND operations to determine range membership
- 1 stage for result accumulation

**Optimizations:**
- Parallel comparison across all 182 ranges using generate blocks
- Single-cycle OR reduction to check any-range membership

**Performance:**
- **Worst Negative Slack**: 0.065 ns
- **Target Frequency**: ~455 MHz 
- **Number of Cycles**: 2,006 cycles
- **Target Execution Time**: 4.41 µs

### Day 6: [Trash Compactor](https://adventofcode.com/2025/day/6)
**Part 1**: This problem is optimally solved using BCD encoding. The testbench drives inputs as BCD, with each problem containing 4 rows of values plus an operation sign. I transfer each problem over 2 cycles, with each cycle carrying two 16-bit BCD values (supporting up to 4 digits per value). A separate op input signal indicates the operation (multiply or add).A key insight: the input contains no zero digits at all, which greatly simplifies the bcd_to_binary conversion function. I can determine the actual value by checking which digit positions are non-zero, eliminating the need for complex zero-handling logic. For multiplication, rather than using an expensive 32×32 combinational multiplier, I implemented a Karatsuba-like algorithm across multiple pipeline stages. This decomposes the 32×32 multiplication into four 16×16 multiplications, significantly reducing the critical path.

Input Stage: Buffers two 32-bit words into a 64-bit register containing four 16-bit BCD values
Stage 1: BCD to binary conversion for all four numbers in parallel
Stage 2: First level operations - multiply or add pairs (line1×line2, line3×line4)
Stage 3: For multiplication, split 32-bit results into high/low 16-bit parts for Karatsuba decomposition
Stage 4: Compute partial products (HH, HL, LH, LL) or pass through addition result
Stage 5: Shift partial products to correct bit positions (HH<<32, HL<<16, LH<<16, LL)
Stage 6: Sum all partial products to get final 64-bit result
Accumulator: Maintains running sum across all 1000 problems

**Optimizations:**
- BCD to binary conversion handles 1-4 digit numbers efficiently in a single function
- Karatsuba-like multiplication algorithm breaks 32×32 multiplication into four 16×16 operations
- Separate fast path for addition bypasses multiplication stages
- Bit shifts replace multiplication for positioning partial products

**Performance:**
- **Worst Negative Slack**: 0.026 ns
- **Target Frequency**: ~295 MHz 
- **Number of Cycles**: 2,010 cycles
- **Target Execution Time**: 6.83 µs

**Part 2**: With my implimentation, part 2 is like 80% similar to part 1. The differences are just truncating the input buffer and handling some additional zero edge cases. 

Input Stage: Buffers two 32-bit words into a 64-bit register containing four 16-bit BCD values
Stage 1: BCD-to-binary conversion reading digits column-wise-extracts nibbles at positions [3:0], [19:16], [35:32], [51:48] for the first number, [7:4], [23:20], [39:36], [55:52] for the second, etc., to form numbers from right-to-left columns
Stage 2: First-level operations with zero-handling for multiplication (if one operand is 0, return the other; if both are 0, return 1 as identity) or add pairs for addition
Stage 3: For multiplication, split 32-bit results into high/low 16-bit parts for Karatsuba decomposition; for addition, sum the pairs
Stage 4: Compute Karatsuba partial products (HH, HL, LH, LL) or pass through addition result
Stage 5: Shift partial products to correct bit positions (HH<<32, HL<<16, LH<<16)
Stage 6: Sum all partial products to produce final 64-bit result
Accumulator: Maintains running sum across all 1000 problems

**Performance:**
- **Worst Negative Slack**: 0.025 ns
- **Target Frequency**: ~285 MHz 
- **Number of Cycles**: 2,010 cycles
- **Target Execution Time**: 7.04 µs

### Day 7: [Laboratories](https://adventofcode.com/2025/day/7)
**Part 1**: The manifold is 141×142, so each row requires 141 bits, streamed in as five 32-bit chunks over 5 clock cycles. The core challenge is tracking which positions have active beams and detecting splits. I maintain a current_beams vector where each bit represents a beam at that position. When a beam hits a splitter (^), it stops and creates two new beams to the left and right.
The pipeline has 8 stages:

Stage 1: Buffer the incoming row data
Stage 2: Detect splits (beams hitting ^) and compute next beam positions
Stages 3-8: Tree reduction to sum all splits in the row (141 bits → 70 → 36 → 18 → 9 → 3 → 1)

The beam propagation logic handles three cases per position:
`
next_beams[i] = (current_beams[i-1] && splits[i-1]) || (current_beams[i+1] && splits[i+1]) || (current_beams[i] && !splits[i])
`
**Optimizations:**
- Tree adders for parallel summation across 141 positions
- Single-cycle beam/timeline propagation using combinational logic

**Performance:**
- **Worst Negative Slack**: 0.061 ns
- **Target Frequency**: 725 MHz 
- **Number of Cycles**: 721 cycles
- **Target Execution Time**: 0.99µs

**Part 2**: Instead of tracking single beams, I track the number of quantum timelines at each position. When a particle reaches a splitter, it takes both paths simultaneously, doubling the timeline count. The problem with this part is that the number will become very large so t hat the critical path is abit bigger than I expected. Although there are available ideas to optimize the critical path (but deeper pipelines of course), I did not do it because it not really a matter here and will make the program a bit cumbersome to read and the result now is quite good tho.

The key difference from Part 1:
`
next_paths[i] = (splits[i-1] ? current_paths[i-1] : 0) + (splits[i+1] ? current_paths[i+1] : 0) + (!splits[i] ? current_paths[i] : 0)
`
**Optimizations:**
- Tree adders for parallel summation across 141 positions
- Single-cycle beam/timeline propagation using combinational logic

**Performance:**
- **Worst Negative Slack**: 0.027 ns
- **Target Frequency**: 400 MHz 
- **Number of Cycles**: 721 cycles
- **Target Execution Time**: 1.80 µs

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
- **Worst Negative Slack**: 0.003 ns
- **Target Frequency**: 680 MHz 
- **Number of Cycles**: 2,009 cycles
- **Target Execution Time**: 2.96 µs

### File Structure (per day)
```
day_X/
├── input.txt                   # Raw problem input
├── *_part1.v                   # Part 1 Verilog implementation
├── *_part2.v                   # Part 2 Verilog implementation
├── test_day_X.py               # Cocotb test file (supporting print result)
└── Makefile                    # Build configuration
```

