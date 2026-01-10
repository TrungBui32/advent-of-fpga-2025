def convert_ranges(filename_in):
    with open(filename_in, 'r') as f_in:
        data = f_in.read().strip()
        ranges = data.split(',')
        
        with open("table_1.mem", 'w') as f1, open("table_2.mem", 'w') as f2:
            for range_str in ranges:
                start, end = range_str.split('-')
                f1.write(f"{start}\n")
                f2.write(f"{end}\n")

convert_ranges("input.txt")