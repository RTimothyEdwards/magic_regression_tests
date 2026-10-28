# Read the technology LEF (for the default route widths used by the
# regular net) and test.def, and write the result as GDS (out.gds).

drc off
crashbackups stop
lef read $env(TLEF)
def read test.def
load testcase
gds write out.gds
puts "DONE"
quit -noprompt
