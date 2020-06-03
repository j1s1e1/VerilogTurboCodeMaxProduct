# VerilogTurboCodeMaxProduct
Turbo coder and decoder

***** Important
This project uses shared files from my VerilogCommon project.  Please also download that project to get those files.
*****

There are currenlty two versions.  The original versions processes blocks of symbols.  This takes a lot of resources since the data is all passed in on the same clock and separate hardware operates on each symbol in the block.  The second version processes one symbol per clock cycle.  This is more efficient, but requires some additional data management.  This version has stream_ appended to the front of most modules. 

Several interface files are provided to provide a way to configure the turbo decoder.  These include:

Trellis Interface

This interface allows for feedforward or recursive trellis encoding.  The interface module is paramaterized to allow the use of different convolutional codes.  The interface precalculates previous states, next states, outputs, and branch metrics as constant paramaters that can be used by various modules based on a couple of interface parameters.

Interleave Interface

This interface generates forward and reverse interleave patterns.  for the block processing, it is just used to transorm blocks.  For the streaming processing, it is wrapped in a module that buffers data so that the forward and reverse interleaving can be done.  This should allow simple changes to the interleaver without changing any of the other code.

Currently, the data is processed as 32 bit floats.  There are parameters for the data type and number of bits.  It would be trivial to use the 16 bit half float type in the common project.  I also have a variable precision float type that has not been uploaded yet.  Currently, processing does not include modulo arithmetic.  For the large float type, this does not really matter.  If a smaller float type or fixed point type were used, it would probably be necessary to either use modulo arithmetic, or reduce the outputs of each alpha and beta step by the minimum value to prevent growth out of the precision range.
