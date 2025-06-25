import os
import re
from collections import defaultdict

LIB_DIR = os.path.join(os.path.dirname(__file__), 'lib')
OUTPUT_FILE = os.path.join(os.path.dirname(__file__), 'table_classes.txt')

def find_table_classes(lib_dir):
    # Use defaultdict to group file paths by class name
    class_files = defaultdict(list)
    class_pattern = re.compile(r'class\s+(\w*Table\w*)\b')

    for root, _, files in os.walk(lib_dir):
        for file in files:
            if file.endswith('.dart'):
                file_path = os.path.join(root, file)
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                    matches = class_pattern.findall(content)
                    for match in matches:
                        class_files[match].append(file_path)
    return class_files

def main():
    class_files = find_table_classes(LIB_DIR)
    if not class_files:
        print("No classes containing 'Table' found in lib directory.")
        return

    # Write results to output file
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as out_file:
        out_file.write(f"Found {len(class_files)} unique 'Table' classes in lib directory:\n")
        for idx, (class_name, file_paths) in enumerate(sorted(class_files.items()), 1):
            out_file.write(f"{idx}. {class_name} (found in {len(file_paths)} file(s)):\n")
            for file_path in file_paths:
                out_file.write(f"   - {os.path.relpath(file_path, LIB_DIR)}\n")
    print(f"Table class list written to {OUTPUT_FILE}")

    print(f"Found {len(class_files)} unique 'Table' classes in lib directory:")
    for idx, (class_name, file_paths) in enumerate(sorted(class_files.items()), 1):
        print(f"{idx}. {class_name} (found in {len(file_paths)} file(s)):")
        for file_path in file_paths:
            print(f"   - {os.path.relpath(file_path, LIB_DIR)}")

if __name__ == "__main__":
    main()