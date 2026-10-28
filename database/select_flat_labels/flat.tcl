# Flatten a cell in place with "select top cell;  select pick;  select
# flat;  select keep".  The label in the top cell ("A") must keep its name,
# and the label from the subcell instance sub_0 ("B") must get the instance
# name as a prefix.

drc off
crashbackups stop
cellname create sub
load sub
box values 0 0 10 10
paint m1
label B center m1
save sub
cellname create top
load top
box values 20 0 30 10
paint m2
label A center m2
box values 0 0 0 0
getcell sub
select top cell
select pick
select flat
select keep
save top
puts "DONE"
quit -noprompt
