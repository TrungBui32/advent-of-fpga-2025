import array


def solve_part2(lines):
    total = 0
    for line in lines:
        num = int(line.strip())
        
        arr = [0] * 12
        number = 0
        
        for i in range(12):
            arr[i] = num % 10
            num //= 10
        
        while num > 0:
            digit = num % 10
            
            for j in range(12):
                if digit >= arr[11 - j]:
                    tmp = arr[11 - j]
                    arr[11 - j] = digit
                    digit = tmp
                else: 
                    break

            num //= 10
        
        for i in range(12):
            number = number * 10 + arr[11 - i]

        total += number
    return total

def solve_part1(lines):
    total = 0
    for line in lines:
        number = 0
        num = int(line.strip())
        second = num % 10
        num //= 10
        first = num % 10
        num //= 10
        while(num > 0):
            digit = num % 10
            if digit >= first:
                if second < first:
                    second = first
                first = digit
            num //= 10
        for i in range(12):
            number = first * 10 + second
        total += number
    return total

with open('input.txt', 'r') as f:
    lines = f.readlines()

part1_answer = solve_part1(lines)
part2_answer = solve_part2(lines)

print(f"Part 1: {part1_answer}")
print(f"Part 2: {part2_answer}")
