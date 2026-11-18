# Long resistor-network node names

Extract a branched metal1 wire and a transistor pair using short and
1100-character terminal-name prefixes. Every full terminal name must survive
and remain distinct, the ports must remain connected through wire resistance,
and renaming must not change the physical network.

The wire exercises generated internal node names. The transistor pair also
exercises device terminal renaming. Before the fix, fixed 1000-byte buffers
in ResWriteExtFile and related output routines overflow. An ordinary build
aborts with stack smashing; AddressSanitizer identifies the overflowing copy.

Run with an AddressSanitizer build for the memory-safety check. The default
build also detects the original wire crash. Generated native logs and
netlists remain in work/ when the test fails.
