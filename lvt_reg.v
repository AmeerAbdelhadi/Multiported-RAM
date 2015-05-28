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
//         lvt_reg.v:  Register-based binary-coded LVT (Live-Value-Table)         //
//                                                                                //
//    Author: Ameer M. Abdelhadi (ameer@ece.ubc.ca, ameer.abdelhadi@gmail.com)    //
// SRAM-based Multi-ported RAMs; University of British Columbia (UBC), March 2013 //
////////////////////////////////////////////////////////////////////////////////////

`include "utils.vh"

module lvt_reg
 #(  parameter MEMD    = 16, // memory depth
     parameter nRPORTS = 2 , // number of reading ports
     parameter nWPORTS = 2 , // number of writing ports
     parameter RDW     = 0 , // new data for Read-During-Write
     parameter IZERO   = 0 , // binary / Initial RAM with zeros (has priority over IFILE)
     parameter IFILE   = ""  // initialization file, optional
  )( input                               clk  ,  // clock
     input  [               nWPORTS-1:0] WEnb ,  // write enable for each writing port
     input  [`log2(MEMD   )*nWPORTS-1:0] WAddr,  // write addresses    - packed from nWPORTS write ports
     input  [`log2(MEMD   )*nRPORTS-1:0] RAddr,  // read  addresses    - packed from nRPORTS read  ports
     output [`log2(nWPORTS)*nRPORTS-1:0] RBank); // read bank selector - packed from nRPORTS read  ports

  localparam ADDRW = `log2(MEMD   ); // address width
  localparam LVTW  = `log2(nWPORTS); // required memory width

  // Generate Bank ID's to write into LVT
  reg  [LVTW*nWPORTS-1:0] WData1D              ; 
  wire [LVTW        -1:0] WData2D [nWPORTS-1:0];
  genvar gi;
  generate
    for (gi=0;gi<nWPORTS;gi=gi+1) begin: GenerateID
      assign  WData2D[gi]=gi;
    end
  endgenerate

  // pack ID's into 1D array
  `ARRINIT;
  always @* `ARR2D1D(nWPORTS,LVTW,WData2D,WData1D);

  mpram_reg    #( .MEMD   (MEMD    ),  // memory depth
                  .DATAW  (LVTW    ),  // data width
                  .nRPORTS(nRPORTS ),  // number of reading ports
                  .nWPORTS(nWPORTS ),  // number of writing ports
                  .RDW    (RDW     ),  // provide new data when Read-During-Write?
                  .IZERO  (IZERO   ),  // binary / Initial RAM with zeros (has priority over IFILE)
                  .IFILE  (IFILE   ))  // initialization file, optional
  mpram_reg_ins ( .clk    (clk     ),  // clock                                             - in
                  .WEnb   (WEnb    ),  // write enable for each writing port                - in : [      nWPORTS-1:0]
                  .WAddr  (WAddr   ),  // write addresses - packed from nWPORTS write ports - in : [ADDRW*nWPORTS-1:0]
                  .WData  (WData1D ),  // write data      - packed from nRPORTS read  ports - in : [LVTW *nWPORTS-1:0]
                  .RAddr  (RAddr   ),  // read  addresses - packed from nRPORTS read  ports - in : [ADDRW*nRPORTS-1:0]
                  .RData  (RBank   )); // read  data      - packed from nRPORTS read  ports - out: [LVTW *nRPORTS-1:0]

endmodule
