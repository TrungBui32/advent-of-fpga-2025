def convert_input():
    with open('input.txt', 'r') as f:
        lines = f.readlines()
    
    param_lines = []
    for i in range(4):
        param_lines.append(lines[i].rstrip('\n'))
    
    operator_line = lines[4].rstrip('\n')
    
    max_length = max(len(line) for line in param_lines + [operator_line])
    
    for i in range(len(param_lines)):
        param_lines[i] = param_lines[i].ljust(max_length)
    operator_line = operator_line.ljust(max_length)
    
    col = 0
    problem_count = 0
    all_values = [[], [], [], []]
    operators = []
    current_problem = ['', '', '', '']
    in_problem = False
    
    while col < max_length and problem_count < 1000:
        has_digit = any(col < len(line) and line[col].isdigit() for line in param_lines)
        
        if has_digit:
            in_problem = True
            for i in range(4):
                if col < len(param_lines[i]) and param_lines[i][col].isdigit():
                    current_problem[i] += param_lines[i][col]
                else:
                    current_problem[i] += '0'
        else:
            if in_problem:
                for i in range(4):
                    value = int(current_problem[i]) if current_problem[i] else 0
                    all_values[i].append(value)
                
                problem_start = col - len(current_problem[0])
                for op_col in range(problem_start, col):
                    if op_col < len(operator_line) and operator_line[op_col] in ['*', '+']:
                        operators.append(operator_line[op_col])
                        break
                
                current_problem = ['', '', '', '']
                in_problem = False
                problem_count += 1
        
        col += 1
    
    if in_problem and any(current_problem):
        for i in range(4):
            value = int(current_problem[i]) if current_problem[i] else 0
            all_values[i].append(value)
        
        problem_start = col - len(current_problem[0])
        for op_col in range(problem_start, col):
            if op_col < len(operator_line) and operator_line[op_col] in ['*', '+']:
                operators.append(operator_line[op_col])
                break
        
        problem_count += 1
    
    for i in range(4):
        with open(f'line{i+1}.mem', 'w') as f:
            for value in all_values[i]:
                hex_value = hex(value)[2:]  
                f.write(f"{hex_value}\n")
        print(f"Created line{i+1}.mem with {len(all_values[i])} elements")
    
    with open('op.mem', 'w') as f:
        for op in operators:
            if op == '+':
                f.write("1\n")
            elif op == '*':
                f.write("0\n")
    
    print(f"Created op.mem with {len(operators)} elements")
    print("Conversion complete!")

if __name__ == "__main__":
    convert_input()
