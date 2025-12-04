with open('input.txt', 'r') as f_in:
    with open('input.mem', 'w') as f_out:
        for line in f_in:
            line = line.strip()
            converted = line.replace('@', '1').replace('.', '0')
            f_out.write(converted + '\n')