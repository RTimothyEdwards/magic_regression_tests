proc tk_dialog {w title text bitmap def args} {
    puts "PROMPT [lindex [split $text] 0]"
    return 0
}
drc on
load top -silent
select top cell
expand
writeall
drc catchup
writeall
puts "DONE"
quit -noprompt
