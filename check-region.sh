#!/bin/bash

# File where regions are specified
regions_file="regions.txt"

# Get all available AWS regions as a space-separated string to simplify matching
available_regions=$(aws ec2 describe-regions --query 'Regions[*].RegionName' --output text | xargs)

# Function to validate and set regions
process_regions() {
    local region_input=$1
    local valid_regions=()
    local invalid_regions=()

    if [[ "$region_input" =~ ^[aA][lL][lL]$ ]]; then
        echo $available_regions
    else
        # Convert region input to an array of trimmed regions
        IFS=$'\n' read -d '' -r -a specified_regions <<< "$region_input"
        # Validate each region
        for region in "${specified_regions[@]}"; do
            trimmed_region=$(echo "$region" | xargs)  # Trim whitespace
            if [[ " $available_regions " =~ " $trimmed_region " ]]; then
                valid_regions+=("$trimmed_region")
            else
                invalid_regions+=("$trimmed_region")
            fi
        done
        # Check for any invalid regions
        if [ ${#invalid_regions[@]} -ne 0 ]; then
            echo "\nInvalid region specified: ${invalid_regions[*]} \n" >&2
            echo "invalid" # signal an error
        fi
        # Return only valid regions
        echo "${valid_regions[@]}"
    fi
}

# Read regions from file and process
if [ -f "$regions_file" ]; then
    regions_input=$(cat "$regions_file")
    # Process regions
    regions=$(process_regions "$regions_input")
    if [[ $regions != "invalid" ]]; then
        echo -e "\nUsing regions: \n"
        IFS=' ' # Set the Internal Field Separator to space for proper word splitting
        for region in $regions; do
            echo "$region"
        done
        echo ""
    fi
else
    echo "\nRegions file not found: $regions_file \n" >&2
    exit 1
fi
