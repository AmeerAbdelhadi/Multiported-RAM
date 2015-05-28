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
//                     mpram_tb.v:  Multiported-RAM testbench                     //
//                                                                                //
//    Author: Ameer M. Abdelhadi (ameer@ece.ubc.ca, ameer.abdelhadi@gmail.com)    //
// SRAM-based Multi-ported RAMs; University of British Columbia (UBC), March 2013 //
////////////////////////////////////////////////////////////////////////////////////


`include "utils.vh"

// set default value for the following parameters, if not defined from command-line
// memory depth
`ifndef MEMD
`define MEMD    64
`endif
// data width
`ifndef DATAW
`define DATAW   8
`endif
// number of reading ports
`ifndef nWPORTS
`define nWPORTS 3
`endif
// number of writing ports
`ifndef nRPORTS
`define nRPORTS 2
`endif
// Simulation cycles count
`ifndef CYCC
`define CYCC 1000
`endif

// set data-dependency perotection/allowance

// WDW (Write-During-Write) protection
`ifndef WDW
`define WDW 0
`endif

// WAW (Write-After-Write) protection
`ifndef WAW
`define WAW 1
`endif

// RDW (Read-During-Write) protection
`ifndef RDW
`define RDW 1
`endif

// RAW (Read-After-Write) protection
`ifndef RAW
`define RAW 1
`endif

module mpram_tb;

  localparam MEMD    = `MEMD         ; // memory depth
  localparam DATAW   = `DATAW        ; // data width
  localparam nRPORTS = `nRPORTS      ; // number of reading ports
  localparam nWPORTS = `nWPORTS      ; // number of writing ports
  localparam CYCC    = `CYCC         ; // simulation cycles count
  localparam WAW     = `WAW          ; // WAW (Write-After-Write ) protection
  localparam WDW     = `WDW          ; // WDW (Write-During-Write) protection
  localparam RAW     = `RAW          ; // RAW (Read-After-Write  ) protection
  localparam RDW     = `RDW          ; // RDW (Read-During-Write ) protection
  localparam ADDRW   = `log2(MEMD)   ; // address size
  localparam LVTWBIN = `log2(nWPORTS); // LVT width for binary coding
  localparam LVTW1HT = nWPORTS-1     ; // LVT width for onehot coding
  localparam VERBOSE = 0             ; // verbose logging (1:yes; 0:no)
  localparam CYCT    = 10            ; // cycle      time
  localparam RSTT    = 5.2*CYCT      ; // reset      time
  localparam TERFAIL = 0             ; // terminate if fail?
  localparam TIMEOUT = 2*CYCT*CYCC   ; // simulation time

  reg                      clk = 1'b0                    ; // global clock
  reg                      rst = 1'b1                    ; // global reset
  reg  [nWPORTS-1:0      ] WEnb                          ; // write enable for each writing port
  reg  [ADDRW*nWPORTS-1:0] WAddr_pck                     ; // write addresses - packed from nWPORTS write ports
  reg  [ADDRW-1:0        ] WAddr_upk        [nWPORTS-1:0]; // write addresses - unpacked 2D array 
  reg  [ADDRW*nRPORTS-1:0] RAddr_pck                     ; // read  addresses - packed from nRPORTS  read  ports
  reg  [ADDRW-1:0        ] RAddr_upk        [nRPORTS-1:0]; // read  addresses - unpacked 2D array 
  reg  [DATAW*nWPORTS-1:0] WData_pck                     ; // write data - packed from nWPORTS read ports
  reg  [DATAW-1:0        ] WData_upk        [nWPORTS-1:0]; // write data - unpacked 2D array 
  wire [DATAW*nRPORTS-1:0] RData_pck_reg                 ; // read  data - packed from nRPORTS read ports
  reg  [DATAW-1:0        ] RData_upk_reg    [nRPORTS-1:0]; // read  data - unpacked 2D array 
  wire [DATAW*nRPORTS-1:0] RData_pck_xor                 ; // read  data - packed from nRPORTS read ports
  reg  [DATAW-1:0        ] RData_upk_xor    [nRPORTS-1:0]; // read  data - unpacked 2D array
  wire [DATAW*nRPORTS-1:0] RData_pck_lvtreg              ; // read  data - packed from nRPORTS read ports
  reg  [DATAW-1:0        ] RData_upk_lvtreg [nRPORTS-1:0]; // read  data - unpacked 2D array 
  wire [DATAW*nRPORTS-1:0] RData_pck_lvtbin              ; // read  data - packed from nRPORTS read ports
  reg  [DATAW-1:0        ] RData_upk_lvtbin [nRPORTS-1:0]; // read  data - unpacked 2D array 
  wire [DATAW*nRPORTS-1:0] RData_pck_lvt1ht              ; // read  data - packed from nRPORTS read ports
  reg  [DATAW-1:0        ] RData_upk_lvt1ht [nRPORTS-1:0]; // read  data - unpacked 2D array 

  integer i,j; // general indeces

  // generates random ram hex/mif initializing files
  task genInitFiles;
    input [31  :0] DEPTH  ; // memory depth
    input [31  :0] WIDTH  ; // memoty width
    input [255 :0] INITVAL; // initial vlaue (if not random)
    input          RAND   ; // random value?
    input [1:8*20] FILEN  ; // memory initializing file name
    reg   [255 :0] ramdata;
    integer addr,hex_fd,mif_fd;
    begin
      // open hex/mif file descriptors
      hex_fd = $fopen({FILEN,".hex"},"w");
      mif_fd = $fopen({FILEN,".mif"},"w");
      // write mif header
      $fwrite(mif_fd,"WIDTH         = %0d;\n",WIDTH);
      $fwrite(mif_fd,"DEPTH         = %0d;\n",DEPTH);
      $fwrite(mif_fd,"ADDRESS_RADIX = HEX;\n"     );
      $fwrite(mif_fd,"DATA_RADIX    = HEX;\n\n"   );
      $fwrite(mif_fd,"CONTENT BEGIN\n"            );
      // write random memory lines
      for(addr=0;addr<DEPTH;addr=addr+1) begin
        if (RAND) begin
          `GETRAND(ramdata,WIDTH); 
        end else ramdata = INITVAL;
        $fwrite(hex_fd,"%0h\n",ramdata);
        $fwrite(mif_fd,"  %0h :  %0h;\n",addr,ramdata);
      end
      // write mif tail
      $fwrite(mif_fd,"END;\n");
      // close hex/mif file descriptors
      $fclose(hex_fd);
      $fclose(mif_fd);
    end
  endtask

  integer rep_fd, ferr;
  initial begin
    // write header
    rep_fd = $fopen("sim.res","r"); // try to open report file for read
    $ferror(rep_fd,ferr);       // detect error
    $fclose(rep_fd);
    rep_fd = $fopen("sim.res","a+"); // open report file for append
    if (ferr) begin     // if file is new (can't open for read); write header
      $fwrite(rep_fd,"Multiported  RAM  Architectural  Parameters   Simulation Results for Different Designs \n");
      $fwrite(rep_fd,"===========================================   =========================================\n");
      $fwrite(rep_fd,"Memory   Data    Write   Read    Simulation   XOR-based   Reg-LVT   SRAM-LVT   SRAM-LVT\n");
      $fwrite(rep_fd,"Depth    Width   Ports   Ports   Cycles                              Binary     Onehot \n");
      $fwrite(rep_fd,"=======================================================================================\n");
    end
    $write("Simulating multi-ported RAM:\n");
    $write("Write ports  : %0d\n"  ,nWPORTS  );
    $write("Read ports   : %0d\n"  ,nRPORTS  );
    $write("Data width   : %0d\n"  ,DATAW    );
    $write("RAM depth    : %0d\n"  ,MEMD     );
    $write("Address width: %0d\n\n",ADDRW    );
    // generate random ram hex/mif initializing file
    genInitFiles(MEMD,DATAW   ,0,1,"init_ram");
    // finish simulation
    #(TIMEOUT) begin 
      $write("*** Simulation terminated due to timeout\n");
      $finish;
    end
  end

  // generate clock and reset
  always  #(CYCT/2) clk = ~clk; // toggle clock
  initial #(RSTT  ) rst = 1'b0; // lower reset

  // pack/unpack data and addresses
  `ARRINIT;
  always @* begin
    `ARR2D1D(nRPORTS,ADDRW,RAddr_upk        ,RAddr_pck        );
    `ARR2D1D(nWPORTS,ADDRW,WAddr_upk        ,WAddr_pck        );
    `ARR1D2D(nWPORTS,DATAW,WData_pck        ,WData_upk        );
    `ARR1D2D(nRPORTS,DATAW,RData_pck_reg    ,RData_upk_reg    );
    `ARR1D2D(nRPORTS,DATAW,RData_pck_xor    ,RData_upk_xor    );
    `ARR1D2D(nRPORTS,DATAW,RData_pck_lvtreg,RData_upk_lvtreg);
    `ARR1D2D(nRPORTS,DATAW,RData_pck_lvtbin,RData_upk_lvtbin);
    `ARR1D2D(nRPORTS,DATAW,RData_pck_lvt1ht,RData_upk_lvt1ht);
end

  // register write addresses
  reg  [ADDRW-1:0        ] WAddr_r_upk   [nWPORTS-1:0]; // previous (registerd) write addresses - unpacked 2D array 
  always @(negedge clk)
    //WAddr_r_pck <= WAddr_pck;
    for (i=0;i<nWPORTS;i=i+1) WAddr_r_upk[i] <= WAddr_upk[i];

  // generate random write data and random write/read addresses; on falling edge
  reg wdw_addr; // indicates same write addresses on same cycle (Write-During-Write)
  reg waw_addr; // indicates same write addresses on next cycle (Write-After-Write)
  reg rdw_addr; // indicates same read/write addresses on same cycle (Read-During-Write)
  reg raw_addr; // indicates same read address on next cycle (Read-After-Write)
  always @(negedge clk) begin
    // generate random write addresses; different that current and previous write addresses
    for (i=0;i<nWPORTS;i=i+1) begin
      wdw_addr = 1; waw_addr = 1;
      while (wdw_addr || waw_addr) begin
        `GETRAND(WAddr_upk[i],ADDRW);
        wdw_addr = 0; waw_addr = 0;
        if (!WDW) for (j=0;j<i      ;j=j+1) wdw_addr = wdw_addr || (WAddr_upk[i] == WAddr_upk[j]  );
        if (!WAW) for (j=0;j<nWPORTS;j=j+1) waw_addr = waw_addr || (WAddr_upk[i] == WAddr_r_upk[j]);
      end
    end
    // generate random read addresses; different that current and previous write addresses
    for (i=0;i<nRPORTS;i=i+1) begin
      rdw_addr = 1; raw_addr = 1;
      while (rdw_addr || raw_addr) begin
        `GETRAND(RAddr_upk[i],ADDRW);
        rdw_addr = 0; raw_addr = 0;
        if (!RDW) for (j=0;j<nWPORTS;j=j+1) rdw_addr = rdw_addr || (RAddr_upk[i] == WAddr_upk[j]  );
        if (!RAW) for (j=0;j<nWPORTS;j=j+1) raw_addr = raw_addr || (RAddr_upk[i] == WAddr_r_upk[j]);
      end
    end
    // generate random write data and write enables
    `GETRAND(WData_pck,DATAW*nWPORTS);
    `GETRAND(WEnb     ,      nWPORTS); if (rst) WEnb={nWPORTS{1'b0}};
  end

  integer cycc=1; // cycles count
  integer cycp=0; // cycles percentage
  integer errc=0; // errors count
  integer fail;
  integer pass_xor_cur    ; // xor multiported-ram passed in current cycle
  integer pass_lvt_reg_cur; // lvt_reg multiported-ram passed in current cycle
  integer pass_lvt_bin_cur; // lvt_bin multiported-ram passed in current cycle
  integer pass_lvt_1ht_cur; // lvt_1ht multiported-ram passed in current cycle
  integer pass_xor     = 1; // xor multiported-ram passed
  integer pass_lvt_reg = 1; // lvt_reg multiported-ram passed
  integer pass_lvt_bin = 1; // lvt_bin multiported-ram passed
  integer pass_lvt_1ht = 1; // lvt_qht multiported-ram passed

  always @(negedge clk)
    if (!rst) begin
      #(CYCT/10) // a little after falling edge
      if (VERBOSE) begin // write input data
        $write("%-7d:\t",cycc);
        $write("BeforeRise: ");
        $write("WEnb="         ); `ARRPRN(nWPORTS,WEnb             ); $write("; ");
        $write("WAddr="        ); `ARRPRN(nWPORTS,WAddr_upk        ); $write("; ");
        $write("WData="        ); `ARRPRN(nWPORTS,WData_upk        ); $write("; ");
        $write("RAddr="        ); `ARRPRN(nRPORTS,RAddr_upk        ); $write(" - ");
      end
      #(CYCT/2) // a little after rising edge
      // compare results
      pass_xor_cur     = (RData_pck_reg===RData_pck_xor   );
      pass_lvt_reg_cur = (RData_pck_reg===RData_pck_lvtreg);
      pass_lvt_bin_cur = (RData_pck_reg===RData_pck_lvtbin);
      pass_lvt_1ht_cur = (RData_pck_reg===RData_pck_lvt1ht);
      pass_xor     = pass_xor     && pass_xor_cur    ;
      pass_lvt_reg = pass_lvt_reg && pass_lvt_reg_cur;
      pass_lvt_bin = pass_lvt_bin && pass_lvt_bin_cur;
      pass_lvt_1ht = pass_lvt_1ht && pass_lvt_1ht_cur;
      fail = !(pass_xor && pass_lvt_reg && pass_lvt_bin && pass_lvt_1ht);
      if (VERBOSE) begin // write outputs
        $write("AfterRise: ");
        $write("RData_reg="    ); `ARRPRN(nRPORTS,RData_upk_reg    ); $write("; ");
        $write("RData_xor="    ); `ARRPRN(nRPORTS,RData_upk_xor    ); $write(":%s",pass_xor_cur     ? "pass" : "fail"); $write("; " );
        $write("RData_lvt_reg="); `ARRPRN(nRPORTS,RData_upk_lvtreg); $write(":%s",pass_lvt_reg_cur ? "pass" : "fail"); $write("; " );
        $write("RData_lvt_bin="); `ARRPRN(nRPORTS,RData_upk_lvtbin); $write(":%s",pass_lvt_bin_cur ? "pass" : "fail"); $write("; " );
        $write("RData_lvt_1ht="); `ARRPRN(nRPORTS,RData_upk_lvt1ht); $write(":%s",pass_lvt_1ht_cur ? "pass" : "fail"); $write(";\n");
      end else begin
        if ((100*cycc/CYCC)!=cycp) begin cycp=100*cycc/CYCC; $write("%-3d%%  passed\t(%-7d / %-7d) cycles\n",cycp,cycc,CYCC); end
      end
      if (fail && TERFAIL) begin
        $write("*** Simulation terminated due to a mismatch\n");
        $finish;
      end
      if (cycc==CYCC) begin
        $write("*** Simulation terminated after %0d cycles. Simulation results:\n",CYCC);
        $write("XOR-based          = %s",pass_xor     ? "pass;\n" : "fail;\n");
        $write("Register-based LVT = %s",pass_lvt_reg ? "pass;\n" : "fail;\n");
        $write("Binary I-LVT       = %s",pass_lvt_bin ? "pass;\n" : "fail;\n");
        $write("Onehot I-LVT       = %s",pass_lvt_1ht ? "pass;\n" : "fail;\n");
        // Append report file
        $fwrite(rep_fd,"%-7d  %-5d   %-5d   %-5d   %-10d   %-9s   %-7s   %-8s   %-08s\n",MEMD,DATAW,nWPORTS,nRPORTS,CYCC,pass_xor?"pass":"fail",pass_lvt_reg?"pass":"fail",pass_lvt_bin?"pass":"fail",pass_lvt_1ht?"pass":"fail");
        $fclose(rep_fd);
        $finish;
      end
      cycc=cycc+1;
    end

  // Bypassing indicators
  localparam BYP = RDW ? "RDW" : (RAW ? "RAW" : (WAW ? "WAW" : "NON"));

  // instantiate multiported register-based ram as reference for all other implementations
  mpram           #( .MEMD   (MEMD            ),  // memory depth
                     .DATAW  (DATAW           ),  // data width
                     .nRPORTS(nRPORTS         ),  // number of reading ports
                     .nWPORTS(nWPORTS         ),  // number of writing ports
                     .TYPE   ("REG"           ),  // multi-port RAM implementation type
                     .BYP    (BYP             ),  // Bypassing type: NON, WAW, RAW, RDW
                     .IFILE  ("init_ram"      ))  // initializtion file, optional
  mpram_reg_ref    ( .clk    (clk             ),  // clock
                     .WEnb   (WEnb            ),  // write enable for each writing port                - in : [nWPORTS-1:0            ]
                     .WAddr  (WAddr_pck       ),  // write addresses - packed from nWPORTS write ports - in : [`log2(MEMD)*nWPORTS-1:0]
                     .WData  (WData_pck       ),  // write data      - packed from nRPORTS read  ports - out: [DATAW      *nWPORTS-1:0]
                     .RAddr  (RAddr_pck       ),  // read  addresses - packed from nRPORTS read  ports - in : [`log2(MEMD)*nRPORTS-1:0]
                     .RData  (RData_pck_reg   )); // read  data      - packed from nRPORTS read  ports - out: [DATAW      *nRPORTS-1:0]
  // instantiate XOR-based multiported-RAM
  mpram           #( .MEMD   (MEMD            ),  // memory depth
                     .DATAW  (DATAW           ),  // data width
                     .nRPORTS(nRPORTS         ),  // number of reading ports
                     .nWPORTS(nWPORTS         ),  // number of writing ports
                     .TYPE   ("XOR"           ),  // multi-port RAM implementation type
                     .BYP    (BYP             ),  // Bypassing type: NON, WAW, RAW, RDW
                     .IFILE  ("init_ram"      ))  // initializtion file, optional
  mpram_xor_dut    ( .clk    (clk             ),  // clock
                     .WEnb   (WEnb            ),  // write enable for each writing port                - in : [nWPORTS-1:0            ]
                     .WAddr  (WAddr_pck       ),  // write addresses - packed from nWPORTS write ports - in : [`log2(MEMD)*nWPORTS-1:0]
                     .WData  (WData_pck       ),  // write data      - packed from nRPORTS read  ports - out: [DATAW      *nWPORTS-1:0]
                     .RAddr  (RAddr_pck       ),  // read  addresses - packed from nRPORTS read  ports - in : [`log2(MEMD)*nRPORTS-1:0]
                     .RData  (RData_pck_xor   )); // read  data      - packed from nRPORTS read  ports - out: [DATAW      *nRPORTS-1:0]
  // instantiate a multiported-RAM with binary-coded register-based LVT
  mpram           #( .MEMD   (MEMD            ),  // memory depth
                     .DATAW  (DATAW           ),  // data width
                     .nRPORTS(nRPORTS         ),  // number of reading ports
                     .nWPORTS(nWPORTS         ),  // number of writing ports
                     .TYPE   ("LVTREG"        ),  // multi-port RAM implementation type
                     .BYP    (BYP             ),  // Bypassing type: NON, WAW, RAW, RDW
                     .IFILE  ("init_ram"      ))  // initializtion file, optional
  mpram_lvtreg_dut ( .clk    (clk             ),  // clock
                     .WEnb   (WEnb            ),  // write enable for each writing port                - in : [nWPORTS-1:0            ]
                     .WAddr  (WAddr_pck       ),  // write addresses - packed from nWPORTS write ports - in : [`log2(MEMD)*nWPORTS-1:0]
                     .WData  (WData_pck       ),  // write data      - packed from nRPORTS read  ports - out: [DATAW      *nWPORTS-1:0]
                     .RAddr  (RAddr_pck       ),  // read  addresses - packed from nRPORTS read  ports - in : [`log2(MEMD)*nRPORTS-1:0]
                     .RData  (RData_pck_lvtreg)); // read  data      - packed from nRPORTS read  ports - out: [DATAW      *nRPORTS-1:0]
  // instantiate a multiported-RAM with binary-coded SRAM LVT
  mpram           #( .MEMD   (MEMD            ),  // memory depth
                     .DATAW  (DATAW           ),  // data width
                     .nRPORTS(nRPORTS         ),  // number of reading ports
                     .nWPORTS(nWPORTS         ),  // number of writing ports
                     .TYPE   ("LVTBIN"        ),  // multi-port RAM implementation type
                     .BYP    (BYP             ),  // Bypassing type: NON, WAW, RAW, RDW
                     .IFILE  ("init_ram"      ))  // initializtion file, optional
  mpram_lvtbin_dut ( .clk    (clk             ),  // clock
                     .WEnb   (WEnb            ),  // write enable for each writing port                - in : [nWPORTS-1:0            ]
                     .WAddr  (WAddr_pck       ),  // write addresses - packed from nWPORTS write ports - in : [`log2(MEMD)*nWPORTS-1:0]
                     .WData  (WData_pck       ),  // write data      - packed from nRPORTS read  ports - out: [DATAW      *nWPORTS-1:0]
                     .RAddr  (RAddr_pck       ),  // read  addresses - packed from nRPORTS read  ports - in : [`log2(MEMD)*nRPORTS-1:0]
                     .RData  (RData_pck_lvtbin)); // read  data      - packed from nRPORTS read  ports - out: [DATAW      *nRPORTS-1:0]
  // instantiate a multiported-RAM with onehot-coded SRAM LVT
  mpram           #( .MEMD   (MEMD            ),  // memory depth
                     .DATAW  (DATAW           ),  // data width
                     .nRPORTS(nRPORTS         ),  // number of reading ports
                     .nWPORTS(nWPORTS         ),  // number of writing ports
                     .TYPE   ("LVT1HT"        ),  // multi-port RAM implementation type
                     .BYP    (BYP             ),  // Bypassing type: NON, WAW, RAW, RDW
                     .IFILE  ("init_ram"      ))  // initializtion file, optional
  mpram_lvt1ht_dut ( .clk    (clk             ),  // clock
                     .WEnb   (WEnb            ),  // write enable for each writing port                - in : [nWPORTS-1:0            ]
                     .WAddr  (WAddr_pck       ),  // write addresses - packed from nWPORTS write ports - in : [`log2(MEMD)*nWPORTS-1:0]
                     .WData  (WData_pck       ),  // write data      - packed from nRPORTS read  ports - out: [DATAW      *nWPORTS-1:0]
                     .RAddr  (RAddr_pck       ),  // read  addresses - packed from nRPORTS read  ports - in : [`log2(MEMD)*nRPORTS-1:0]
                     .RData  (RData_pck_lvt1ht)); // read  data      - packed from nRPORTS read  ports - out: [DATAW      *nRPORTS-1:0]

endmodule
