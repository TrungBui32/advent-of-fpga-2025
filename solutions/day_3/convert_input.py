def convert_dec_to_bin(filename_in):
    with open(filename_in, 'r') as f_in:
        lines = f_in.readlines()
        
        with open("input.mem", 'w') as f_out:
            for line in lines:
                line = line.strip()
                if line:
                    dec_value = int(line)
                    bin_value = format(dec_value, '0333b')
                    f_out.write(f"{bin_value}\n")

convert_dec_to_bin("input.txt")