#Create a simulator object
set ns [new Simulator]

#Define different colors for data flows (for NAM)
$ns color 1 Blue
$ns color 2 Red
$ns color 3 Green

# set to "cubic" for cubic results
set algorithm "reno"

set nf [open outReno.nam w]
set tf [open TCPReno.tr w]
if {$algorithm eq "cubic"} {
	set nf [open TCPCubic.nam w]
	set tf [open TCPCubic.tr w]
}

$ns namtrace-all $nf
$ns trace-all $tf


#Set session routing policy for all nodes
$ns rtproto Session

#Procedure to plot the congestion window
proc plotWindow {tcpSource outfile} {
	global ns
	set now [$ns now]
	set cwnd [$tcpSource set cwnd_]

#the data is recorded in a file called congestionReno.xg for TCP Reno
#the date is recorded in a file called congestionCubic.xg for TCP Cubic
puts $outfile "$now $cwnd"
$ns at [expr $now + 0.1] "plotWindow $tcpSource $outfile"
}

#Define a 'drawGraph' procedure
proc drawGraph {} {
	global ns nf tf algorithm
	$ns flush-trace
	#Close the NAM trace file
	close $nf
	#Close the trace file
	close $tf
	if {$algorithm eq "cubic"} { 
		exec nam outCubic.nam &
		exec xgraph congestionCubic.xg -geometry 300x300 &
	} else {
		exec nam outReno.nam &
		exec xgraph congestionReno.xg -geometry 300x300 &
	}
}

proc doExit {} {
	exit 0
}

#########################################################################
# The below proc does the following:
# 1. Opens the trace file generated for a TCP Variant (Reno/Cubic)
# 2. Analyzes each line for "Drop" event and TCP Packet Type.
# 3. Counts the dropped packets.
# 4. Prints the value.
########################################################################
proc findPacketsDropped {} {
	global algorithm
	if {$algorithm eq "reno"} {
		set fid [open TCPReno.tr]
	} else {
		set fid [open TCPCubic.tr]
	}
	
	set trace [read $fid]
	close $fid	

	# Split into records on newlines
	set records [split $trace "\n"]	

	set packtdropped 0	

	#Iterate over the records
	foreach rec $records {	

	     # Split the records to fields with space as separator
	     set fields [split $rec " "]
	    
	     # Assign fields to variables and count the dropped packets for tcp
	     lassign $fields \
	       event time fnode tnode pkttyp psize flags fid saddr daddr snum pid	

	       if { $pkttyp == "tcp" && $event == "d"
	       } then {
	          incr packtdropped 
	       }
	}
	puts "Total packets dropped for TCP $algorithm is: $packtdropped"
}

#Create eight nodes
set n0 [$ns node]
set n1 [$ns node]
set n2 [$ns node]
set n3 [$ns node]
set n4 [$ns node]
set n5 [$ns node]
set n6 [$ns node]
set n7 [$ns node]

#Create links between the nodes
$ns duplex-link $n0 $n2 1Mb 2ms DropTail
$ns duplex-link $n1 $n2 1Mb 2ms DropTail
$ns duplex-link $n2 $n3 0.7Mb 2ms DropTail
$ns duplex-link $n4 $n3 1Mb 2ms DropTail
$ns duplex-link $n3 $n5 0.7Mb 2ms DropTail
$ns duplex-link $n5 $n6 1Mb 2ms DropTail
$ns duplex-link $n5 $n7 1Mb 2ms DropTail

#Set Queue Size for links to 10
$ns queue-limit $n2 $n3 10
$ns queue-limit $n3 $n5 10

#Give node position (for NAM)
$ns duplex-link-op $n0 $n2 orient right-down
$ns duplex-link-op $n1 $n2 orient right-up
$ns duplex-link-op $n2 $n3 orient right
$ns duplex-link-op $n4 $n3 orient right-down 
$ns duplex-link-op $n3 $n5 orient right
$ns duplex-link-op $n5 $n6 orient right-up
$ns duplex-link-op $n5 $n7 orient right-down

#Create a UDP agent and attach it to node n0
set udp0 [new Agent/UDP]
$udp0 set fid_ 1
$ns attach-agent $n0 $udp0

#Create a CBR traffic source and attach to udp0
set cbr0 [new Application/Traffic/CBR]
$cbr0 set packetSize_ 500
$cbr0 set interval_ 0.005
$cbr0 attach-agent $udp0

#Create a UDP agent and attach it to node n4
set udp4 [new Agent/UDP]
$udp4 set fid_ 3
$ns attach-agent $n4 $udp4

#Create a CBR traffic source and attach to udp4
set cbr4 [new Application/Traffic/CBR]
$cbr4 set packetSize_ 500
$cbr4 set interval_ 0.005
$cbr4 attach-agent $udp4

#Create a TCP agent and attach it to node n1
if {$algorithm eq "cubic"} {
	set tcp1 [new Agent/TCP/Linux]
} else {
	set tcp1 [new Agent/TCP/Reno]
}

$tcp1 set class_ 2
$tcp1 set fid_ 2
if {$algorithm eq "cubic"} {
	$ns at 0 "$tcp1 select_ca cubic"
} 

$ns attach-agent $n1 $tcp1

#Create a FTP traffic source and attach to tcp1
set ftp1 [new Application/FTP]
$ftp1 attach-agent $tcp1  

#Create the sink for TCP1
set sink6 [new Agent/TCPSink]
$ns attach-agent $n6  $sink6
$ns connect $tcp1 $sink6

#Create the sink for UDP0
set null70 [new Agent/Null]
$ns attach-agent $n7 $null70
$ns connect $udp0 $null70

#Create the sink for UPD1
set null71 [new Agent/Null]
$ns attach-agent $n7 $null71
$ns connect $udp4 $null71

#Schedule events for the CBR and FTP agents
$ns at 8.0 "$cbr0 start"
$ns at 8.0 "$cbr4 start"
$ns at 1.0 "$ftp1 start"
$ns at 19.0 "$ftp1 stop"
$ns at 13.0 "$cbr0 stop"
$ns at 13.0 "$cbr4 stop"

#Detach tcp and sink agents (not really necessary)
$ns at 19.0 "$ns detach-agent $n1 $tcp1 ; $ns detach-agent $n6 $sink6"

#find packets dropped
$ns at 20.0 "findPacketsDropped"

#draw graph
$ns at 21.0 "drawGraph"

#Call the exit procedure after 21 seconds of simulation time
$ns at 22.0 "doExit"



#Print CBR packet size and interval
puts "CBR packet size for n0 = [$cbr0 set packet_size_]"
puts "CBR interval n0 = [$cbr0 set interval_]"

puts "CBR packet size for n4 = [$cbr4 set packet_size_]"
puts "CBR interval n4 = [$cbr4 set interval_]"

#Uncomment below line to Generate graph for TCP Reno congestion
if {$algorithm eq "cubic"} {
	set outfile [open "congestionCubic.xg" w]
} else {
	set outfile [open "congestionReno.xg" w]
}

$ns at 0.0 "plotWindow $tcp1 $outfile"

#Run the simulation
$ns run

# script for calculating packet drops
# if {$algorithm eq "reno"} {
# 	set fid [open TCPReno.tr]
# } else {
# 	set fid [open TCPCubic.tr]
# }

# set trace [read $fid]
# close $fid	

# # Split into records on newlines
# set records [split $trace "\n"]	

# set packtdropped 0	

# #Iterate over the records
# foreach rec $records {	
# 	# Split the records to fields with space as separator
# 	set fields [split $rec " "]
	    
# 	# Assign fields to variables and count the dropped packets for tcp
# 	lassign $fields \
# 	    event time fnode tnode pkttyp psize flags fid saddr daddr snum pid	

# 	if { $pkttyp == "tcp" && $event == "d"
# 	} then {
# 	   incr packtdropped 
# 	}
# }
# puts "Total packets dropped for TCP $algorithm is: $packtdropped"

