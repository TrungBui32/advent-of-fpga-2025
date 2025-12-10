with open('input.txt', 'r') as f:
    lines = f.readlines()

with open('x.mem', 'w') as x_file, open('y.mem', 'w') as y_file:
    for line in lines:
        line = line.strip()
        if line:  
            x, y = line.split(',')
            x_file.write(format(int(x), '032b') + '\n')
            y_file.write(format(int(y), '032b') + '\n')

print("Conversion complete! Created x.mem and y.mem with binary format")