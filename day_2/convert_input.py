def convert_ranges(filename_in):
    with open(filename_in, 'r') as f_in:
        data = f_in.read().strip()
        ranges = data.split(',')
        
        with open("table_1.mem", 'w') as f1, open("table_2.mem", 'w') as f2:
            for range_str in ranges:
                start, end = range_str.split('-')
                start_bin = format(int(start), '064b')
                end_bin = format(int(end), '064b')
                f1.write(f"{start_bin}\n")
                f2.write(f"{end_bin}\n")

convert_ranges("input.txt")