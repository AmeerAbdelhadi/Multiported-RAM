////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2013, University of British Columbia (UBC); All rights reserved. //
//                                                                                //
// Redistribution  and  use  in  source   and  binary  forms,   with  or  without //
// modification,  are permitted  provided that  the following conditions are met: //
//   * Redistributions   of  source   code  must  retain   the   above  copyright //
//     notice,  this   list   of   conditions   and   the  following  disclaimer. //
//   * Redistributions  in  binary  form  must  reproduce  the  above   copyright //
//     notice, this  list  of  conditions  and the  following  disclaimer in  the //
//     documentation and/or  other  materials  provided  with  the  distribution. //
//   * Neither the name of the University of British Columbia (UBC) nor the names //
//     of   its   contributors  may  be  used  to  endorse  or   promote products //
//     derived from  this  software without  specific  prior  written permission. //
//                                                                                //
// THIS  SOFTWARE IS  PROVIDED  BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" //
// AND  ANY EXPRESS  OR IMPLIED WARRANTIES,  INCLUDING,  BUT NOT LIMITED TO,  THE //
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE //
// DISCLAIMED.  IN NO  EVENT SHALL University of British Columbia (UBC) BE LIABLE //
// FOR ANY DIRECT,  INDIRECT,  INCIDENTAL,  SPECIAL,  EXEMPLARY, OR CONSEQUENTIAL //
// DAMAGES  (INCLUDING,  BUT NOT LIMITED TO,  PROCUREMENT OF  SUBSTITUTE GOODS OR //
// SERVICES;  LOSS OF USE,  DATA,  OR PROFITS;  OR BUSINESS INTERRUPTION) HOWEVER //
// CAUSED AND ON ANY THEORY OF LIABILITY,  WHETHER IN CONTRACT, STRICT LIABILITY, //
// OR TORT  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE //
// OF  THIS SOFTWARE,  EVEN  IF  ADVISED  OF  THE  POSSIBILITY  OF  SUCH  DAMAGE. //
////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////
//   mpram_gen.v: Generic multiported-RAM; Old data will be read in case of RAW.  //
//                                                                                //
//    Author: Ameer M. Abdelhadi (ameer@ece.ubc.ca, ameer.abdelhadi@gmail.com)    //
// SRAM-based Multi-ported RAMs; University of British Columbia (UBC), March 2013 //
////////////////////////////////////////////////////////////////////////////////////

`include "utils.vh"

module mpram_gen
 #(  parameter MEMD    = 16, // memory depth
     parameter DATAW   = 32, // data width
     parameter nRPORTS = 3 , // number of reading ports
     parameter nWPORTS = 2 , // number of writing ports
     parameter IZERO   = 0 , // binary / Initial RAM with zeros (has priority over INITFILE)
     parameter IFILE   = ""  // initialization hex file (don't pass extension), optional
  )( input                                clk  , // clock
     input      [nWPORTS-1:0            ] WEnb , // write enable for each writing port
     input      [`log2(MEMD)*nWPORTS-1:0] WAddr, // write addresses - packed from nWPORTS write ports
     input      [DATAW      *nWPORTS-1:0] WData, // write data      - packed from nRPORTS read ports
     input      [`log2(MEMD)*nRPORTS-1:0] RAddr, // read  addresses - packed from nRPORTS  read  ports
     output reg [DATAW      *nRPORTS-1:0] RData  // read  data      - packed from nRPORTS read ports
  );

  localparam ADDRW = `log2(MEMD); // address width
  integer i;

  // initialize RAM, with zeros if IZERO or file if IFLE.
  reg [DATAW-1:0] mem [0:MEMD-1]; // memory array
  initial
    if (IZERO)
      for (i=0; i<MEMD; i=i+1) mem[i] = {DATAW{1'b0}};
    else
      if (IFILE != "") $readmemh({IFILE,".hex"}, mem);

  always @(posedge clk) begin
      // write to nWPORTS ports; nonblocking statement to read old data
      for (i=1; i<=nWPORTS; i=i+1)
        if (WEnb[i-1]) mem[WAddr[i*ADDRW-1 -: ADDRW]] <= WData[i*DATAW-1 -: DATAW]; // Change into blocking statement (=) to read new data
      // Read from nRPORTS ports; nonblocking statement to read old data
      for (i=1; i<=nRPORTS; i=i+1)
        RData[i*DATAW-1 -: DATAW] <= mem[RAddr[i*ADDRW-1 -: ADDRW]]; //Change into blocking statement (=) to read new data
    end

endmodule
