def convert_input():
    with open('input.txt', 'r') as f_in:
        lines = f_in.readlines()

    with open('x.mem', 'w') as f_x, \
         open('y.mem', 'w') as f_y, \
         open('z.mem', 'w') as f_z:

        for line in lines:
            line = line.strip()
            if not line:
                continue

            parts = line.split(',')

            num_x = int(parts[0])
            num_y = int(parts[1])
            num_z = int(parts[2])

            bin_x = bin(num_x)[2:].zfill(17)
            bin_y = bin(num_y)[2:].zfill(17)
            bin_z = bin(num_z)[2:].zfill(17)

            f_x.write(bin_x + '\n')
            f_y.write(bin_y + '\n')
            f_z.write(bin_z + '\n')

if __name__ == '__main__':
    convert_input()