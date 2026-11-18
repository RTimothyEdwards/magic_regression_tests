# Read the layout with locking set by $env(LOCKING) and print the state of
# every cell, then try to make cell $env(WRITECELL) writeable.
crashbackups stop
locking $env(LOCKING)
puts "LOCKING [locking]"
load top
select top cell
expand
foreach c {top c0 c1 c2} {
    puts "STATE $c [cellname list writeable $c]"
}
cellname writeable $env(WRITECELL) true
puts READER_DONE
quit -noprompt
