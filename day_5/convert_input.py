def convert_input():
    with open('input.txt', 'r') as f:
        content = f.read()
    
    # Split by blank line
    parts = content.strip().split('\n\n')
    ranges_section = parts[0]
    values_section = parts[1]
    
    # Parse ranges (before and after -)
    start_values = []
    end_values = []
    for line in ranges_section.strip().split('\n'):
        start, end = line.split('-')
        start_values.append(int(start))
        end_values.append(int(end))
    
    # Parse input values
    input_values = [int(x) for x in values_section.strip().split('\n')]
    
    # Write start_range.mem (50-digit binary)
    with open('start_range.mem', 'w') as f:
        for val in start_values:
            f.write(f'{val:050b}\n')
    
    # Write end_range.mem (50-digit binary)
    with open('end_range.mem', 'w') as f:
        for val in end_values:
            f.write(f'{val:050b}\n')
    
    # Write input.mem (50-digit binary)
    with open('input.mem', 'w') as f:
        for val in input_values:
            f.write(f'{val:050b}\n')
    
    print(f"Created start_range.mem with {len(start_values)} entries")
    print(f"Created end_range.mem with {len(end_values)} entries")
    print(f"Created input.mem with {len(input_values)} entries")

if __name__ == '__main__':
    convert_input()