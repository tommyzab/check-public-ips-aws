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

# File to store the unique public IPs
output_file="public-ips.txt"
> "$output_file"  # clear the file content if already exists

# Function to add an IP to the file if it's not already present
add_unique_ip() {
    local ip=$1
    grep -qxF "$ip" "$output_file" || echo "$ip" >> "$output_file"
}

# Iterate over all validated regions
for region in $regions; do
    echo ""
    echo "Checking region: $region"

    # EC2 Instances Public IPs
    for ip in $(aws ec2 describe-instances --region $region --query 'Reservations[*].Instances[*].PublicIpAddress' --output text); do
        add_unique_ip "$ip"
    done

    # Elastic IPs
    for ip in $(aws ec2 describe-addresses --region $region --query 'Addresses[*].PublicIp' --output text); do
        add_unique_ip "$ip"
    done

    # ELBs (Classic, Application, and Network Load Balancers)
    # Using nslookup to resolve DNS names to IPs
    for dns in $(aws elb describe-load-balancers --region $region --query 'LoadBalancerDescriptions[*].DNSName' --output text); do
        if [ ! -z "$dns" ]; then
            for ip in $(nslookup "$dns" | grep '^Address:' | grep -v '#' | awk '{ print $2 }'); do
                add_unique_ip "$ip"
            done
            sleep 2
        fi
    done
    for dns in $(aws elbv2 describe-load-balancers --region $region --query 'LoadBalancers[*].DNSName' --output text); do
        if [ ! -z "$dns" ]; then
            for ip in $(nslookup "$dns" | grep '^Address:' | grep -v '#' | awk '{ print $2 }'); do
                add_unique_ip "$ip"
            done
            sleep 2
        fi
    done

    # NAT Gateways Public IPs
    for ip in $(aws ec2 describe-nat-gateways --region $region --query 'NatGateways[*].NatGatewayAddresses[*].PublicIp' --output text); do
        add_unique_ip "$ip"
    done

    # Network Interfaces (ENIs) Public IPs
    for ip in $(aws ec2 describe-network-interfaces --region $region --query 'NetworkInterfaces[*].Association.PublicIp' --output text | grep -v None); do
        add_unique_ip "$ip"
    done
done

echo "\nAll public IPs have been checked and unique entries are saved in \"$output_file\".\n"
