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
// mrram.v:Multiread-RAM using bank replication; based on generic dual-ported RAM //
//                 with optional single-stage or two-stage bypass                 //
//                                                                                //
//    Author: Ameer M. Abdelhadi (ameer@ece.ubc.ca, ameer.abdelhadi@gmail.com)    //
// SRAM-based Multi-ported RAMs; University of British Columbia (UBC), March 2013 //
////////////////////////////////////////////////////////////////////////////////////

`include "utils.vh"

module mrram
 #(  parameter MEMD    = 16, // memory depth
     parameter DATAW   = 32, // data width
     parameter nRPORTS = 3 , // number of reading ports
     parameter BYPASS  = 1 , // bypass? 0:none; 1: single-stage; 2:two-stages
     parameter IZERO   = 0 , // binary / Initial RAM with zeros (has priority over IFILE)
     parameter IFILE   = ""  // initialization mif file (don't pass extension), optional
  )( input                                clk  ,  // clock
     input                                WEnb ,  // write enable  (1 port)
     input      [`log2(MEMD)        -1:0] WAddr,  // write address (1 port)
     input      [DATAW              -1:0] WData,  // write data    (1 port)
     input      [`log2(MEMD)*nRPORTS-1:0] RAddr,  // read  addresses - packed from nRPORTS  read  ports
     output reg [DATAW      *nRPORTS-1:0] RData); // read  data - packed from nRPORTS read ports

  localparam ADDRW = `log2(MEMD); // address width

  // unpacked read addresses/data
  reg  [ADDRW-1:0] RAddr_upk [nRPORTS-1:0]; // read addresses - unpacked 2D array 
  wire [DATAW-1:0] RData_upk [nRPORTS-1:0]; // read data      - unpacked 2D array 

  // unpack read addresses; pack read data
  `ARRINIT;
  always @* begin
    `ARR1D2D(nRPORTS,ADDRW,RAddr,RAddr_upk);
    `ARR2D1D(nRPORTS,DATAW,RData_upk,RData);
  end

  // generate and instantiate generic RAM blocks
  genvar rpi;
  generate
    for (rpi=0 ; rpi<nRPORTS ; rpi=rpi+1) begin: RPORTrpi
      // generic dual-ported ram instantiation
      dpram  #( .MEMD   (MEMD        ),  // memory depth
                .DATAW  (DATAW       ),  // data width
                .BYPASS (BYPASS      ),  // bypass? 0: none; 1: single-stage; 2:two-stages
                .IZERO  (IZERO       ),  // binary / Initial RAM with zeros (has priority over INITFILE)
                .IFILE  (IFILE       ))  // initialization file, optional
      dpram_i ( .clk  (clk           ),  // clock         - in
                .WEnb (WEnb          ),  // write enable  - in
                .WAddr(WAddr         ),  // write address - in : [`log2(MEMD)-1:0]
                .WData(WData         ),  // write data    - in : [DATAW      -1:0]
                .RAddr(RAddr_upk[rpi]),  // read  address - in : [`log2(MEMD)-1:0]
                .RData(RData_upk[rpi])); // read  data    - out: [DATAW      -1:0]
    end
  endgenerate

endmodule
