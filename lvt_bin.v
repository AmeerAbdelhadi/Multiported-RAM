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
//                 lvt_bin.v: Binary-coded LVT (Live-Value-Table)                 //
//                                                                                //
//    Author: Ameer M. Abdelhadi (ameer@ece.ubc.ca, ameer.abdelhadi@gmail.com)    //
// SRAM-based Multi-ported RAMs; University of British Columbia (UBC), March 2013 //
////////////////////////////////////////////////////////////////////////////////////

`include "utils.vh"

module lvt_bin
 #(  parameter MEMD    = 16, // memory depth
     parameter nRPORTS = 2 , // number of reading ports
     parameter nWPORTS = 2 , // number of writing ports
     parameter WAW     = 1 , // allow Write-After-Write (need to bypass feedback ram)
     parameter RAW     = 1 , // new data for Read-after-Write (need to bypass output ram)
     parameter RDW     = 0 , // new data for Read-During-Write
     parameter IZERO   = 0 , // binary / Initial RAM with zeros (has priority over IFILE)
     parameter IFILE   = ""  // initialization file, optional
  )( input                                   clk  ,  // clock
     input      [               nWPORTS-1:0] WEnb ,  // write enable for each writing port
     input      [`log2(MEMD)   *nWPORTS-1:0] WAddr,  // write addresses - packed from nWPORTS write ports
     input      [`log2(MEMD)   *nRPORTS-1:0] RAddr,  // read  addresses - packed from nRPORTS  read  ports
     output reg [`log2(nWPORTS)*nRPORTS-1:0] RBank); // read  data - packed from nRPORTS read ports

  localparam ADDRW = `log2(MEMD   ); // address width
  localparam LVTW  = `log2(nWPORTS); // required memory width

  // Generate Bank ID's to write into LVT
  wire [LVTW        -1:0] WData2D [nWPORTS-1:0];
  genvar gi;
  generate
    for (gi=0;gi<nWPORTS;gi=gi+1) begin: GenerateID
      assign  WData2D[gi]=gi;
    end
  endgenerate

  // Register write addresses, data and enables
  reg [ADDRW*nWPORTS-1:0] WAddr_r; // registered write addresses - packed from nWPORTS write ports
  reg [      nWPORTS-1:0] WEnb_r ; // registered write enable for each writing port
  always @(posedge clk) begin
    WAddr_r <= WAddr;
    WEnb_r  <= WEnb ;
  end

  // unpacked/pack addresses/data
  reg  [ADDRW            -1:0] WAddr2D    [nWPORTS-1:0]             ; // write addresses            / 2D
  reg  [ADDRW            -1:0] WAddr2D_r  [nWPORTS-1:0]             ; // registered write addresses / 2D
  wire [LVTW * nRPORTS   -1:0] RDataOut2D [nWPORTS-1:0]             ; // read data out              / 2D
  reg  [LVTW             -1:0] RDataOut3D [nWPORTS-1:0][nRPORTS-1:0]; // read data out              / 3D
  reg  [ADDRW*(nWPORTS-1)-1:0] RAddrFB2D  [nWPORTS-1:0]             ; // read address fb            / 2D
  reg  [ADDRW            -1:0] RAddrFB3D  [nWPORTS-1:0][nWPORTS-2:0]; // read address fb            / 3D
  wire [LVTW *(nWPORTS-1)-1:0] RDataFB2D  [nWPORTS-1:0]             ; // read data fb               / 2D
  reg  [LVTW             -1:0] RDataFB3D  [nWPORTS-1:0][nWPORTS-2:0]; // read data fb               / 3D
  reg  [LVTW             -1:0] WDataFB2D  [nWPORTS-1:0]             ; // write data                 / 2D
  reg  [LVTW             -1:0] RBank2D    [nRPORTS-1:0]             ; // read data                  / 2D 
  `ARRINIT;
  always @* begin
    `ARR1D2D(nWPORTS,          ADDRW,WAddr     ,WAddr2D   );
    `ARR1D2D(nWPORTS,          ADDRW,WAddr_r   ,WAddr2D_r );
    `ARR2D1D(nRPORTS,          LVTW ,RBank2D   ,RBank     );
    `ARR2D3D(nWPORTS,nRPORTS  ,LVTW ,RDataOut2D,RDataOut3D);
    `ARR3D2D(nWPORTS,nWPORTS-1,ADDRW,RAddrFB3D ,RAddrFB2D );
    `ARR2D3D(nWPORTS,nWPORTS-1,LVTW ,RDataFB2D ,RDataFB3D );
  end

  // generate and instantiate mulriread BRAMs
  genvar wpi;
  generate
    for (wpi=0 ; wpi<nWPORTS ; wpi=wpi+1) begin: RPORTwpi
      // feedback multiread ram instantiation
      mrram    #( .MEMD   (MEMD           ),  // memory depth
                  .DATAW  (LVTW           ),  // data width
                  .nRPORTS(nWPORTS-1      ),  // number of reading ports
                  .BYPASS (WAW||RDW||RAW  ),  // bypass? 0:none; 1:single-stage; 2:two-stages
                  .IZERO  (IZERO          ),  // binary / Initial RAM with zeros (has priority over IFILE)
                  .IFILE  (IFILE          ))  // initialization file, optional
      mrram_fbk ( .clk    (clk            ),  // clock                                            - in
                  .WEnb   (WEnb_r[wpi]    ),  // write enable  (1 port)                           - in
                  .WAddr  (WAddr2D_r[wpi] ),  // write address (1 port)                           - in : [`log2(MEMD)        -1:0]
                  .WData  (WDataFB2D[wpi] ),  // write data    (1 port)                           - in : [LVTW               -1:0]
                  .RAddr  (RAddrFB2D[wpi] ),  // read  addresses - packed from nRPORTS read ports - in : [`log2(MEMD)*nRPORTS-1:0]
                  .RData  (RDataFB2D[wpi] )); // read  data      - packed from nRPORTS read ports - out: [LVTW       *nRPORTS-1:0]
      // output multiread ram instantiation
      mrram    #( .MEMD   (MEMD           ),  // memory depth
                  .DATAW  (LVTW           ),  // data width
                  .nRPORTS(nRPORTS        ),  // number of reading ports
                  .BYPASS (RDW ? 2 : RAW  ),  // bypass? 0:none; 1:single-stage; 2:two-stages
                  .IZERO  (IZERO          ),  // binary / Initial RAM with zeros (has priority over IFILE)
                  .IFILE  (IFILE          ))  // initialization file, optional
      mrram_out ( .clk    (clk            ),  // clock                                            - in
                  .WEnb   (WEnb_r[wpi]    ),  // write enable  (1 port)                           - in
                  .WAddr  (WAddr2D_r[wpi] ),  // write address (1 port)                           - in : [`log2(MEMD)        -1:0]
                  .WData  (WDataFB2D[wpi] ),  // write data    (1 port)                           - in : [LVTW               -1:0]
                  .RAddr  (RAddr          ),  // read  addresses - packed from nRPORTS read ports - in : [`log2(MEMD)*nRPORTS-1:0]
                  .RData  (RDataOut2D[wpi])); // read  data      - packed from nRPORTS read ports - out: [LVTW       *nRPORTS-1:0]
    end
  endgenerate

  // combinatorial logic for output and feedback functions
  integer i,j,k;
  always @* begin
    // generate output read functions
    for(i=0;i<nRPORTS;i=i+1) begin
      RBank2D[i] = RDataOut3D[0][i];
      for(j=1;j<nWPORTS;j=j+1) RBank2D[i] = RBank2D[i] ^ RDataOut3D[j][i];
    end
    // generate feedback functions
    for(i=0;i<nWPORTS;i=i+1) WDataFB2D[i] = WData2D[i];
    for(i=0;i<nWPORTS;i=i+1) begin
      k = 0;
      for(j=0;j<nWPORTS-1;j=j+1) begin
        k=k+(j==i);
        RAddrFB3D[i][j] = WAddr2D[k];
        WDataFB2D[k] = WDataFB2D[k] ^ RDataFB3D[i][j];
        k=k+1;
      end
    end
  end

endmodule
