# Exit status of magic in batch mode

Scripts and flows that run magic in batch mode (`-dnull -noconsole`) rely
on its exit status to detect failures.  Before magic 8.3.447 (commit
11080465, November 2023), magic always exited with status 0, even after
`exit -1`, because the Tcl exit hook did not pass the exit value on.
(Notes in `~/devel/magic/exit_code/`.)

## What the test does

`exit.tcl` paints a little metal in scmos and then ends in one of several
ways, and `run.sh` checks magic's exit status:

| Case       | Script ends with                 | Expected status |
|------------|----------------------------------|-----------------|
| `exit3`    | `exit 3`                         | 3               |
| `exitneg`  | `exit -1`                        | 255             |
| `exit0`    | `exit 0`                         | 0               |
| `exitproc` | `exit 5` called inside a proc    | 5               |
| `quit`     | `quit -noprompt`                 | 0               |
| `eof`      | nothing (end of input)           | 0               |

With magic 8.3.446 (just before the fix), every case exits with status 0.

Not covered:  the related problem where `magic -rcfile <rc> script.tcl`
failed with "invalid command name magic::u2l" when run with graphics
(the wrapper's `-nowindow` argument ended up after the script name, so it
was passed to the script;  `~/devel/magic/Aquiles/scripting/`).  It
happens only with a graphics display, which the test runs do not have.
