# Paint in the child, then answer each "writeall" prompt with "write".
proc tk_dialog {w title text bitmap def args} {
    puts "PROMPT [lindex [split $text] 0]"
    return 0
}
drc off
load parent -silent
select top cell
expand
load leaf -silent
box {*}$::env(EDIT_AREA)
paint metal1
load parent -silent
writeall
puts "DONE"
quit -noprompt
