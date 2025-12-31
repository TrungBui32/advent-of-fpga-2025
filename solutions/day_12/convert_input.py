def convert_input():
    with open('input.txt', 'r') as f:
        lines = [line.strip() for line in f.readlines()]
    
    presents_data = []
    shape_idx = 0
    i = 0
    
    while shape_idx < 6 and i < len(lines):
        if lines[i] == f"{shape_idx}:":
            shape_lines = []
            for j in range(1, 4):  
                if i + j < len(lines) and lines[i + j] != "":
                    shape_line = lines[i + j]
                    binary_line = shape_line.replace('#', '1').replace('.', '0')
                    shape_lines.append(binary_line)
            
            flattened = ''.join(shape_lines)
            presents_data.append(flattened)
            shape_idx += 1
            i += 4 
            i += 1
    
    with open('presents.mem', 'w') as f:
        for present in presents_data:
            f.write(present + '\n')
    
    sizes_data = []
    quantities_data = []
    
    start_idx = 0
    for i, line in enumerate(lines):
        if 'x' in line and ':' in line:  
            start_idx = i
            break
    
    for i in range(start_idx, len(lines)):
        line = lines[i].strip()
        if line and 'x' in line and ':' in line:
            size_part, quantity_part = line.split(':', 1)
            width, height = map(int, size_part.split('x'))
            
            width_bin = format(width, '08b')
            height_bin = format(height, '08b')
            sizes_data.append(width_bin + height_bin)
            
            quantities = list(map(int, quantity_part.strip().split()))
            if len(quantities) == 6:
                quantity_line = ''.join(format(q, '08b') for q in quantities)
                quantities_data.append(quantity_line)
    
    with open('sizes.mem', 'w') as f:
        for size in sizes_data:
            f.write(size + '\n')
    
    with open('quantities.mem', 'w') as f:
        for quantity in quantities_data:
            f.write(quantity + '\n')
    
    print(f"Generated:")
    print(f"- presents.mem: {len(presents_data)} presents")
    print(f"- sizes.mem: {len(sizes_data)} size entries")
    print(f"- quantities.mem: {len(quantities_data)} quantity entries")

if __name__ == "__main__":
    convert_input()