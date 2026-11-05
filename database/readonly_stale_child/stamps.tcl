# Answer each "writeall" prompt with "write", and record the cell it names.
proc tk_dialog {w title text bitmap def args} {
    puts "PROMPT [lindex [split $text] 0]"
    return 0
}
drc off
load top -silent
select top cell
expand
writeall
puts "DONE"
quit -noprompt
