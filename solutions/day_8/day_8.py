def solve_part2():
    with open('input.txt', 'r') as f:
        lines = f.read().strip().split('\n')
    
    boxes = []
    for line in lines:
        if not line.strip(): continue
        x, y, z = map(int, line.split(','))
        boxes.append((x, y, z))
        
    n = len(boxes)
    edges = []
    
    for i in range(n):
        for j in range(i + 1, n):
            x1, y1, z1 = boxes[i]
            x2, y2, z2 = boxes[j]
            dist_sq = (x1 - x2) ** 2 + (y1 - y2) ** 2 + (z1 - z2) ** 2
            edges.append((dist_sq, i, j))
            
    MAX_VALUE = 18446744073709551615 
    PADDING_COUNT = 500
    
    print(f"Injecting {PADDING_COUNT} dummy edges with value {MAX_VALUE}...")
    for _ in range(PADDING_COUNT):
        edges.append((MAX_VALUE, 0, 0))
    CHUNK_SIZE = 20000
    print(f"Sorting edges in chunks of {CHUNK_SIZE} elements...")
    
    for k in range(0, len(edges), CHUNK_SIZE):
        end_k = min(k + CHUNK_SIZE, len(edges))
        
        chunk = edges[k:end_k]
        
        chunk.sort()
        
        edges[k:end_k] = chunk
    print(f"Exporting {len(edges)} chunk-sorted distances to result_py.txt...")
    with open('result_py.txt', 'w') as res_file:
        for dist, i, j in edges:
            res_file.write(f"{dist}\n")

    parent = list(range(n))
    rank = [0] * n
    
    def find(x):
        if parent[x] != x:
            parent[x] = find(parent[x]) 
        return parent[x]
    
    def union(x, y):
        px, py = find(x), find(y)
        if px == py:
            return False 
        if rank[px] < rank[py]:
            parent[px] = py
        elif rank[px] > rank[py]:
            parent[py] = px
        else:
            parent[py] = px
            rank[px] += 1
        return True
    
    edges_added = 0
    last_edge = None

    for dist, i, j in edges:
        if dist == MAX_VALUE and i == 0 and j == 0:
            continue

        if union(i, j):
            edges_added += 1
            last_edge = (i, j)
            if edges_added == n - 1:
                break
    
    if last_edge:
        i, j = last_edge
        x1 = boxes[i][0]
        x2 = boxes[j][0]
        print(f"Last MST Edge: Box {i} and {j}. Result: {x1 * x2}")
        return x1 * x2
    return 0

if __name__ == "__main__":
    solve_part2()
