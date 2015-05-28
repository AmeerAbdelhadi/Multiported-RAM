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
//                 mpram_wrp.v: Multiported-RAM synthesis wrapper                 //
//                                                                                //
//    Author: Ameer M. Abdelhadi (ameer@ece.ubc.ca, ameer.abdelhadi@gmail.com)    //
// SRAM-based Multi-ported RAMs; University of British Columbia (UBC), March 2013 //
////////////////////////////////////////////////////////////////////////////////////

`include "utils.vh"

// configure architectural parameters
`include "config.vh"

module mpram_wrp
 #(  parameter MEMD    = `MEMD   , // memory depth
     parameter DATAW   = `DATAW  , // data width
     parameter nRPORTS = `nRPORTS, // number of reading ports
     parameter nWPORTS = `nWPORTS, // number of writing ports
     parameter TYPE    = `TYPE   , // implementation type: REG, XOR, LVTREG, LVTBIN, LVT1HT, AUTO
     parameter BYP     = `BYP    , // Bypassing type: NON, WAW, RAW, RDW
     parameter IFILE   = ""        // initialization file, optional
  )( input                                 clk  ,  // clock
     input       [nWPORTS-1:0            ] WEnb ,  // write enable for each writing port
     input       [`log2(MEMD)*nWPORTS-1:0] WAddr,  // write addresses - packed from nWPORTS write ports
     input       [DATAW      *nWPORTS-1:0] WData,  // write data - packed from nWPORTS read ports
     input       [`log2(MEMD)*nRPORTS-1:0] RAddr,  // read  addresses - packed from nRPORTS  read  ports
     output wire [DATAW      *nRPORTS-1:0] RData); // read  data - packed from nRPORTS read ports

  // instantiate a multiported-RAM
  mpram     #( .MEMD   (MEMD   ),  // positive integer: memory depth
               .DATAW  (DATAW  ),  // positive integer: data width
               .nRPORTS(nRPORTS),  // positive integer: number of reading ports
               .nWPORTS(nWPORTS),  // positive integer: number of writing ports
               .TYPE   (TYPE   ),  // text: multi-port RAM implementation type: "AUTO", "REG", "XOR", "LVTREG", "LVTBIN", or "LVT1HT"
                                   //   AUTO  : Choose automatically based on the design parameters
                                   //   REG   : Register-based multi-ported RAM
                                   //   XOR   : XOR-based nulti-ported RAM  
                                   //   LVTREG: Register-based LVT multi-ported RAM
                                   //   LVTBIN: Binary-coded I-LVT-based multi-ported RAM
                                   //   LVT1HT: Onehot-coded I-LVT-based multi-ported RAM
               .BYP    (BYP    ),  // text: Bypassing type: "NON", "WAW", "RAW", or "RDW"
                                   //   WAW: Allow Write-After-Write (need to bypass feedback ram)
                                   //   RAW: New data for Read-after-Write (need to bypass output ram)
                                   //   RDW: New data for Read-During-Write
               .IFILE  (""     ))  // text: initializtion file, optional
  mpram_inst ( .clk    (clk    ),  // clock
               .WEnb   (WEnb   ),  // write enable for each writing port                - input : [nWPORTS-1:0            ]
               .WAddr  (WAddr  ),  // write addresses - packed from nWPORTS write ports - input : [`log2(MEMD)*nWPORTS-1:0]
               .WData  (WData  ),  // write data      - packed from nRPORTS read  ports - output: [DATAW      *nWPORTS-1:0]
               .RAddr  (RAddr  ),  // read  addresses - packed from nRPORTS read  ports - input : [`log2(MEMD)*nRPORTS-1:0]
               .RData  (RData  )); // read  data      - packed from nRPORTS read  ports - output: [DATAW      *nRPORTS-1:0]

endmodule

