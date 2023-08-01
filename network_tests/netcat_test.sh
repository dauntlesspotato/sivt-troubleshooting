#!/bin/bash

# Define the ANSI escape codes for green color
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

declare -A endpoints

# VCenter and ESXi hosts on 443
endpoints["vcenter"]="172.16.10.40:443"
endpoints["esxi1"]="172.16.10.5:443" # if all are on the same network, one esxi host should be sufficient
#endpoints["esxi2"]="172.16.10.6:443"
#endpoints["esxi3"]="172.16.10.7:443"

# NSX ALB Controller Nodes on 443 (uncomment 2 and 3 if using HA)
endpoints["nsx-alb-controller1"]="172.16.10.41:8443:22:443"
#endpoints["nsx-alb-controller2"]="172.16.10.42:8443:22:443"
#endpoints["nsx-alb-controller3"]="172.16.10.43:8443:22:443"

# DNS Server on 53
endpoints["dns"]="192.168.4.2:53"

# frontend network endpoints 
endpoints["kube-api-server"]="172.16.102.51:6443"

# ntp server test
ntp_server="192.168.4.2"



#### ********** Don't edit past this line ********** ####

#### NTP server test logic ####
echo -n "Testing NTP Server --> "
ntpdate_result=$(ntpdate -q $ntp_server 2>&1)
if [[ $? != 0 ]]; then
    echo -e "${RED}Connection Failed${NC}"
else
    echo -e "${GREEN}OK${NC}"
fi

#### network test logic ####
for key in ${!endpoints[@]}; do
    # get values for key
    values="${endpoints[$key]}"
    # split the values on ":"
    IFS=":" read -ra value_array <<< "$values"
    # inform user
    echo "Testing endpoint: $key"
    
    # perform test for each port
    n=${#value_array[@]} # getting length of array
    for ((i = 1; i < n; i++)); do
        echo -n "Testing ${value_array[0]}:${value_array[$i]} --> "
        netcat_result=$(nc -vz "${value_array[0]}" "${value_array[$i]}" 2>&1)
        if [[ $? != 0 ]]; then
            echo -e "${RED}Connection Failed${NC}"
        else
            echo -e "${GREEN}OK${NC}"
        fi
        echo $netcat_result
    done
    echo ""
done
