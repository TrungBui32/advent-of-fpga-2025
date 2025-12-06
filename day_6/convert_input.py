def convert_input():
    with open('input.txt', 'r') as f:
        lines = f.readlines()
    
    # Process first 4 lines (numerical data)
    for i in range(4):
        numbers = lines[i].strip().split()
        with open(f'line{i+1}.mem', 'w') as f:
            for num in numbers:
                # Convert to hex format (4 digits) for Verilog $readmemh
                f.write(f"{int(num):04X}\n")
        print(f"Created line{i+1}.mem with {len(numbers)} elements")
    
    # Process line 5 (operators: + and *)
    operators = lines[4].strip()
    with open('op.mem', 'w') as f:
        for char in operators:
            if char == '+':
                f.write("1\n")
            elif char == '*':
                f.write("0\n")
            # Skip spaces and other characters
    
    # Count actual operators (not spaces)
    op_count = sum(1 for char in operators if char in ['+', '*'])
    print(f"Created op.mem with {op_count} elements")
    print("Conversion complete!")

if __name__ == "__main__":
    convert_input()