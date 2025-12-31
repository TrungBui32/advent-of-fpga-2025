def convert_to_binary(input_file, source_file, destination_file, count_file):
    with open(input_file, 'r') as infile:
        lines = infile.readlines()

    source_binary = []
    destination_binary = []
    destination_counts = []

    for line in lines:
        if ':' in line:
            source, destination = line.strip().split(':')
            source = source.strip().ljust(3)[:3]
            destination = destination.replace(' ', '')
            source_bin = ''.join(format(ord(char), '08b') for char in source)
            destination_bin = ''.join(format(ord(char), '08b') for char in destination)
            source_binary.append(source_bin) 
            destination_binary.append(destination_bin)

            destination_count = len(destination) // 3
            destination_counts.append(format(destination_count, '05b'))

    max_destination_length = max(len(line) for line in destination_binary)

    destination_binary = [line.rjust(max_destination_length, '0') for line in destination_binary]

    with open(source_file, 'w') as src_file:
        src_file.write('\n'.join(source_binary) + '\n')

    with open(destination_file, 'w') as dest_file:
        dest_file.write('\n'.join(destination_binary) + '\n')

    with open(count_file, 'w') as count_file:
        count_file.write('\n'.join(destination_counts) + '\n')


input_file = 'input.txt'
source_file = 'source.mem'
destination_file = 'destination.mem'
count_file = 'count.mem'

convert_to_binary(input_file, source_file, destination_file, count_file)
