#
# longname.tcl --- Write and read cell uses with very long use names.
# See README.md.  Run in the directory where files are to be written.

set fails 0

proc check {what got want} {
    global fails
    if {$got eq $want} {
	puts "  ok: $what"
    } else {
	puts "  FAILED: $what (got $got, expected $want)"
	incr fails
    }
}

# Return the lengths and last characters of the use names in a cell, sorted
proc uses {cell} {
    set result {}
    set fh [open $cell.mag]
    foreach line [split [read $fh] "\n"] {
	if {[lindex $line 0] eq "use"} {
	    set id [lindex $line 2]
	    lappend result "[string length $id][string index $id end]"
	}
    }
    close $fh
    return [lsort $result]
}

# 1. Write:  a use name longer than 1024 characters (this crashed magic).
#    The "identify" command is limited by the 2048 character command
#    line limit, so use 1500 characters.

load child
box 0 0 10 10
paint m1
save child
load parent
box 0 0 10 10
getcell child
select cell child_0
identify [string repeat "x" 1499]A
box 20 0 30 10
getcell child
select cell child_0
identify [string repeat "x" 1499]B
save parent
check "write 1500 character use names" [uses parent] {1500A 1500B}

# 2. Read back:  names must not be truncated (which would make the two
#    use names identical) and the file must be readable.

# Read a cell, write it out again under a new name, and return its uses
proc readback {cell} {
    load $cell
    cellname rename $cell ${cell}_out
    save ${cell}_out
    return [uses ${cell}_out]
}
check "read and rewrite 1500 character use names" [readback parent] {1500A 1500B}

# 3. Read files with use lines around and far past the 2048 character
#    line buffer used for reading.

proc mkfile {name idlen} {
    set id [string repeat "x" [expr {$idlen - 1}]]
    set fh [open $name.mag w]
    puts $fh "magic\ntech scmos\ntimestamp 0\n<< checkpaint >>\nrect 0 0 30 10"
    puts $fh "use child  ${id}A\ntimestamp 0\ntransform 1 0 0 0 1 0\nbox 0 0 10 10"
    puts $fh "use child  ${id}B\ntimestamp 0\ntransform 1 0 20 0 1 0\nbox 0 0 10 10"
    puts $fh "<< end >>"
    close $fh
}
# "use child  " is 11 characters, so these give line lengths of 2046
# to 2049 characters plus the newline, then about 5000 and 20000.
foreach len {2035 2036 2037 2038 5000 20000} {
    mkfile long$len $len
    check "read use names of $len characters" [readback long$len] \
		[list ${len}A ${len}B]
}

puts "RESULT failures=$fails"
quit -noprompt
