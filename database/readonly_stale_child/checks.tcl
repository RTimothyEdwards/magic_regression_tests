# Process the timestamp mismatches with the DRC off, so that any check areas
# remain, then write the cells so that their check areas can be seen in the files.
proc tk_dialog {w title text bitmap def args} {
    # Answer "skip" to the prompts:  only the mismatch processing is wanted here
    return 2
}
drc off
load top -silent
select top cell
expand
writeall
writeall force vendorparent cleanparent staleparent staleboxparent top
puts "DONE"
quit -noprompt
