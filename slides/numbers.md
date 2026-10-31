Originally we wanted to load column wise. But then we realized you had to write the entire output word in one write operation. 
Second design required a register file memory that was too large (about 600 words) and it required 9 read ports. Select muxes alone would use about 88% of the LUTs on the FPGA

add image `./memory.png`
add image `./loader.png`

Status
- We have implemented
 - memory
 - loader
 - parts of FSM
- today we expect to have a running version of the accelerator


Stats
- We compute 2 pixels in parallel
- Every word is read 3 times
- A word is read every cycle
- There is a total of `288*352/4=25344` words. With a clock speed of 100MHz we can compute `100*10⁶/(25344*3)=1315` images per second


Future work
- Improve buffering, so words are read fewer times 
- Add resource sharing
- Integrate with rest of SoC
- Add support for border pixels

