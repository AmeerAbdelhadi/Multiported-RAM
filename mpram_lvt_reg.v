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
//   mpram_lvt_reg.v:  Multiported-RAM based on register-based binary-coded LVT   //
//                                                                                //
//    Author: Ameer M. Abdelhadi (ameer@ece.ubc.ca, ameer.abdelhadi@gmail.com)    //
// SRAM-based Multi-ported RAMs; University of British Columbia (UBC), March 2013 //
////////////////////////////////////////////////////////////////////////////////////

`include "utils.vh"

module mpram_lvt_reg
 #(  parameter MEMD    = 16, // memory depth
     parameter DATAW   = 32, // data width
     parameter nRPORTS = 2 , // number of reading ports
     parameter nWPORTS = 2 , // number of writing ports
     parameter RDW     = 0 , // new data for Read-During-Write (WAW and RAW are OK in register-based RAM)
     parameter IFILE   = ""  // initialization file, optional
  )( input                                clk  ,  // clock
     input      [nWPORTS-1:0            ] WEnb ,  // write enable for each writing port
     input      [`log2(MEMD)*nWPORTS-1:0] WAddr,  // write addresses - packed from nWPORTS write ports
     input      [DATAW      *nWPORTS-1:0] WData,  // write data - packed from nWPORTS read ports
     input      [`log2(MEMD)*nRPORTS-1:0] RAddr,  // read  addresses - packed from nRPORTS  read  ports
     output reg [DATAW      *nRPORTS-1:0] RData); // read  data - packed from nRPORTS read ports

  localparam ADDRW = `log2(MEMD   ); // address width
  localparam LVTW  = `log2(nWPORTS); // LVT     width

  // unpacked/pack addresses/data
  reg  [ADDRW        -1:0] WAddr2D  [nWPORTS-1:0]             ; // write addresses      / 2D
  reg  [DATAW        -1:0] WData2D  [nWPORTS-1:0]             ; // write data           / 2D 
  wire [DATAW*nRPORTS-1:0] RData2Di [nWPORTS-1:0]             ; // read data / internal / 2D
  reg  [DATAW        -1:0] RData3Di [nWPORTS-1:0][nRPORTS-1:0]; // read data / internal / 3D
  reg  [DATAW        -1:0] RData2D  [nRPORTS-1:0]             ; // read data / output   / 2D
  wire [LVTW *nRPORTS-1:0] RBank                              ; // read bank selector   / 1D
  reg  [LVTW         -1:0] RBank2D  [nRPORTS-1:0]             ; // read bank selector   / 2D
  `ARRINIT;
  always @* begin
    `ARR1D2D(nWPORTS,        ADDRW,WAddr   ,WAddr2D );
    `ARR1D2D(nWPORTS,        DATAW,WData   ,WData2D );
    `ARR2D3D(nWPORTS,nRPORTS,DATAW,RData2Di,RData3Di);
    `ARR2D1D(nRPORTS,        DATAW,RData2D ,RData   );
    `ARR1D2D(nRPORTS,        LVTW ,RBank   ,RBank2D );
  end

  // instantiate LVT
  lvt_reg    #( .MEMD   (MEMD     ),  // memory depth
                .nRPORTS(nRPORTS  ),  // number of reading ports
                .nWPORTS(nWPORTS  ),  // number of writing ports
                .RDW    (RDW      ),  // new data for Read-During-Write
                .IZERO  (IFILE!=""),  // binary / Initial RAM with zeros (has priority over IFILE)
                .IFILE  (""       ))  // initialization file, optional
  lvt_reg_ins ( .clk    (clk      ),  // clock                                                 - in
                .WEnb   (WEnb     ),  // write enable for each writing port                    - in : [      nWPORTS-1:0]
                .WAddr  (WAddr    ),  // write addresses    - packed from nWPORTS write ports  - in : [ADDRW*nWPORTS-1:0]
                .RAddr  (RAddr    ),  // read  addresses    - packed from nRPORTS  read  ports - in : [ADDRW*nRPORTS-1:0]
                .RBank  (RBank    )); // read bank selector - packed from nRPORTS read ports   - out: [LVTW *nRPORTS-1:0]

  // generate and instantiate mulriread RAM blocks
  genvar wpi;
  generate
    for (wpi=0 ; wpi<nWPORTS ; wpi=wpi+1) begin: RPORTwpi
      // ram_multiread instantiation
      mrram    #( .MEMD   (MEMD         ),  // memory depth
                  .DATAW  (DATAW        ),  // data width
                  .nRPORTS(nRPORTS      ),  // number of reading ports
                  .BYPASS (RDW          ),  // bypass? 0:none; 1:single-stage; 2:two-stages
                  .IZERO  (0            ),  // binary / Initial RAM with zeros (has priority over IFILE)
                  .IFILE  (wpi?"":IFILE ))  // initialization file, optional
      mrram_ins ( .clk    (clk          ),  // clock                                            - in
                  .WEnb   (WEnb[wpi]    ),  // write enable  (1 port)                           - in
                  .WAddr  (WAddr2D[wpi] ),  // write address (1 port)                           - in : [ADDRW        -1:0]
                  .WData  (WData2D[wpi] ),  // write data    (1 port)                           - in : [DATAW        -1:0]
                  .RAddr  (RAddr        ),  // read  addresses - packed from nRPORTS read ports - in : [ADDRW*nRPORTS-1:0]
                  .RData  (RData2Di[wpi])); // read  data      - packed from nRPORTS read ports - out: [DATAW*nRPORTS-1:0]
    end
  endgenerate

  // combinatorial logic for output muxes
  integer i;
  always @*  for(i=0;i<nRPORTS;i=i+1) RData2D[i] = RData3Di[RBank2D[i]][i];

endmodule
