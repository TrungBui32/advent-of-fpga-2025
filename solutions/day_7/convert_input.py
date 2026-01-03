def convert_input():
    with open('input.txt', 'r') as f_in:
        lines = f_in.readlines()
        
    with open('input.mem', 'w') as f_out:
        for i, line in enumerate(lines):
            if i == 0:
                continue
            line = line.strip()
            converted = line.replace('.', '0').replace('^', '1')
            f_out.write(converted + '\n')

if __name__ == '__main__':
    convert_input()