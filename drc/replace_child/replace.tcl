# Replace an instance with an instance of a newly created cell, in the
# order used by the device generator ("Apply" in the parameter dialog):
# delete the old instance, paint the new cell before it has any parent,
# then place it.  The new cell's errors must be copied up to the parent.
#
# In scmos, metal1 1 wide is a DRC error, 10 wide is clean.

drc on
cellname create good
load good
box 0 0 10 10; paint metal1
cellname create top
load top
box 0 0 0 0
getcell good
drc catchup
puts "COUNT before [drc list count total]"

select cell good_0
delete
cellname create bad
load bad
box 0 0 1 10; paint metal1
load top
box 0 0 0 0
getcell bad
drc catchup
puts "COUNT after [drc list count total] [drc listall count total]"

# Recheck everything:  the counts must not change
select top cell
drc check
select clear
drc catchup
puts "COUNT recheck [drc list count total] [drc listall count total]"
quit -noprompt
