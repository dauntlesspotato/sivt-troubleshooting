#!/bin/bash

# Define the ANSI escape codes for colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check curl version
curl_version=$(curl --version 2>&1 | head -n 1 | awk '{ print $2 }')
echo "NOTE: curl version is $curl_version, the minimum required version for error message output is 7.75.0"

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

# kube-api-server endpoints 
endpoints["kube-api-server"]="172.16.102.51:6443"

# litmus test
endpoints["sivt-management"]="172.16.10.28:443:6443"
endpoints["sivt-frontend"]="172.16.102.235:8443:22:443:6443"

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
    unset IFS
    # inform user
    echo "Testing endpoint: $key"
     
    # normal ping test
    echo -n "Normal ping test --> "
    ping_result=$(ping -w 3 -c 5 -i .6 "${value_array[0]}")
    if [[ $? != 0 ]]; then
        echo -e "${RED}Failed${NC}"
    else
        echo -e "${GREEN}OK${NC}"
    fi
    
    # jumbo ping test
    echo -n "Jumbo ping test --> "
    ping_result=$(ping -w 3 -c 5 -i .6 -s 1600 "${value_array[0]}")
    if [[ $? != 0 ]]; then
        echo -e "${RED}Failed${NC} Note: This should not prevent SIVT from completing if normal pings are successful"
    else
        echo -e "${GREEN}OK${NC}"
    fi

    # perform firewall and ping test for each port
    n=${#value_array[@]} # getting length of array
    for ((i = 1; i < n; i++)); do
        echo -n "Testing ${value_array[0]}:${value_array[$i]} --> "
        response=$(curl -s -o /dev/null -w "%{response_code}:%{errormsg}" "${value_array[0]}:${value_array[$i]}")
        #echo "Response: $response"
        IFS=":" read -ra response_array <<< "$response"
        unset IFS

        if [[ "${response_array[1]}" == *"Failed to connect"* ]]; then
            echo -e "${RED}${response_array[0]} ${response_array[1]}${NC}"
        else
            echo -e "${GREEN}${response_array[0]} OK ${NC}${response_array[1]}"
        fi
    done
    echo ""
done
