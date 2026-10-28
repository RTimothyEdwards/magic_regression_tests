# Place three instances of the L-shaped cell "ell" on the same bounding
# box:  one normal, one mirrored (same bounding box, different transform),
# and one exact duplicate of the first.  Only the exact duplicate should
# be discarded.  The case is chosen by the environment variable CASE:
#
#   getcell   place the instances with "getcell" (saved as top_getcell.mag)
#   gds       write a GDS file with the three instances, read it back, and
#             save the top cell (top_gds.mag)

drc off
crashbackups stop

# The cell "ell":  an L shape, not symmetric
cellname create ell
load ell
box values 0 0 79 309
paint m1
box values 0 0 244 56
paint m1
save ell

switch $env(CASE) {
    getcell {
	cellname create top_getcell
	load top_getcell
	box values 0 0 0 0
	getcell ell
	box values 0 0 0 0
	getcell ell h
	box values 0 0 0 0
	getcell ell
	save top_getcell
    }
    gds {
	# Get the GDS layer and datatype of metal1 from magic's own output,
	# then write the test file with three SREFs (see mkgds.py) and read
	# it back.
	gds write ell
	exec python3 $env(TESTDIR)/mkgds.py ell.gds top.gds
	cellname rename ell ell_orig
	gds read top.gds
	load top_gds
	save top_gds
    }
}
puts "DONE"
quit -noprompt
