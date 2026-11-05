# Saving a cell twice in one second

A timestamp is the time in seconds.  If a cell was modified and saved, and then
modified and saved again within the same second, then its timestamp was already
current.  The update returned without clearing the flag that said that it needed
a new one, so magic reported:

    Magic error: writing out-of-date timestamp for cell.

and the flag stayed set after the save.  Scripts are the usual way to do this.

The test saves a cell repeatedly, and checks that it did so within one second.
A save in a later second must still produce a new timestamp, recorded by the
parent.
