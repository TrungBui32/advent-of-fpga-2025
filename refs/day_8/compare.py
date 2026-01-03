import sys
import itertools

def compare_log_range():
    PY_FILE = 'result_py.txt'       
    SIM_LOG_FILE = 'simulation.log' 
    
    START_LINE = 16  
    END_LINE = 500015    

    print(f"Comparing {PY_FILE} against {SIM_LOG_FILE}")
    print(f"Targeting Simulation Log Lines: {START_LINE} to {END_LINE}")
    print("-" * 40)

    try:
        with open(PY_FILE, 'r') as f_py:
            py_lines = [line.strip() for line in f_py if line.strip()]

        with open(SIM_LOG_FILE, 'r') as f_sim:
            all_sim_lines = f_sim.readlines()

        if START_LINE < 1 or END_LINE > len(all_sim_lines):
            print(f"Error: Line range {START_LINE}-{END_LINE} is out of bounds.")
            print(f"Simulation log has {len(all_sim_lines)} lines.")
            return

        sim_subset = all_sim_lines[START_LINE-1 : END_LINE]
        
        sim_lines_cleaned = [line.strip() for line in sim_subset]

    except FileNotFoundError as e:
        print(f"Error: Could not open file - {e}")
        return

    mismatches = 0
    checked_count = 0

    for idx, (gold, sim) in enumerate(itertools.zip_longest(py_lines, sim_lines_cleaned)):
        checked_count += 1
        
        sim_line_num = START_LINE + idx

        if gold is None:
            print(f"[LENGTH ERROR] Sim Log has extra data at line {sim_line_num}: '{sim}'")
            mismatches += 1
            continue
        if sim is None:
            print(f"[LENGTH ERROR] Sim Log ran out of data. Expected Python value: '{gold}'")
            mismatches += 1
            continue

        try:
            val_gold = int(gold)
            val_sim = int(sim) 
            
            if val_gold != val_sim:
                print(f"[MISMATCH] Sim Line {sim_line_num}: Expected {val_gold}, got {val_sim}")
                mismatches += 1
        except ValueError:
            print(f"[PARSE ERROR] Sim Line {sim_line_num}: Non-integer data found.")
            print(f"              Expected: '{gold}'")
            print(f"              Got:      '{sim}'")
            mismatches += 1

    print("-" * 40)
    print(f"Comparison Complete.")
    print(f"Lines Checked: {checked_count}")
    
    if mismatches == 0:
        print("SUCCESS: Data matches perfectly.")
    else:
        print(f"FAILURE: Found {mismatches} mismatches.")

if __name__ == "__main__":
    compare_log_range()
