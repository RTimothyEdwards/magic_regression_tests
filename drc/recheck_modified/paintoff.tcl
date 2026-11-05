# Edits made with the DRC off are still recorded as needing to be checked.
drc off
foreach {cell op} {painted paint erased erase} {
    load $cell -silent
    box 2 2 4 4
    $op metal1
    save
}
puts "DONE"
quit -noprompt
