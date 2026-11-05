proc tk_dialog {w title text bitmap def args} {
    puts "PROMPT [lindex [split $text] 0]"
    return 0
}
drc off
load pending -silent
select top cell
drc check
save
set f [open pending.mag]
if {[string first "<< checkpaint >>" [read $f]] >= 0} {puts "SAVED_WITH_CHECKPAINT"}
close $f
drc on
drc catchup
writeall
puts "DONE"
quit -noprompt
