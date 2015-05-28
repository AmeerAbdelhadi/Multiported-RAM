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
//dpram.v: Generic dual-ported RAM with optional single-stage or two-stage bypass.//
//                                                                                //
//    Author: Ameer M. Abdelhadi (ameer@ece.ubc.ca, ameer.abdelhadi@gmail.com)    //
// SRAM-based Multi-ported RAMs; University of British Columbia (UBC), March 2013 //
////////////////////////////////////////////////////////////////////////////////////

`include "utils.vh"

module dpram
 #(  parameter MEMD    = 16, // memory depth
     parameter DATAW   = 32, // data width
     parameter BYPASS  = 1 , // bypass? 0:none; 1: single-stage; 2: two-stage
     parameter IZERO   = 0 , // binary / Initial RAM with zeros (has priority over IFILE)
     parameter IFILE   = ""  // initialization hex file (don't pass extension), optional
  )( input                    clk  , // clock
     input                    WEnb , // write enable for each writing port
     input  [`log2(MEMD)-1:0] WAddr, // write addresses - packed from nWPORTS write ports
     input  [DATAW      -1:0] WData, // write data      - packed from nRPORTS read ports
     input  [`log2(MEMD)-1:0] RAddr, // read  addresses - packed from nRPORTS  read  ports
     output reg [DATAW  -1:0] RData  // read  data      - packed from nRPORTS read ports
  );

  wire [DATAW-1:0] RData_i; // read ram data (internal) - packed from nRPORTS read ports
  mpram_gen #( .MEMD   (MEMD   ),  // memory depth
               .DATAW  (DATAW  ),  // data width
               .nRPORTS(1      ),  // number of reading ports
               .nWPORTS(1      ),  // number of writing ports
               .IZERO  (IZERO  ),  // binary / Initial RAM with zeros (has priority over INITFILE)
               .IFILE  (IFILE  ))  // initializtion file, optional
  dpram_inst ( .clk    (clk    ),  // clock
               .WEnb   (WEnb   ),  // write enable for each writing port                - in : [nWPORTS-1:0            ]
               .WAddr  (WAddr  ),  // write addresses - packed from nWPORTS write ports - in : [`log2(MEMD)*nWPORTS-1:0]
               .WData  (WData  ),  // write data      - packed from nRPORTS read  ports - out: [DATAW      *nWPORTS-1:0]
               .RAddr  (RAddr  ),  // read  addresses - packed from nRPORTS read  ports - in : [`log2(MEMD)*nRPORTS-1:0]
               .RData  (RData_i)); // read  data      - packed from nRPORTS read  ports - out: [DATAW      *nRPORTS-1:0]

  // registers; will be removed if unused
  reg WEnb_r;
  reg [`log2(MEMD)-1:0] WAddr_r;
  reg [`log2(MEMD)-1:0] RAddr_r;
  reg [DATAW-1:0] WData_r;
  always @(posedge clk) begin
    WEnb_r  <= WEnb ;
    WAddr_r <= WAddr;
    RAddr_r <= RAddr;
    WData_r <= WData; // bypass register
  end
  
  // bypass: single-staeg, two-stage (logic will be removed if unused)
  wire bypass1,bypass2;
  assign bypass1 = (BYPASS >= 1) && WEnb_r && (WAddr_r == RAddr_r);
  assign bypass2 = (BYPASS == 2) && WEnb   && (WAddr   == RAddr_r);

  // output mux (mux or mux inputs will be removed if unused)
  always @*
    if (bypass2)      RData = WData  ;
    else if (bypass1) RData = WData_r;
         else         RData = RData_i;

endmodule
