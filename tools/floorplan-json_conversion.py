import re
import json
import sys

# Patterns to match pblock sections in the .xdc file
pblock_pattern = r"create_pblock\s+(\S+)"
resize_pattern = r"resize_pblock\s+\[get_pblocks\s+(\S+)\]\s+-add\s+\{(\S+):(\S+)\}"

# A function to categorize resource type based on the start of the string
def get_resource_type(resource):
    if resource.startswith("SLICE"):
        return "SLICE"
    elif resource.startswith("DSP"):
        return "DSP"
    elif resource.startswith("RAMB18"):
        return "RAMB18"
    elif resource.startswith("RAMB36"):
        return "RAMB36"
    elif resource.startswith("LAGUNA"):
        return "LAGUNA"
    return "UNKNOWN"

# Parse the .xdc file
def parse_xdc(file_path):
    pblocks = {}
    current_pblock = None

    with open(file_path, 'r') as f:
        for line in f:
            # Check for create_pblock line
            pblock_match = re.search(pblock_pattern, line)
            if pblock_match:
                current_pblock = pblock_match.group(1)
                pblocks[current_pblock] = {}

            # Check for resize_pblock lines
            resize_match = re.search(resize_pattern, line)
            if resize_match and current_pblock:
                resource_type = get_resource_type(resize_match.group(2))
                if resource_type not in pblocks[current_pblock]:
                    pblocks[current_pblock][resource_type] = {}
                pblocks[current_pblock][resource_type]['start'] = resize_match.group(2)
                pblocks[current_pblock][resource_type]['end'] = resize_match.group(3)

    return pblocks

# Convert the parsed data to JSON format
def convert_to_json(pblocks, output_file):
    with open(output_file, 'w') as f:
        json.dump(pblocks, f, indent=4)

# Example usage
xdc_file = sys.argv[1]
output_json = sys.argv[2]

pblocks_data = parse_xdc(xdc_file)
convert_to_json(pblocks_data, output_json)

print(f'Conversion complete! JSON saved to {output_json}')
