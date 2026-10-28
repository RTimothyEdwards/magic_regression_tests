# Exit from a batch-mode script in the way given by the environment
# variable CASE.  run.sh checks magic's exit status.

drc off
crashbackups stop
cellname create a
load a
box values 0 0 10 10
paint m1

switch $env(CASE) {
    exit3	{ exit 3 }
    exitneg	{ exit -1 }
    exit0	{ exit 0 }
    exitproc	{ proc leave {} { exit 5 }; leave }
    quit	{ quit -noprompt }
    eof		{ }
}
