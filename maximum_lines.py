import os

maximum = 0
maximum_file = None

for root, dir, files in os.walk('./lib'):
    for file in files:
        if file.endswith('.dart'):
            # Perform some operation with the file
            # For example, print the file name and its directory
            content = open(os.path.join(root, file))
            lines = content.readlines()
            if maximum < (count := len(lines)):
                maximum = count
                maximum_file = os.path.join(root, file)
            content.close()

print(f'Maximum number of lines in a Dart file: {maximum}')
print(f'File with maximum lines: {maximum_file}')