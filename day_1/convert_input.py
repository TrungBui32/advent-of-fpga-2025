def convert_to_hex(filename_in, filename_out):
    with open(filename_in, 'r') as f_in, open(filename_out, 'w') as f_out:
        for line in f_in:
            line = line.strip()
            if line:
                direction = line[0]
                value = int(line[1:])
                if direction == 'R':
                    hex_value = 0x400 | value  
                else:  
                    hex_value = value 
                
                f_out.write(f"{hex_value:03X}\n")

convert_to_hex("input.txt", "input.mem")
