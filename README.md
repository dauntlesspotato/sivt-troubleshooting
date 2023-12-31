# sivt-troubleshooting

You should use the scripts in the network_tests folder to test network connectivity

You should create a VM on each network (SIVT can be used for this), and then run the curl 
test script on that network to test that all services local to that network are 
available, and that the network has access to the requisite services in other networks.

You can create an nginx webserver on the SIVT instance to serve whatever port you are trying to test using

    docker run -it --rm -d -p 8080:80 --name web nginx

![Alt text](/../screenshots/images/vSphere-network-diagram.png?raw=true "Network Diagram")

![Alt text](/../screenshots/images/curl-test-example.jpg?raw=true "Curl Test Example")

Please refer all questions to me@johncarden.engineer or jcarden@vmware.com.
# sivt-troubleshooting
