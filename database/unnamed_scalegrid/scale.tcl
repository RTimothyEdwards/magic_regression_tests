# Record the dialogs that magic raises, and answer each with the last choice
# ("abort" for "writeall", "yes" for "quit" would exit, so answer "no").
set ::dialogs {}
proc tk_dialog {w title text bitmap def args} {
    lappend ::dialogs [string map {"\n" " "} $text]
    if {[lsearch $args abort] >= 0} {return [lsearch $args skip]}
    return 0
}
proc report {tag} {
    puts "$tag $::dialogs"
    set ::dialogs {}
}

drc off
box 0 0 10 10
paint metal1
scalegrid 1 2
writeall
report PAINTED_WRITEALL
quit
report PAINTED_QUIT

load cell -silent
scalegrid 1 2
puts "CELL_FLAGS [cellname flags cell]"
puts "DONE"
quit -noprompt
