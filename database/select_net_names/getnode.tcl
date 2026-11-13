# Two wires labeled N (not a port);  the second also has top-level port P.
# From the first wire, "getnode" gives N, unless labels of the same name
# connect ("extract no unique"):  then the port name P takes precedence.
cellname create p
load p
box 0 0 10 4;   paint metal1
box 0 0 2 4;    label N c metal1
box 0 20 10 24; paint metal1
box 0 20 2 24;  label N c metal1
box 8 20 10 24; label P c metal1
port make 1
foreach mode {unique nounique} {
    if {$mode == "unique"} {extract do unique} else {extract no unique}
    select clear
    box 0 0 10 4
    select area metal1
    puts "GN $mode [getnode]"
}

# With "getnode alias on", each node gives a list of its names, the
# chosen name first.  A third wire has labels Q and R, and a fourth
# has no label.
box 0 40 10 44; paint metal1
box 0 40 2 44;  label Q c metal1
box 8 40 10 44; label R c metal1
box 0 60 10 64; paint metal1
getnode alias on
foreach mode {unique nounique} {
    if {$mode == "unique"} {extract do unique} else {extract no unique}
    select clear
    box 0 0 10 4
    select area metal1
    puts "GA $mode [getnode]"
}
select clear
box 0 40 10 44
select area metal1
puts "GA labels [getnode]"
select clear
box 0 60 10 64
select area metal1
puts "GA nolabel [getnode]"
# Two nodes, with and without aliases
select clear
box 0 0 10 4
select area metal1
box 0 40 10 44
select more area metal1
puts "GA twonodes [getnode]"
getnode alias off
puts "GA twonodes_off [getnode]"
quit -noprompt
