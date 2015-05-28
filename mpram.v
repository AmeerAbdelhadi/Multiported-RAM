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
// mpram.v:  Multiported-RAM: Register-based, XOR, register-LVT, binary & one-hot //
//                                                                                //
//    Author: Ameer M. Abdelhadi (ameer@ece.ubc.ca, ameer.abdelhadi@gmail.com)    //
// SRAM-based Multi-ported RAMs; University of British Columbia (UBC), March 2013 //
////////////////////////////////////////////////////////////////////////////////////

`include "utils.vh"

module mpram
 #(  parameter MEMD    = 16       , // memory depth
     parameter DATAW   = 32       , // data width
     parameter nRPORTS = 2        , // number of reading ports
     parameter nWPORTS = 2        , // number of writing ports
     parameter TYPE    = ""       , // implementation type: REG, XOR, LVTREG, LVTBIN, LVT1HT, AUTO
     parameter BYP     = "RAW"    , // Bypassing type: NON, WAW, RAW, RDW
                                    // WAW: Allow Write-After-Write (need to bypass feedback ram)
                                    // RAW: new data for Read-after-Write (need to bypass output ram)
                                    // RDW: new data for Read-During-Write
     parameter IFILE   = "init_ram" // initialization file, optional
  )( input                                 clk  ,  // clock
     input       [nWPORTS-1:0            ] WEnb ,  // write enable for each writing port
     input       [`log2(MEMD)*nWPORTS-1:0] WAddr,  // write addresses - packed from nWPORTS write ports
     input       [DATAW      *nWPORTS-1:0] WData,  // write data - packed from nWPORTS read ports
     input       [`log2(MEMD)*nRPORTS-1:0] RAddr,  // read  addresses - packed from nRPORTS  read  ports
     output wire [DATAW      *nRPORTS-1:0] RData); // read  data - packed from nRPORTS read ports

  localparam ADDRW = `log2(MEMD); // address width

  // Auto calculation of best method when TYPE="AUTO" is selected.
  localparam l2nW     = `log2(nWPORTS);
  localparam nBitsXOR = DATAW*(nWPORTS-1);
  localparam nBitsBIN = l2nW*(nWPORTS+nRPORTS-1);
  localparam nBits1HT = (nWPORTS-1)*(nRPORTS+1);
  localparam AUTOTYPE = ( (nBits1HT<=nBitsXOR) && (nBits1HT<=nBitsBIN) ) ? "LVT1HT" : ( (nBitsBIN<=nBitsXOR) ? "BIN" : "XOR" );
  // if TYPE is not one of known types (REG, XOR, LVTREG, LVTBIN, LVT1HT) choose auto (best) type
  localparam iTYPE    = ((TYPE!="REG")&&(TYPE!="XOR")&&(TYPE!="LVTREG")&&(TYPE!="LVTBIN")&&(TYPE!="LVT1HT")) ? AUTOTYPE : TYPE;

  // Bypassing indicators
  localparam WAW =  BYP!="NON"               ; // allow Write-After-Write (need to bypass feedback ram)
  localparam RAW = (BYP=="RAW")||(BYP=="RDW"); // new data for Read-after-Write (need to bypass output ram)
  localparam RDW =  BYP=="RDW"               ; // new data for Read-During-Write


  // generate and instantiate RAM with specific implementation
  generate
    if (nWPORTS==1) begin
      // instantiate multiread RAM
      mrram            #( .MEMD   (MEMD      ),  // memory depth
                          .DATAW  (DATAW     ),  // data width
                          .nRPORTS(nRPORTS   ),  // number of reading ports
                          .BYPASS (RDW?2:RAW ),  // bypass? 0:none; 1:single-stage; 2:two-stages
                          .IFILE  (IFILE     ))  // initialization file, optional
      mrram_ins         ( .clk    (clk       ),  // clock                                            - in
                          .WEnb   (WEnb      ),  // write enable  (1 port)                           - in
                          .WAddr  (WAddr     ),  // write address (1 port)                           - in : [`log2(MEMD)        -1:0]
                          .WData  (WData     ),  // write data    (1 port)                           - in : [DATAW              -1:0]
                          .RAddr  (RAddr     ),  // read  addresses - packed from nRPORTS read ports - in : [`log2(MEMD)*nRPORTS-1:0]
                          .RData  (RData     )); // read  data      - packed from nRPORTS read ports - out: [DATAW      *nRPORTS-1:0]
    end
    else if (iTYPE=="REG"   ) begin
      // instantiate multiported register-based RAM
      mpram_reg        #( .MEMD   (MEMD      ),  // memory depth
                          .DATAW  (DATAW     ),  // data width
                          .nRPORTS(nRPORTS   ),  // number of reading ports
                          .nWPORTS(nWPORTS   ),  // number of writing ports
                          .RDW    (RDW       ),  // provide new data when Read-During-Write?
                          .IFILE  (IFILE     ))  // initializtion file, optional
      mpram_reg_ref     ( .clk    (clk       ),  // clock
                          .WEnb   (WEnb      ),  // write enable for each writing port                - in : [nWPORTS-1:0            ]
                          .WAddr  (WAddr     ),  // write addresses - packed from nWPORTS write ports - in : [`log2(MEMD)*nWPORTS-1:0]
                          .WData  (WData     ),  // write data      - packed from nRPORTS read  ports - out: [DATAW      *nWPORTS-1:0]
                          .RAddr  (RAddr     ),  // read  addresses - packed from nRPORTS read  ports - in : [`log2(MEMD)*nRPORTS-1:0]
                          .RData  (RData     )); // read  data      - packed from nRPORTS read  ports - out: [DATAW      *nRPORTS-1:0]
    end
    else if (iTYPE=="XOR"   ) begin
      // instantiate XOR-based multiported RAM
      mpram_xor        #( .MEMD   (MEMD      ),  // memory depth
                          .DATAW  (DATAW     ),  // data width
                          .nRPORTS(nRPORTS   ),  // number of reading ports
                          .nWPORTS(nWPORTS   ),  // number of writing ports
                          .WAW    (WAW       ), // allow Write-After-Write (need to bypass feedback ram)
                          .RAW    (RAW       ), // new data for Read-after-Write (need to bypass output ram)
                          .RDW    (RDW       ), // new data for Read-During-Write
                          .IFILE  (IFILE     ))  // initializtion file, optional
      mpram_xor_ins     ( .clk    (clk       ),  // clock
                          .WEnb   (WEnb      ),  // write enable for each writing port                - in : [nWPORTS-1:0            ]
                          .WAddr  (WAddr     ),  // write addresses - packed from nWPORTS write ports - in : [`log2(MEMD)*nWPORTS-1:0]
                          .WData  (WData     ),  // write data      - packed from nRPORTS read  ports - out: [DATAW      *nWPORTS-1:0]
                          .RAddr  (RAddr     ),  // read  addresses - packed from nRPORTS read  ports - in : [`log2(MEMD)*nRPORTS-1:0]
                          .RData  (RData     )); // read  data      - packed from nRPORTS read  ports - out: [DATAW      *nRPORTS-1:0]
    end
    else if (iTYPE=="LVTREG") begin
      // instantiate a multiported RAM with binary-coded register-based LVT
      mpram_lvt_reg    #( .MEMD   (MEMD      ),  // memory depth
                          .DATAW  (DATAW     ),  // data width
                          .nRPORTS(nRPORTS   ),  // number of reading ports
                          .nWPORTS(nWPORTS   ),  // number of writing ports
                          .RDW    (RDW       ), // new data for Read-During-Write
                          .IFILE  (IFILE     ))  // initializtion file, optional
      mpram_lvt_reg_ins ( .clk    (clk       ),  // clock
                          .WEnb   (WEnb      ),  // write enable for each writing port                - in : [nWPORTS-1:0            ]
                          .WAddr  (WAddr     ),  // write addresses - packed from nWPORTS write ports - in : [`log2(MEMD)*nWPORTS-1:0]
                          .WData  (WData     ),  // write data      - packed from nRPORTS read  ports - out: [DATAW      *nWPORTS-1:0]
                          .RAddr  (RAddr     ),  // read  addresses - packed from nRPORTS read  ports - in : [`log2(MEMD)*nRPORTS-1:0]
                          .RData  (RData     )); // read  data      - packed from nRPORTS read  ports - out: [DATAW      *nRPORTS-1:0]
    end
    else if (iTYPE=="LVTBIN") begin
      // instantiate a multiported RAM with binary-coded SRAM LVT
      mpram_lvt_bin    #( .MEMD   (MEMD      ),  // memory depth
                          .DATAW  (DATAW     ),  // data width
                          .nRPORTS(nRPORTS   ),  // number of reading ports
                          .nWPORTS(nWPORTS   ),  // number of writing ports
                          .WAW    (WAW       ), // allow Write-After-Write (need to bypass feedback ram)
                          .RAW    (RAW       ), // new data for Read-after-Write (need to bypass output ram)
                          .RDW    (RDW       ), // new data for Read-During-Write
                          .IFILE  (IFILE     ))  // initializtion file, optional
      mpram_lvt_bin_ins ( .clk    (clk       ),  // clock
                          .WEnb   (WEnb      ),  // write enable for each writing port                - in : [nWPORTS-1:0            ]
                          .WAddr  (WAddr     ),  // write addresses - packed from nWPORTS write ports - in : [`log2(MEMD)*nWPORTS-1:0]
                          .WData  (WData     ),  // write data      - packed from nRPORTS read  ports - out: [DATAW      *nWPORTS-1:0]
                          .RAddr  (RAddr     ),  // read  addresses - packed from nRPORTS read  ports - in : [`log2(MEMD)*nRPORTS-1:0]
                          .RData  (RData     )); // read  data      - packed from nRPORTS read  ports - out: [DATAW      *nRPORTS-1:0]
    end
    else begin
      // instantiate a multiported RAM with onehot-coded SRAM LVT
      mpram_lvt_1ht    #( .MEMD   (MEMD      ),  // memory depth
                          .DATAW  (DATAW     ),  // data width
                          .nRPORTS(nRPORTS   ),  // number of reading ports
                          .nWPORTS(nWPORTS   ),  // number of writing ports
                          .WAW    (WAW       ), // allow Write-After-Write (need to bypass feedback ram)
                          .RAW    (RAW       ), // new data for Read-after-Write (need to bypass output ram)
                          .RDW    (RDW       ), // new data for Read-During-Write
                          .IFILE  (IFILE     ))  // initializtion file, optional
      mpram_lvt_1ht_ins ( .clk    (clk       ),  // clock
                          .WEnb   (WEnb      ),  // write enable for each writing port                - in : [nWPORTS-1:0            ]
                          .WAddr  (WAddr     ),  // write addresses - packed from nWPORTS write ports - in : [`log2(MEMD)*nWPORTS-1:0]
                          .WData  (WData     ),  // write data      - packed from nRPORTS read  ports - out: [DATAW      *nWPORTS-1:0]
                          .RAddr  (RAddr     ),  // read  addresses - packed from nRPORTS read  ports - in : [`log2(MEMD)*nRPORTS-1:0]
                          .RData  (RData     )); // read  data      - packed from nRPORTS read  ports - out: [DATAW      *nRPORTS-1:0]
    end
  endgenerate

endmodule

