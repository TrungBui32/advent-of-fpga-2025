import re

def parse_and_convert(input_filename):
    MAX_LIGHTS = 32 
    BIT_WIDTH = 32
    
    parsed_machines = []
    
    try:
        with open(input_filename, 'r') as f:
            lines = f.readlines()
    except FileNotFoundError:
        print(f"Error: {input_filename} not found.")
        return

    re_lights = re.compile(r'\[([.#]+)\]') 
    re_buttons = re.compile(r'\(([\d,]+)\)') 
    re_joltage = re.compile(r'\{([0-9,]+)\}')

    for line in lines:
        if not line.strip():
            continue
            
        light_match = re_lights.search(line)
        if not light_match:
            continue
            
        light_str = light_match.group(1)
        num_lights = len(light_str)
        
        target_val = 0
        for i, char in enumerate(light_str):
            if char == '#':
                target_val |= (1 << i)
        
        button_matches = re_buttons.findall(line)
        current_machine_buttons = []
        for btn_str in button_matches:
            indices = [int(x) for x in btn_str.split(',')]
            btn_mask = 0
            for idx in indices:
                btn_mask |= (1 << idx)
            current_machine_buttons.append(btn_mask)
            
        num_buttons = len(current_machine_buttons)

        joltage_match = re_joltage.search(line)
        joltage_values = []
        if joltage_match:
            joltage_str = joltage_match.group(1)
            joltage_values = [int(x) for x in joltage_str.split(',')]

        parsed_machines.append({
            'target': target_val,
            'buttons': current_machine_buttons,
            'joltage': joltage_values,
            'num_lights': num_lights,
            'num_buttons': num_buttons,
            'num_joltage': len(joltage_values)
        })

    MAX_BUTTONS = max(machine['num_buttons'] for machine in parsed_machines) if parsed_machines else 0
    MAX_JOLTAGE = max(machine['num_joltage'] for machine in parsed_machines) if parsed_machines else 0
    
    print(f"Total machines: {len(parsed_machines)}")
    print(f"Max buttons: {MAX_BUTTONS}, Max joltage: {MAX_JOLTAGE}")

    def to_bin(val):
        return f"{val:0{BIT_WIDTH}b}"

    with open('light.mem', 'w') as f_light, \
         open('buttons.mem', 'w') as f_btn, \
         open('config.mem', 'w') as f_conf, \
         open('joltage.mem', 'w') as f_jolt:
        
        for machine in parsed_machines:
            f_light.write(f"{to_bin(machine['target'])}\n")
            
            config_val = (machine['num_buttons'] << 16) | machine['num_lights']
            f_conf.write(f"{to_bin(config_val)}\n")
            
            for btn in machine['buttons']:
                f_btn.write(f"{to_bin(btn)}\n")
            
            padding_btn = MAX_BUTTONS - machine['num_buttons']
            for _ in range(padding_btn):
                f_btn.write(f"{to_bin(0)}\n")

            for i in range(MAX_JOLTAGE):
                if i < len(machine['joltage']):
                    f_jolt.write(f"{to_bin(machine['joltage'][i])}\n")
                else:
                    f_jolt.write(f"{to_bin(0)}\n")

    print("Files generated: light.mem, buttons.mem, config.mem, joltage.mem")

if __name__ == "__main__":
    parse_and_convert("input.txt")