graph = {
    "A": ["B", "C", "D"],
    "B": ["A", "E", "F"],
    "C": ["A", "F"],
    "D": ["A"],
    "E": ["B"],
    "F": ["B", "C"],
}


def main():
    stack = ["A"]
    visited = []

    while len(stack) > 0:
        node = stack.pop()
        if node not in visited:
            visited.append(node)
            print(f"{node}\t{str(visited):30}\t{stack}")
            for neighbor in reversed(graph[node]):
                if neighbor not in visited:
                    stack.append(neighbor)
            print(f"{node}\t{str(visited):30}\t{stack}")


if __name__ == "__main__":
    main()
