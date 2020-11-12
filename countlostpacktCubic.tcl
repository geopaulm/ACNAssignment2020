##Read the trace file
set fid [open TCPCubic.tr]
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
puts "Total packets dropped for TCP Cubic is: $packtdropped"


