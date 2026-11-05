# In an otherwise unused session, nothing should need saving, so "quit" exits
# without asking.  If it asks, answer "no" and report that.
proc tk_dialog {w title text bitmap def args} {
    puts "DIALOG [string map {"\n" " "} $text]"
    if {[lsearch $args abort] >= 0} {return [lsearch $args skip]}
    return 0
}
drc off
scalegrid 1 2
puts "FLAGS [cellname flags (UNNAMED)]"
writeall
puts "REACHED_QUIT"
quit
puts "QUIT_DID_NOT_EXIT"
quit -noprompt
