# AWS Region Validator and Public IP Collector

This repository contains two Bash scripts designed to work with AWS services to validate regions and collect public IP addresses from various AWS resources.


## Scripts Overview

1. **check-region.sh**: This script validates AWS regions specified in a file (`regions.txt`). It checks the provided regions against the available AWS regions and outputs the valid regions.

2. **all-public-ips.sh**: This script builds upon `check-region.sh` and collects unique public IP addresses from various AWS resources across the specified regions. The collected IPs are stored in `public-ips.txt`.


## Prerequisites

- AWS CLI installed and configured with appropriate permissions.
- Bash shell environment.
- A file named `regions.txt` in the same directory as the scripts, containing the AWS regions to be checked (one region per line or "all" to include all available regions).


## Usage

### check-region.sh

1. **Purpose**: Validate AWS regions specified in `regions.txt`.

2. **Run the Script**:
    ```bash
    ./check-region.sh
    ```
3. **Output**: Displays valid regions or an error message if invalid regions are found.

### all-public-ips.sh

1. **Purpose**: Collect unique public IP addresses from various AWS resources in the specified regions.

2. **Run the Script**:
    ```bash
    ./all-public-ips.sh
    ```
3. **Output**: 
    - Displays the regions being checked.
    - Saves unique public IP addresses to `public-ips.txt`.


## File Descriptions

- **regions.txt**: A text file containing the list of AWS regions to be validated and checked.
- **public-ips.txt**: A text file where unique public IP addresses are saved.


## Example `regions.txt` File

us-east-1<br>
us-west-2<br>
eu-central-1

Note: The actual `regions.txt` file contains only `us-east-1`. The additional regions shown here are for illustrative purposes.


## Notes

- Ensure that the AWS CLI is properly configured with access to the required AWS resources.
- The script `all-public-ips.sh` performs DNS lookups for load balancers, which might require appropriate network permissions.


## Acknowledgements

- AWS CLI documentation and tools.