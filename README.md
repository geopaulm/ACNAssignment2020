# ACNAssignment2020
To execute the TCL file question1.tcl and get the required graphs and traces, please follow the below steps on Windows 10 system.

On Windows 10 system:

- Install ubuntu 18.04 using oracle virtual box
    - Oracle virtual box download
      https://www.virtualbox.org/wiki/Downloads
    - Ubuntu download
      https://releases.ubuntu.com/18.04/
    - how to install ubuntu with oracle virtual box on windows 10
      https://itsfoss.com/install-linux-in-virtualbox/
  
 - Once you have brought up the ubuntu box on virutal box VM, install ns2 and associated tools
    - Follow this link for installing ns2
      https://zoomadmin.com/HowToInstall/UbuntuPackage/ns2
    - For installing nam
      sudo apt install nam
    - Follow the below link for installing xgraph
      https://askubuntu.com/questions/1196290/xgraph-in-ubuntu-18-4
      
 Now, we are done with the needed tools for this assignment
 
 - create a directory ACNAssignment in your home directory
   command: mkdir ACNAssignment
 - download the question1.tcl file in to this directory
 - run the simulation
   command: ns question1.tcl
   
Note: for generating TCP Reno and TCP Cubic graphs and traces, open the source code and comment the lines mentioned.
      
