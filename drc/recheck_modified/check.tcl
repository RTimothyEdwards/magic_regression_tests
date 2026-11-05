# Run a full DRC check on each cell in $CELLS, then "writeall", answering "write"
# to each prompt and recording the cell it names.
proc tk_dialog {w title text bitmap def args} {
    puts "PROMPT [lindex [split $text] 0]"
    return 0
}
drc on
foreach cell $::env(CELLS) {
    load $cell -silent
    select top cell
    drc check
    drc catchup
}
writeall
puts "DONE"
quit -noprompt
