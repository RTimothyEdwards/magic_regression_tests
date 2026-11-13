# Cell "sub" has two disconnected metal1 wires labeled with port A, and
# two labeled with (non-port) B.  Cell "top" has the same with port C and
# label D, and an instance of "sub" at (100, 4).  From one wire of each
# name, "select net" is run with each "extract do unique" setting, and
# then again with "sub" marked as an abstract view.
proc wires {names} {
    foreach {y name port} $names {
	box 0 $y 10 [expr {$y + 4}]
	paint metal1
	box 0 $y 2 [expr {$y + 4}]
	label $name c metal1
	if {$port} {port make 1}
    }
}
cellname create sub
load sub
wires {0 A 1 20 A 1 40 B 0 60 B 0}
cellname create top
load top
wires {0 C 1 20 C 1 40 D 0 60 D 0}
box 100 4 100 4
getcell sub
select top cell
expand

proc nets {tag} {
    foreach mode {unique notopports nounique} {
	switch $mode {
	    unique {extract do unique}
	    notopports {extract do unique notopports}
	    nounique {extract no unique}
	}
	foreach {name x y} {C 5 2 D 5 42 A 105 6 B 105 46} {
	    select clear
	    box $x $y $x $y
	    select net
	    puts "NET $tag $mode $name [select bbox]"
	}
    }
}
nets plain
load sub
property LEFview TRUE
load top
nets abstract
quit -noprompt
