import re
import os
import subprocess

# Run the terraform output command and save the output to the file
subprocess.run('echo "$(terraform output kube_config)" > /mnt/c/Users/BMA8BP/terraform/azurek8s', shell=True)
print('Terraform Output saved to /mnt/c/Users/BMA8BP/terraform/azurek8s')

# Path to the file
file_path = '/mnt/c/Users/BMA8BP/terraform/azurek8s'

# Directory to save the kubeconfig files
output_dir = '/mnt/c/Users/BMA8BP/terraform/kubeconfigs'
os.makedirs(output_dir, exist_ok=True)

# Path to the merged kubeconfig file
merged_kubeconfig_path = os.path.join(output_dir, 'merged_kubeconfig.yaml')

# Read the content of the file
with open(file_path, 'r') as file:
    text = file.read()

# Extract the regions from the default array
default_line = 'default     = ["spaincentral", "westeurope", "centralindia"]'
regions = re.findall(r'"(.*?)"', default_line)

# Function to extract the value for a given region
def extract_region_value(text, region):
    pattern = fr'"{region}"\s*=\s*<<-EOT\s*(.*?)\s*EOT'
    match = re.search(pattern, text, re.DOTALL)
    if match:
        return match.group(1).strip()  # Strip leading/trailing whitespace
    else:
        return None

# Function to fix indentation
def fix_indentation(yaml_content):
    lines = yaml_content.split('\n')
    fixed_lines = [lines[0]]  # Keep the first line as is
    for line in lines[1:]:
        fixed_lines.append(line[2:] if line.startswith('  ') else line)
    return '\n'.join(fixed_lines)

# Initialize a list to hold the paths of the kubeconfig files
kubeconfig_paths = []

# Extract and save the kubeconfig content for each region
for region in regions:
    value = extract_region_value(text, region)
    if value:
        # Fix the indentation
        fixed_value = fix_indentation(value)
        
        # Save the extracted content to a file
        region_kubeconfig_path = os.path.join(output_dir, f'{region}_kubeconfig.yaml')
        with open(region_kubeconfig_path, 'w') as region_file:
            region_file.write(fixed_value)
        
        print(f'Kubeconfig for {region} written to {region_kubeconfig_path}')
        
        # Add the path to the kubeconfig_paths list
        kubeconfig_paths.append(region_kubeconfig_path)
    else:
        print(f'No match found for {region}')