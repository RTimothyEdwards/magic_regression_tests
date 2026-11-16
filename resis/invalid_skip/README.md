# Reject unknown layers without corrupting the skip masks

Run an invalid extresist skip command, a valid command, and a mask reset.
The invalid layer must produce a diagnostic and execution must continue.

Before the paired fix, DBTechNoisyNameType returns a negative index, and
CmdExtResis still clears ResCopyMask at that index. AddressSanitizer reports
a global-buffer-overflow. The test should be run with an AddressSanitizer
build to detect that error reliably; an ordinary build may silently write
outside the array without crashing.

No process design kit is needed: the test uses the built-in scmos technology.
