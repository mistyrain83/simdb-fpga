// SIM_DB_FPGA.v
//-------------------------------------------------------------------------------
//-- File:       SIM_DB_FPGA.v
//-- Contents:   SIM DB Board FPGA Source Code
//--
//-- $Archive: /SIM_DB_FPGA.v $
//-- Copyright (c) 2013 www.000925.net, All rights reserved
//-- 
//-- $Date: 2013/11/24 10:35:39 $
//-- $Revision: 1.0 $
//-- $Author: qixiangbing $
//-- $Log: SIM_DB_FPGA.v $
//-- $Log: split channels $
//-- $Note: W_clk actually is clock(25MHz input clock) $
//--
//-- $Date: 2014-01-10 14:41 $
//-- $Revision: 1.0.2 $
//-- $Author: qixiangbing $
//-- $Log: update comments and variables name; add led module to top $
//--
//-- $Date: 2014-03-30 20:08 $
//-- $Revision: 2.0 $
//-- $Author: qixiangbing $
//-- $Log: running on SIM_DB VB board $
//--
//-- $Date: 2014-05-02 20:43 $
//-- $Revision: 2.0.1 $
//-- $Author: qixiangbing $
//-- $Log: use hard reset signal $
//--
//-- $Date: 2014-05-20 09:55 $
//-- $Revision: 2.0.2 $
//-- $Author: qixiangbing $
//-- $Log: fixed pulse1,2 diff problem $
//--
//-- $Date: 2014-06-23 17:17 $
//-- $Revision: 2.0.3 $
//-- $Author: qixiangbing $
//-- $Log: add current tachometer feature $
//--
//-- $Date: 2014-07-01 17:17 $
//-- $Revision: 2.0.4 $
//-- $Author: qixiangbing $
//-- $Log: modify TI LOCK Led to OUTPUT Led1 $
//-------------------------------------------------------------------------------

module sim_db
(
  input             I_rst_n,          // reset signal
  input             clock,            // clock signal
  input     [11:0]  I_la,             // local bus address
  inout     [15:0]  IO_ld,            // local bus data
  input             I_lrd_n,          // local bus read
  input             I_lwr_n,          // local bus write
  input             I_lcs_n,          // local bus cs
  input             I_lclk,           // local bus clock
  input             I_tx3,            // uart3 tx
  input             I_spi_cs,         // spi cs
  output            O_la_dir,         // la dir
  output            O_la_oe_n,        // la oe
  output            O_ld_dir,         // ld dir
  output            O_ld_oe_n,        // ld oe
  output    [5:0]   O_spd1_ch,        // tachometer 1 channel 1-6
  output    [5:0]   O_spd2_ch,        // tachometer 2 channel 1-6
  output            O_dop_pwm,        // doppler pwm signal
  output            O_out1,           // output
  output            O_out2,           // output
  output            O_led1,           // fpga led
  output            O_led2,           // fpga led
  output            O_btm_cd1,        // btm cd signal 1-2
  output            O_btm_cd2,        // btm cd signal 1-2
  output            O_ti_lock,        // ti lock signal
  output            O_ti_led,         // ti lock led signal
  output            O_cspd1_latch,    // current speed sensor latch
  output            O_cspd1_clr,      // current speed sensor clr
  output            O_mvb_lcs_n,      // mvb lcs
  output            O_mvb_rst_n,      // mvb reset
  output            O_spi_cl_cs_n,    // current loop spi cs
  output            O_rs485_de,       // rs485 re/de
  output  [1:0]     O_cspd_ch,        // current speed sensor channel 1-2
  output  [24:0]    O_io
);

//==============soft reset=================================
// reg        W_reset_n;
// reg   [23:0] R_Reset_Cnt;
// parameter RESET_TIME_PARAMETER = 24'hB71B00;  //25M Clock, Reset timeout 0.48s

//==============parameters=================================
parameter FPGA_Ver_ADDR= 12'h800;                        //                                    
parameter DATA_AAAA_ADDR=12'h802;                        //
parameter DATA_5555_ADDR=12'h804;                        //
parameter DATA_FFFF_ADDR=12'h806;                        //
parameter DATA_0000_ADDR=12'h808;                        //

parameter FPGA_SPD_MODE_ADDR=12'h810;                    // 输出模式寄存器，低6位为输出模式选择, 1 - 有限脉冲输出 0 - 无限 
parameter FPGA_OUTPUT_CONTROL_ADDR=12'h812;              // 0-11 SPD1-spd12;  12  dop, 1 - enable; 0 - disable
parameter FPGA_SPD_LOAD_ADDR=12'h814;                    // SPD parameter load, please ref docs

parameter FPGA_SPD1_FCONFIG_LOW_ADDR= 12'h820;           // 1，2通道低16位频率参数
parameter FPGA_SPD1_FCONFIG_HIGH_ADDR=12'h822;           // 1，2通道高16位频率参数
parameter FPGA_SPD2_FCONFIG_LOW_ADDR= 12'h824;           // 3，4通道低16位频率参数
parameter FPGA_SPD2_FCONFIG_HIGH_ADDR=12'h826;           // 3，4通道高16位频率参数
parameter FPGA_SPD3_FCONFIG_LOW_ADDR= 12'h828;           // 5，6通道低16位频率参数
parameter FPGA_SPD3_FCONFIG_HIGH_ADDR=12'h82a;           // 5，6通道高16位频率参数
parameter FPGA_SPD4_FCONFIG_LOW_ADDR= 12'h830;           // 7，8通道低16位频率参数
parameter FPGA_SPD4_FCONFIG_HIGH_ADDR=12'h832;           // 7，8通道高16位频率参数
parameter FPGA_SPD5_FCONFIG_LOW_ADDR= 12'h834;           // 9，10通道低16位频率参数
parameter FPGA_SPD5_FCONFIG_HIGH_ADDR=12'h836;           // 9，10通道高16位频率参数
parameter FPGA_SPD6_FCONFIG_LOW_ADDR= 12'h838;           // 11，12通道低16位频率参数
parameter FPGA_SPD6_FCONFIG_HIGH_ADDR=12'h83a;           // 11，12通道高16位频率参数

// 最高位判断哪个通道相位在前  1 - 2通道在先，0 - 1通道在先
parameter FPGA_SPD1_PCONFIG_LOW_ADDR= 12'h840;           // 1，2通道低16相位率参数
parameter FPGA_SPD1_PCONFIG_HIGH_ADDR=12'h842;           // 1，2通道高16相位率参数  
parameter FPGA_SPD2_PCONFIG_LOW_ADDR= 12'h844;           // 3，4通道低16相位率参数  
parameter FPGA_SPD2_PCONFIG_HIGH_ADDR=12'h846;           // 3，4通道高16相位率参数  
parameter FPGA_SPD3_PCONFIG_LOW_ADDR= 12'h848;           // 5，6通道低16相位率参数  
parameter FPGA_SPD3_PCONFIG_HIGH_ADDR=12'h84a;           // 5，6通道高16相位率参数  
parameter FPGA_SPD4_PCONFIG_LOW_ADDR= 12'h850;           // 7，8通道低16相位率参数  
parameter FPGA_SPD4_PCONFIG_HIGH_ADDR=12'h852;           // 7，8通道高16相位率参数  
parameter FPGA_SPD5_PCONFIG_LOW_ADDR= 12'h854;           // 9，10通道低16位相位参数                                      
parameter FPGA_SPD5_PCONFIG_HIGH_ADDR=12'h856;           // 9，10通道高16位相位参数 
parameter FPGA_SPD6_PCONFIG_LOW_ADDR= 12'h858;           // 11，12通道低16位相位参数
parameter FPGA_SPD6_PCONFIG_HIGH_ADDR=12'h85a;           // 11，12通道高16位相位参数

parameter FPGA_SPD1_PLUSE_ADDR = 12'h860;                // 1，2通道脉冲个数参数
parameter FPGA_SPD2_PLUSE_ADDR = 12'h862;                // 3，4通道脉冲个数参数
parameter FPGA_SPD3_PLUSE_ADDR = 12'h864;                // 5，6通道脉冲个数参数
parameter FPGA_SPD4_PLUSE_ADDR = 12'h866;                // 7，8通道脉冲个数参数
parameter FPGA_SPD5_PLUSE_ADDR = 12'h868;                // 9，10通道脉冲个数参数
parameter FPGA_SPD6_PLUSE_ADDR = 12'h86a;                // 11，12通道脉冲个数参数

// 低6位为有限个数脉冲输出结束标志 1 表示输出结束，当重新加载脉冲个数后自动为0
parameter FPGA_LIMITED_PULSE_FINISHED_ADDR = 12'h870;        

parameter FPGA_CD_TI_OUTPUT_ADDR = 12'h880;                 //  TI-2  CD2-1  CD1-0
parameter FPGA_DOP_FCONFIG_LOW_ADDR =  12'h882;             // dop 低16位频率参数
parameter FPGA_DOP_FCONFIG_HIGH_ADDR = 12'h884;             // dop 高16位频率参数

parameter FPGA_IO_OUTPUT_ADDR = 12'h890;                    // IO输出寄存器
parameter FPGA_IO_LED_ADDR = 12'h8a0;                       // 指示灯寄存器

// 脉冲初始化寄存器
parameter FPGA_SPD1_INIT_LOW_ADDR= 12'h8b0;
parameter FPGA_SPD1_INIT_HIGH_ADDR= 12'h8b2;
parameter FPGA_SPD2_INIT_LOW_ADDR= 12'h8b4;
parameter FPGA_SPD2_INIT_HIGH_ADDR= 12'h8b6;
parameter FPGA_SPD3_INIT_LOW_ADDR= 12'h8b8;
parameter FPGA_SPD3_INIT_HIGH_ADDR= 12'h8ba;

parameter FPGA_SPD4_INIT_LOW_ADDR= 12'h8c0;
parameter FPGA_SPD4_INIT_HIGH_ADDR= 12'h8c2;
parameter FPGA_SPD5_INIT_LOW_ADDR= 12'h8c4;
parameter FPGA_SPD5_INIT_HIGH_ADDR= 12'h8c6;
parameter FPGA_SPD6_INIT_LOW_ADDR= 12'h8c8;
parameter FPGA_SPD6_INIT_HIGH_ADDR= 12'h8ca;

// SPI SELECT
parameter FPGA_SPI_SELECT_ADDR = 12'h8d0;

parameter FPGA_VER_CSR = 16'hB723; // fpga version

//--------------------REG & WIRE--------------------------
wire        W_reset_n           ;
//wire        W_reset_n_n         ;
wire        W_clk               ;

wire        W_O_dop_pwm         ;
wire        W_O_normal_spd1     ;
wire        W_O_normal_spd2     ;
wire        W_O_normal_spd3     ;
wire        W_O_normal_spd4     ;
wire        W_O_normal_spd5     ;
wire        W_O_normal_spd6     ;
wire        W_O_normal_spd7     ;
wire        W_O_normal_spd8     ;
wire        W_O_normal_spd9     ;
wire        W_O_normal_spd10    ;
wire        W_O_normal_spd11    ;
wire        W_O_normal_spd12    ;
wire [5:0]  W_SPD_MODE          ;

wire [11:0] W_localbus_addr       ;
wire [15:0] W_reg_data_out       ;

wire [15:0] W_SPD1_REPORT_PULSE_LOW;
wire [15:0] W_SPD1_REPORT_PULSE_HIGH;
wire [15:0] W_SPD2_REPORT_PULSE_LOW;
wire [15:0] W_SPD2_REPORT_PULSE_HIGH;
wire [15:0] W_SPD3_REPORT_PULSE_LOW;
wire [15:0] W_SPD3_REPORT_PULSE_HIGH;

wire [15:0] W_SPD4_REPORT_PULSE_LOW;
wire [15:0] W_SPD4_REPORT_PULSE_HIGH;
wire [15:0] W_SPD5_REPORT_PULSE_LOW;
wire [15:0] W_SPD5_REPORT_PULSE_HIGH;
wire [15:0] W_SPD6_REPORT_PULSE_LOW;
wire [15:0] W_SPD6_REPORT_PULSE_HIGH;

reg  [15:0] R_FPGA_REG           ;

reg         R_I_lcs_n            ;
reg         R_I_lcs_n_1          ;
reg         R_I_lwr_n            ;
reg         R_I_lwr_n_1          ;
reg         R_I_lrd_n            ;
reg         R_I_lrd_n_1          ;
reg         R_I_lrd_n_2          ;

reg  [15:0] R_SPD1_FCONFIG_LOW     ;
reg  [15:0] R_SPD1_FCONFIG_HIGH    ;
reg  [15:0] R_SPD2_FCONFIG_LOW     ;
reg  [15:0] R_SPD2_FCONFIG_HIGH    ;
reg  [15:0] R_SPD3_FCONFIG_LOW     ;
reg  [15:0] R_SPD3_FCONFIG_HIGH    ;
reg  [15:0] R_SPD4_FCONFIG_LOW     ;
reg  [15:0] R_SPD4_FCONFIG_HIGH    ;
reg  [15:0] R_SPD5_FCONFIG_LOW     ;
reg  [15:0] R_SPD5_FCONFIG_HIGH    ;
reg  [15:0] R_SPD6_FCONFIG_LOW     ;
reg  [15:0] R_SPD6_FCONFIG_HIGH    ;
reg  [15:0] R_SPD1_PCONFIG_LOW     ;
reg  [15:0] R_SPD1_PCONFIG_HIGH    ;
reg  [15:0] R_SPD2_PCONFIG_LOW     ;
reg  [15:0] R_SPD2_PCONFIG_HIGH    ;
reg  [15:0] R_SPD3_PCONFIG_LOW     ;
reg  [15:0] R_SPD3_PCONFIG_HIGH    ;
reg  [15:0] R_SPD4_PCONFIG_LOW     ;
reg  [15:0] R_SPD4_PCONFIG_HIGH    ;
reg  [15:0] R_SPD5_PCONFIG_LOW     ;
reg  [15:0] R_SPD5_PCONFIG_HIGH    ;
reg  [15:0] R_SPD6_PCONFIG_LOW     ;
reg  [15:0] R_SPD6_PCONFIG_HIGH    ;
reg  [15:0] R_DOP_FCONFIG_LOW      ;
reg  [15:0] R_DOP_FCONFIG_HIGH     ;

reg  [15:0] R_SPD1_PLUSE           ;
reg  [15:0] R_SPD2_PLUSE           ;
reg  [15:0] R_SPD3_PLUSE           ;
reg  [15:0] R_SPD4_PLUSE           ;
reg  [15:0] R_SPD5_PLUSE           ;
reg  [15:0] R_SPD6_PLUSE           ;
reg  [5:0]  R_SPD_MODE             ;
reg  [5:0]  R_limited_Pluse_finished;
reg  [12:0] R_SPD_LOAD             ;
reg  [12:0] R_OUTPUT_CONTROL       ;
reg  [2:0]  R_CD_TI_OUTPUT         ;

reg  [1:0]  R_IO_OUTPUT            ;
reg  [1:0]  R_IO_LED               ;

reg  [15:0] R_SPD1_INIT_PULSE_LOW;
reg  [15:0] R_SPD1_INIT_PULSE_HIGH;
reg  [15:0] R_SPD2_INIT_PULSE_LOW;
reg  [15:0] R_SPD2_INIT_PULSE_HIGH;
reg  [15:0] R_SPD3_INIT_PULSE_LOW;
reg  [15:0] R_SPD3_INIT_PULSE_HIGH;

reg  [15:0] R_SPD4_INIT_PULSE_LOW;
reg  [15:0] R_SPD4_INIT_PULSE_HIGH;
reg  [15:0] R_SPD5_INIT_PULSE_LOW;
reg  [15:0] R_SPD5_INIT_PULSE_HIGH;
reg  [15:0] R_SPD6_INIT_PULSE_LOW;
reg  [15:0] R_SPD6_INIT_PULSE_HIGH;

reg [15:0] R_SPI_SELECT           ;

assign O_io = 25'h0;
// assign O_io[24] = O_ld_dir;
// assign O_io[23] = R_I_lcs_n;
// assign O_io[22] = O_rs485_de;
// assign O_io[21] = W_reset_n;
// assign O_io[20] = I_lclk;
// assign O_io[19] = I_la[11];
// assign O_io[18] = I_la[10];
// assign O_io[17] = I_la[9];
// assign O_io[16] = I_la[8];
// assign O_io[15] = I_la[7];
// assign O_io[14] = I_la[6];
// assign O_io[13] = I_la[5];
// assign O_io[12] = I_la[4];
// assign O_io[11] = I_la[3];
// assign O_io[10] = I_la[2];
// assign O_io[9] = I_la[1];
// assign O_io[8] = I_la[0];
// assign O_io[7] = IO_ld[0];
// assign O_io[6] = IO_ld[1];
// assign O_io[5] = IO_ld[2];
// assign O_io[4] = IO_ld[3];
// assign O_io[3] = IO_ld[4];
// assign O_io[2] = IO_ld[5];
// assign O_io[1] = IO_ld[6];
// assign O_io[0] = IO_ld[7];

//--------------------DIR & OE--------------------------
assign O_la_dir = 1'b1;
assign O_la_oe_n = 1'b0;
assign O_ld_dir = !((!R_I_lcs_n) & (!I_lrd_n)); // 1-input; 0-output
// assign O_ld_oe_n = 1'b0;
assign O_ld_oe_n = (W_localbus_addr[11:8] == 4'b1000)? 1'b0: 1'b1;  // 0x8xx is fpga local bus

//-------------------btm and ti-----------------------------
assign     O_btm_cd1           =        !R_CD_TI_OUTPUT[0]; // 1-OFF; 0-ON
assign     O_btm_cd2           =        !R_CD_TI_OUTPUT[1]; // 1-OFF; 0-ON
assign     O_ti_lock           =        R_CD_TI_OUTPUT[2]; // 1-valid tag; 0-invalid tag
// assign     O_ti_led            =        !R_CD_TI_OUTPUT[2]; // 1-OFF; 0-ON

//-------------------doppler rader-----------------------------
assign     O_dop_pwm           =        (R_OUTPUT_CONTROL[12] & W_O_dop_pwm);

//-------------------tachometer-----------------------------
assign     O_spd1_ch[0]        =        (R_OUTPUT_CONTROL[0] & W_O_normal_spd1 )  ;
assign     O_spd1_ch[1]        =        (R_OUTPUT_CONTROL[1] & W_O_normal_spd2 )  ;
assign     O_spd1_ch[2]        =        (R_OUTPUT_CONTROL[2] & W_O_normal_spd3 )  ;
assign     O_spd1_ch[3]        =        (R_OUTPUT_CONTROL[3] & W_O_normal_spd4 )  ;
assign     O_spd1_ch[4]        =        (R_OUTPUT_CONTROL[4] & W_O_normal_spd5 )  ;
assign     O_spd1_ch[5]        =        (R_OUTPUT_CONTROL[5] & W_O_normal_spd6 )  ;

assign     O_spd2_ch[0]        =        (R_OUTPUT_CONTROL[6] & W_O_normal_spd7 )  ;
assign     O_spd2_ch[1]        =        (R_OUTPUT_CONTROL[7] & W_O_normal_spd8 )  ;
assign     O_spd2_ch[2]        =        (R_OUTPUT_CONTROL[8] & W_O_normal_spd9 )  ;
assign     O_spd2_ch[3]        =        (R_OUTPUT_CONTROL[9] & W_O_normal_spd10 ) ;
assign     O_spd2_ch[4]        =        (R_OUTPUT_CONTROL[10] & W_O_normal_spd11 ) ;
assign     O_spd2_ch[5]        =        (R_OUTPUT_CONTROL[11] & W_O_normal_spd12 ) ;

//-------------------output-----------------------------
assign O_out1 = (!R_CD_TI_OUTPUT[2]) & (!R_IO_OUTPUT[0]); // 1-OFF; 0-ON
assign O_out2 = !R_IO_OUTPUT[1]; // 1-OFF; 0-ON

//assign O_led1 = !R_IO_LED[0]; // 1-OFF; 0-ON
//assign O_led2 = !R_IO_LED[1]; // 1-OFF; 0-ON
assign O_led1 = !((R_OUTPUT_CONTROL[0] & W_O_normal_spd1 ) ) ;
assign O_led2 = !((R_OUTPUT_CONTROL[6] & W_O_normal_spd7 ) ) ;

//------------------------local bus rd&wr---------------------------------
assign IO_ld = ((!R_I_lcs_n) && (!(I_lrd_n&&R_I_lrd_n_2)) && (W_localbus_addr[11:8]==4'b1000))? W_reg_data_out: 16'hzzzz;
assign W_reg_data_out = R_FPGA_REG;
assign W_localbus_addr = I_la;

//---------------------MVB-----------------------
// NOTES: should modify local bus rd&wr
assign O_mvb_rst_n = W_reset_n;
assign O_mvb_lcs_n = (W_localbus_addr[11:8]==4'b0100)? 1'b0: 1'b1;

//---------------------CURRENT TACHOMETER-----------------------
assign O_cspd1_latch = ((!R_SPI_SELECT[0]) | I_spi_cs);
assign O_cspd1_clr = 1'b0;
assign O_cspd_ch[0] = (R_OUTPUT_CONTROL[0] & W_O_normal_spd1 );
assign O_cspd_ch[1] = (R_OUTPUT_CONTROL[1] & W_O_normal_spd2 );

//---------------------CURRENT LOOP-----------------------
assign O_spi_cl_cs_n = ((R_SPI_SELECT[0]) | I_spi_cs);

//---------------------RS485-----------------------
assign O_rs485_de = !(I_tx3);

//-----------------SOFT RESET-----------------------
// always@(posedge W_clk)
// begin
    // if(R_Reset_Cnt >= RESET_TIME_PARAMETER)
    // begin
        // W_reset_n  <= 1'b1;
    // end
    // else
    // begin
        // R_Reset_Cnt <= R_Reset_Cnt + 1'b1;
        // W_reset_n  <= 1'b0;
    // end
// end

//---------------------synchronization-----------------------
always @(posedge W_clk)
    begin
     if (!W_reset_n)
         begin  
            R_I_lcs_n           <=    1'b1  ;
            R_I_lwr_n           <=    1'b1  ;
            R_I_lrd_n           <=    1'b1  ;
            R_I_lcs_n_1         <=    1'b1  ;
            R_I_lwr_n_1         <=    1'b1  ;
            R_I_lrd_n_1         <=    1'b1  ;
            R_I_lrd_n_2         <=    1'b1  ;
        end
     else       
       begin
            R_I_lcs_n           <=    I_lcs_n  ;
            R_I_lwr_n           <=    I_lwr_n  ;
            R_I_lrd_n           <=    I_lrd_n  ;
            R_I_lcs_n_1         <=    R_I_lcs_n ;
            R_I_lwr_n_1         <=    R_I_lwr_n ;
            R_I_lrd_n_1         <=    R_I_lrd_n  ;
            R_I_lrd_n_2         <=    R_I_lrd_n_1 ;
      end          
    end

//-----------------Limited pulse finished flag--------------    
always @(negedge W_reset_n or posedge W_clk)
   begin                                                         
      if (!W_reset_n)
          begin
           R_limited_Pluse_finished     <=    6'b000000;
          end
      else
        begin
          R_limited_Pluse_finished[0]   <=    W_SPD_MODE[0];
          R_limited_Pluse_finished[1]   <=    W_SPD_MODE[1];
          R_limited_Pluse_finished[2]   <=    W_SPD_MODE[2];
          R_limited_Pluse_finished[3]   <=    W_SPD_MODE[3];
          R_limited_Pluse_finished[4]   <=    W_SPD_MODE[4];
          R_limited_Pluse_finished[5]   <=    W_SPD_MODE[5];
        end
  end

//-----------------Internal REG read & write-------------------         
always @(negedge W_reset_n or posedge W_clk)
    begin
      if (!W_reset_n)
          begin
             R_FPGA_REG                     <=   16'h0000;
             R_OUTPUT_CONTROL[12:0]         <=   12'b0_0000_0000_0000;
             R_CD_TI_OUTPUT[2:0]            <=   3'b000;
             R_SPD_MODE[5:0]                <=   6'b00_0000;
             R_SPD_LOAD[12:0]               <=   12'b0_0000_0000_0000;
             R_SPD1_FCONFIG_LOW  [15:0]     <=   16'h0000; 
             R_SPD1_FCONFIG_HIGH [15:0]     <=   16'h0000; 
             R_SPD2_FCONFIG_LOW  [15:0]     <=   16'h0000; 
             R_SPD2_FCONFIG_HIGH [15:0]     <=   16'h0000; 
             R_SPD3_FCONFIG_LOW  [15:0]     <=   16'h0000; 
             R_SPD3_FCONFIG_HIGH [15:0]     <=   16'h0000; 
             R_SPD4_FCONFIG_LOW  [15:0]     <=   16'h0000; 
             R_SPD4_FCONFIG_HIGH [15:0]     <=   16'h0000; 
             R_SPD5_FCONFIG_LOW  [15:0]     <=   16'h0000; 
             R_SPD5_FCONFIG_HIGH [15:0]     <=   16'h0000; 
             R_SPD6_FCONFIG_LOW  [15:0]     <=   16'h0000; 
             R_SPD6_FCONFIG_HIGH [15:0]     <=   16'h0000; 
             R_SPD1_PCONFIG_LOW  [15:0]     <=   16'h0000; 
             R_SPD1_PCONFIG_HIGH [15:0]     <=   16'h0000; 
             R_SPD2_PCONFIG_LOW  [15:0]     <=   16'h0000; 
             R_SPD2_PCONFIG_HIGH [15:0]     <=   16'h0000; 
             R_SPD3_PCONFIG_LOW  [15:0]     <=   16'h0000;
             R_SPD3_PCONFIG_HIGH [15:0]     <=   16'h0000; 
             R_SPD4_PCONFIG_LOW  [15:0]     <=   16'h0000;
             R_SPD4_PCONFIG_HIGH [15:0]     <=   16'h0000;
             R_SPD5_PCONFIG_LOW  [15:0]     <=   16'h0000;
             R_SPD5_PCONFIG_HIGH [15:0]     <=   16'h0000;
             R_SPD6_PCONFIG_LOW  [15:0]     <=   16'h0000; 
             R_SPD6_PCONFIG_HIGH [15:0]     <=   16'h0000; 
             R_SPD1_PLUSE[15:0]             <=   16'h0000 ;
             R_SPD2_PLUSE[15:0]             <=   16'h0000 ;
             R_SPD3_PLUSE[15:0]             <=   16'h0000 ;
             R_SPD4_PLUSE[15:0]             <=   16'h0000 ;
             R_SPD5_PLUSE[15:0]             <=   16'h0000 ;
             R_SPD6_PLUSE[15:0]             <=   16'h0000 ;

             R_DOP_FCONFIG_LOW   [15:0]     <=   16'h0000; 
             R_DOP_FCONFIG_HIGH  [15:0]     <=   16'h0000; 
             R_IO_OUTPUT[1:0]               <=   2'b00;
             R_IO_LED[1:0]                  <=   2'b00;
             
             R_SPD1_INIT_PULSE_LOW[15:0]  <=   16'h0000 ;
             R_SPD1_INIT_PULSE_HIGH[15:0] <=   16'h0000 ;
             R_SPD2_INIT_PULSE_LOW[15:0]  <=   16'h0000 ;
             R_SPD2_INIT_PULSE_HIGH[15:0] <=   16'h0000 ;
             R_SPD3_INIT_PULSE_LOW[15:0]  <=   16'h0000 ;
             R_SPD3_INIT_PULSE_HIGH[15:0] <=   16'h0000 ;

             R_SPD4_INIT_PULSE_LOW[15:0]  <=   16'h0000 ;
             R_SPD4_INIT_PULSE_HIGH[15:0] <=   16'h0000 ;
             R_SPD5_INIT_PULSE_LOW[15:0]  <=   16'h0000 ;
             R_SPD5_INIT_PULSE_HIGH[15:0] <=   16'h0000 ;
             R_SPD6_INIT_PULSE_LOW[15:0]  <=   16'h0000 ;
             R_SPD6_INIT_PULSE_HIGH[15:0] <=   16'h0000 ;
			 
			 R_SPI_SELECT[15:0]           <=   16'h0000 ;
          end
      else
          begin
            if  ((!R_I_lcs_n) && (!R_I_lrd_n)&&R_I_lrd_n_1)   //read  reg
             case(W_localbus_addr[11:0]) 
            
                FPGA_Ver_ADDR:                   R_FPGA_REG[15:0]         <=   FPGA_VER_CSR   ;
                DATA_AAAA_ADDR:                  R_FPGA_REG[15:0]         <=   16'haaaa   ;
                DATA_5555_ADDR:                  R_FPGA_REG[15:0]         <=   16'h5555   ;
                DATA_FFFF_ADDR:                  R_FPGA_REG[15:0]         <=   16'hffff   ;
                DATA_0000_ADDR:                  R_FPGA_REG[15:0]         <=   16'h0000   ;
                FPGA_OUTPUT_CONTROL_ADDR   :     R_FPGA_REG[15:0]         <=   {3'b000,R_OUTPUT_CONTROL[12:0]}  ;
                FPGA_CD_TI_OUTPUT_ADDR :         R_FPGA_REG[15:0]         <=   {13'b0000_0000_0000_0000_0,R_CD_TI_OUTPUT[2:0]}     ;
                FPGA_SPD_MODE_ADDR:              R_FPGA_REG[15:0]         <=   {10'b0000_0000_00,R_SPD_MODE[5:0]}      ;
                FPGA_SPD_LOAD_ADDR:              R_FPGA_REG[15:0]         <=   {3'b000,R_SPD_LOAD[12:0]}   ;
                FPGA_SPD1_FCONFIG_LOW_ADDR:      R_FPGA_REG[15:0]         <=   R_SPD1_FCONFIG_LOW  [15:0]  ;
                FPGA_SPD1_FCONFIG_HIGH_ADDR:     R_FPGA_REG[15:0]         <=   R_SPD1_FCONFIG_HIGH [15:0]  ;
                FPGA_SPD2_FCONFIG_LOW_ADDR:      R_FPGA_REG[15:0]         <=   R_SPD2_FCONFIG_LOW  [15:0]  ;
                FPGA_SPD2_FCONFIG_HIGH_ADDR:     R_FPGA_REG[15:0]         <=   R_SPD2_FCONFIG_HIGH [15:0]  ;
                FPGA_SPD3_FCONFIG_LOW_ADDR :     R_FPGA_REG[15:0]         <=   R_SPD3_FCONFIG_LOW  [15:0]  ;
                FPGA_SPD3_FCONFIG_HIGH_ADDR:     R_FPGA_REG[15:0]         <=   R_SPD3_FCONFIG_HIGH [15:0]  ;
                FPGA_SPD4_FCONFIG_LOW_ADDR :     R_FPGA_REG[15:0]         <=   R_SPD4_FCONFIG_LOW  [15:0]  ;
                FPGA_SPD4_FCONFIG_HIGH_ADDR:     R_FPGA_REG[15:0]         <=   R_SPD4_FCONFIG_HIGH [15:0]  ;
                FPGA_SPD5_FCONFIG_LOW_ADDR :     R_FPGA_REG[15:0]         <=   R_SPD5_FCONFIG_LOW  [15:0]  ;
                FPGA_SPD5_FCONFIG_HIGH_ADDR:     R_FPGA_REG[15:0]         <=   R_SPD5_FCONFIG_HIGH [15:0]  ;
                FPGA_SPD6_FCONFIG_LOW_ADDR :     R_FPGA_REG[15:0]         <=   R_SPD6_FCONFIG_LOW  [15:0]  ;
                FPGA_SPD6_FCONFIG_HIGH_ADDR:     R_FPGA_REG[15:0]         <=   R_SPD6_FCONFIG_HIGH [15:0]  ;
                FPGA_SPD1_PCONFIG_LOW_ADDR :     R_FPGA_REG[15:0]         <=   R_SPD1_PCONFIG_LOW  [15:0]  ;
                FPGA_SPD1_PCONFIG_HIGH_ADDR:     R_FPGA_REG[15:0]         <=   R_SPD1_PCONFIG_HIGH [15:0]  ;
                FPGA_SPD2_PCONFIG_LOW_ADDR :     R_FPGA_REG[15:0]         <=   R_SPD2_PCONFIG_LOW  [15:0]  ;
                FPGA_SPD2_PCONFIG_HIGH_ADDR:     R_FPGA_REG[15:0]         <=   R_SPD2_PCONFIG_HIGH [15:0]  ;
                FPGA_SPD3_PCONFIG_LOW_ADDR :     R_FPGA_REG[15:0]         <=   R_SPD3_PCONFIG_LOW  [15:0]  ;
                FPGA_SPD3_PCONFIG_HIGH_ADDR:     R_FPGA_REG[15:0]         <=   R_SPD3_PCONFIG_HIGH [15:0]  ;             
                FPGA_SPD4_PCONFIG_LOW_ADDR :     R_FPGA_REG[15:0]         <=   R_SPD4_PCONFIG_LOW  [15:0]  ;             
                FPGA_SPD4_PCONFIG_HIGH_ADDR:     R_FPGA_REG[15:0]         <=   R_SPD4_PCONFIG_HIGH [15:0]  ;
                FPGA_SPD5_PCONFIG_LOW_ADDR :     R_FPGA_REG[15:0]         <=   R_SPD5_PCONFIG_LOW  [15:0]  ;
                FPGA_SPD5_PCONFIG_HIGH_ADDR:     R_FPGA_REG[15:0]         <=   R_SPD5_PCONFIG_HIGH [15:0]  ;
                FPGA_SPD6_PCONFIG_LOW_ADDR :     R_FPGA_REG[15:0]         <=   R_SPD6_PCONFIG_LOW  [15:0]  ;
                FPGA_SPD6_PCONFIG_HIGH_ADDR:     R_FPGA_REG[15:0]         <=   R_SPD6_PCONFIG_HIGH [15:0]  ;
                FPGA_DOP_FCONFIG_LOW_ADDR  :     R_FPGA_REG[15:0]         <=   R_DOP_FCONFIG_LOW   [15:0]  ;
                FPGA_DOP_FCONFIG_HIGH_ADDR :     R_FPGA_REG[15:0]         <=   R_DOP_FCONFIG_HIGH  [15:0]  ;
                FPGA_SPD1_PLUSE_ADDR:            R_FPGA_REG[15:0]         <=   R_SPD1_PLUSE[15:0]          ;
                FPGA_SPD2_PLUSE_ADDR:            R_FPGA_REG[15:0]         <=   R_SPD2_PLUSE[15:0]          ;
                FPGA_SPD3_PLUSE_ADDR:            R_FPGA_REG[15:0]         <=   R_SPD3_PLUSE[15:0]          ;
                FPGA_SPD4_PLUSE_ADDR:            R_FPGA_REG[15:0]         <=   R_SPD4_PLUSE[15:0]          ;
                FPGA_SPD5_PLUSE_ADDR:            R_FPGA_REG[15:0]         <=   R_SPD5_PLUSE[15:0]          ;
                FPGA_SPD6_PLUSE_ADDR:            R_FPGA_REG[15:0]         <=   R_SPD6_PLUSE[15:0]          ;
                FPGA_LIMITED_PULSE_FINISHED_ADDR:R_FPGA_REG[15:0]         <=   {10'b00_0000_0000,R_limited_Pluse_finished[5:0]}; // read only
                FPGA_IO_OUTPUT_ADDR:             R_FPGA_REG[15:0]         <=   {14'b00_0000_0000_0000_0000,R_IO_OUTPUT[1:0] }  ;
                FPGA_IO_LED_ADDR:                R_FPGA_REG[15:0]         <=   {14'b00_0000_0000_0000_0000,R_IO_LED[1:0]}      ;

                FPGA_SPD1_INIT_LOW_ADDR :     R_FPGA_REG[15:0]         <=   W_SPD1_REPORT_PULSE_LOW  [15:0]  ;             
                FPGA_SPD1_INIT_HIGH_ADDR:     R_FPGA_REG[15:0]         <=   W_SPD1_REPORT_PULSE_HIGH [15:0]  ;
                FPGA_SPD2_INIT_LOW_ADDR :     R_FPGA_REG[15:0]         <=   W_SPD2_REPORT_PULSE_LOW  [15:0]  ;             
                FPGA_SPD2_INIT_HIGH_ADDR:     R_FPGA_REG[15:0]         <=   W_SPD2_REPORT_PULSE_HIGH [15:0]  ;
                FPGA_SPD3_INIT_LOW_ADDR :     R_FPGA_REG[15:0]         <=   W_SPD3_REPORT_PULSE_LOW  [15:0]  ;             
                FPGA_SPD3_INIT_HIGH_ADDR:     R_FPGA_REG[15:0]         <=   W_SPD3_REPORT_PULSE_HIGH [15:0]  ;

                FPGA_SPD4_INIT_LOW_ADDR :     R_FPGA_REG[15:0]         <=   W_SPD4_REPORT_PULSE_LOW  [15:0]  ;             
                FPGA_SPD4_INIT_HIGH_ADDR:     R_FPGA_REG[15:0]         <=   W_SPD4_REPORT_PULSE_HIGH [15:0]  ;
                FPGA_SPD5_INIT_LOW_ADDR :     R_FPGA_REG[15:0]         <=   W_SPD5_REPORT_PULSE_LOW  [15:0]  ;             
                FPGA_SPD5_INIT_HIGH_ADDR:     R_FPGA_REG[15:0]         <=   W_SPD5_REPORT_PULSE_HIGH [15:0]  ;
                FPGA_SPD6_INIT_LOW_ADDR :     R_FPGA_REG[15:0]         <=   W_SPD6_REPORT_PULSE_LOW  [15:0]  ;             
                FPGA_SPD6_INIT_HIGH_ADDR:     R_FPGA_REG[15:0]         <=   W_SPD6_REPORT_PULSE_HIGH [15:0]  ;
				
				FPGA_SPI_SELECT_ADDR:         R_FPGA_REG[15:0]         <=   R_SPI_SELECT[15:0]               ;

               default:
                 begin 
                    R_FPGA_REG[15:0] <= R_FPGA_REG[15:0];
                 end
             endcase
           else if   ((!R_I_lcs_n) && (!R_I_lwr_n)&&R_I_lwr_n_1)   // write reg
           
                case(W_localbus_addr[11:0])
                   
                   FPGA_OUTPUT_CONTROL_ADDR:            R_OUTPUT_CONTROL[12:0]           <=         IO_ld[12:0]    ;
                   FPGA_CD_TI_OUTPUT_ADDR :             R_CD_TI_OUTPUT[2:0]              <=         IO_ld[2:0]     ;
                   FPGA_SPD_MODE_ADDR:                  R_SPD_MODE[5:0]                  <=         IO_ld[5:0]     ;
                   FPGA_SPD_LOAD_ADDR:                  R_SPD_LOAD[12:0]                 <=         IO_ld[12:0]    ;
                   FPGA_SPD1_FCONFIG_LOW_ADDR:          R_SPD1_FCONFIG_LOW  [15:0]       <=         IO_ld[15:0]    ;
                   FPGA_SPD1_FCONFIG_HIGH_ADDR:         R_SPD1_FCONFIG_HIGH [15:0]       <=         IO_ld[15:0]    ;
                   FPGA_SPD2_FCONFIG_LOW_ADDR:          R_SPD2_FCONFIG_LOW  [15:0]       <=         IO_ld[15:0]    ;
                   FPGA_SPD2_FCONFIG_HIGH_ADDR:         R_SPD2_FCONFIG_HIGH [15:0]       <=         IO_ld[15:0]    ;
                   FPGA_SPD3_FCONFIG_LOW_ADDR :         R_SPD3_FCONFIG_LOW  [15:0]       <=         IO_ld[15:0]    ;
                   FPGA_SPD3_FCONFIG_HIGH_ADDR:         R_SPD3_FCONFIG_HIGH [15:0]       <=         IO_ld[15:0]    ;
                   FPGA_SPD4_FCONFIG_LOW_ADDR :         R_SPD4_FCONFIG_LOW  [15:0]       <=         IO_ld[15:0]    ;
                   FPGA_SPD4_FCONFIG_HIGH_ADDR:         R_SPD4_FCONFIG_HIGH [15:0]       <=         IO_ld[15:0]    ;
                   FPGA_SPD5_FCONFIG_LOW_ADDR :         R_SPD5_FCONFIG_LOW  [15:0]       <=         IO_ld[15:0]    ;
                   FPGA_SPD5_FCONFIG_HIGH_ADDR:         R_SPD5_FCONFIG_HIGH [15:0]       <=         IO_ld[15:0]    ;
                   FPGA_SPD6_FCONFIG_LOW_ADDR :         R_SPD6_FCONFIG_LOW  [15:0]       <=         IO_ld[15:0]    ;
                   FPGA_SPD6_FCONFIG_HIGH_ADDR:         R_SPD6_FCONFIG_HIGH [15:0]       <=         IO_ld[15:0]    ;
                   FPGA_SPD1_PCONFIG_LOW_ADDR :         R_SPD1_PCONFIG_LOW  [15:0]       <=         IO_ld[15:0]    ;
                   FPGA_SPD1_PCONFIG_HIGH_ADDR:         R_SPD1_PCONFIG_HIGH [15:0]       <=         IO_ld[15:0]    ;
                   FPGA_SPD2_PCONFIG_LOW_ADDR :         R_SPD2_PCONFIG_LOW  [15:0]       <=         IO_ld[15:0]    ;
                   FPGA_SPD2_PCONFIG_HIGH_ADDR:         R_SPD2_PCONFIG_HIGH [15:0]       <=         IO_ld[15:0]    ;
                   FPGA_SPD3_PCONFIG_LOW_ADDR :         R_SPD3_PCONFIG_LOW  [15:0]       <=         IO_ld[15:0]    ;
                   FPGA_SPD3_PCONFIG_HIGH_ADDR:         R_SPD3_PCONFIG_HIGH [15:0]       <=         IO_ld[15:0]    ;
                   FPGA_SPD4_PCONFIG_LOW_ADDR :         R_SPD4_PCONFIG_LOW  [15:0]       <=         IO_ld[15:0]    ;
                   FPGA_SPD4_PCONFIG_HIGH_ADDR:         R_SPD4_PCONFIG_HIGH [15:0]       <=         IO_ld[15:0]    ;
                   FPGA_SPD5_PCONFIG_LOW_ADDR :         R_SPD5_PCONFIG_LOW  [15:0]       <=         IO_ld[15:0]    ;
                   FPGA_SPD5_PCONFIG_HIGH_ADDR:         R_SPD5_PCONFIG_HIGH [15:0]       <=         IO_ld[15:0]    ;
                   FPGA_SPD6_PCONFIG_LOW_ADDR :         R_SPD6_PCONFIG_LOW  [15:0]       <=         IO_ld[15:0]    ;
                   FPGA_SPD6_PCONFIG_HIGH_ADDR:         R_SPD6_PCONFIG_HIGH [15:0]       <=         IO_ld[15:0]    ;
                   FPGA_DOP_FCONFIG_LOW_ADDR  :         R_DOP_FCONFIG_LOW   [15:0]       <=         IO_ld[15:0]    ;
                   FPGA_DOP_FCONFIG_HIGH_ADDR :         R_DOP_FCONFIG_HIGH  [15:0]       <=         IO_ld[15:0]    ;
                   FPGA_SPD1_PLUSE_ADDR:                R_SPD1_PLUSE[15:0]               <=         IO_ld[15:0]    ;
                   FPGA_SPD2_PLUSE_ADDR:                R_SPD2_PLUSE[15:0]               <=         IO_ld[15:0]    ;
                   FPGA_SPD3_PLUSE_ADDR:                R_SPD3_PLUSE[15:0]               <=         IO_ld[15:0]    ;
                   FPGA_SPD4_PLUSE_ADDR:                R_SPD4_PLUSE[15:0]               <=         IO_ld[15:0]    ;
                   FPGA_SPD5_PLUSE_ADDR:                R_SPD5_PLUSE[15:0]               <=         IO_ld[15:0]    ;
                   FPGA_SPD6_PLUSE_ADDR:                R_SPD6_PLUSE[15:0]               <=         IO_ld[15:0]    ;
                   FPGA_IO_OUTPUT_ADDR:                 R_IO_OUTPUT[1:0]                 <=         IO_ld[1:0]     ;
                   FPGA_IO_LED_ADDR:                    R_IO_LED[1:0]                    <=         IO_ld[1:0]     ;

                   FPGA_SPD1_INIT_LOW_ADDR :         R_SPD1_INIT_PULSE_LOW  [15:0]       <=         IO_ld[15:0]    ;
                   FPGA_SPD1_INIT_HIGH_ADDR:         R_SPD1_INIT_PULSE_HIGH [15:0]       <=         IO_ld[15:0]    ;
                   FPGA_SPD2_INIT_LOW_ADDR :         R_SPD2_INIT_PULSE_LOW  [15:0]       <=         IO_ld[15:0]    ;
                   FPGA_SPD2_INIT_HIGH_ADDR:         R_SPD2_INIT_PULSE_HIGH [15:0]       <=         IO_ld[15:0]    ;
                   FPGA_SPD3_INIT_LOW_ADDR :         R_SPD3_INIT_PULSE_LOW  [15:0]       <=         IO_ld[15:0]    ;
                   FPGA_SPD3_INIT_HIGH_ADDR:         R_SPD3_INIT_PULSE_HIGH [15:0]       <=         IO_ld[15:0]    ;

                   FPGA_SPD4_INIT_LOW_ADDR :         R_SPD4_INIT_PULSE_LOW  [15:0]       <=         IO_ld[15:0]    ;
                   FPGA_SPD4_INIT_HIGH_ADDR:         R_SPD4_INIT_PULSE_HIGH [15:0]       <=         IO_ld[15:0]    ;
                   FPGA_SPD5_INIT_LOW_ADDR :         R_SPD5_INIT_PULSE_LOW  [15:0]       <=         IO_ld[15:0]    ;
                   FPGA_SPD5_INIT_HIGH_ADDR:         R_SPD5_INIT_PULSE_HIGH [15:0]       <=         IO_ld[15:0]    ;
                   FPGA_SPD6_INIT_LOW_ADDR :         R_SPD6_INIT_PULSE_LOW  [15:0]       <=         IO_ld[15:0]    ;
                   FPGA_SPD6_INIT_HIGH_ADDR:         R_SPD6_INIT_PULSE_HIGH [15:0]       <=         IO_ld[15:0]    ;
				   
				   FPGA_SPI_SELECT_ADDR:             R_SPI_SELECT[15:0]                  <=         IO_ld[15:0]    ;
                   default:
                    begin
                        R_FPGA_REG[15:0] <= R_FPGA_REG[15:0];
                    end 
                endcase
                
                else
                    begin
                       R_FPGA_REG[15:0] <= R_FPGA_REG[15:0];
                    end
              end
    end

// 时钟信号和复位信号增加全局Buffer
wire clk_buf, rst_n_buf;
INBUF   i_INBUF1(.PAD(clock),.Y(clk_buf));
CLKINT  i_CLKINT1(.A(clk_buf),.Y(W_clk));
INBUF   i_INBUF2(.PAD(I_rst_n),.Y(rst_n_buf));
CLKINT  i_CLKINT2(.A(rst_n_buf),.Y(W_reset_n));
//CLKINT  i_CLKINT2(.A(rst_n_buf),.Y(W_reset_n_n));

//-----------------------------freq_dop----------------------------------
freq_dop module_freq_dop(
     .I_reset_n (W_reset_n),
     .I_clk   (W_clk),
     .I_freq    ({R_DOP_FCONFIG_HIGH[15:0],R_DOP_FCONFIG_LOW[15:0]}),
     .I_load    (R_SPD_LOAD[12]),
     .I_stat    (R_OUTPUT_CONTROL[12]),
	 .O_spd     (W_O_dop_pwm)
      ); 

//-----------------------------freq_output12_normal-----------------------
freq module_freq1(
     .I_reset_n (W_reset_n),
     .I_clk   (W_clk),
     .I_freq    ({R_SPD1_FCONFIG_HIGH[15:0],R_SPD1_FCONFIG_LOW[15:0]}),
     .I_pha     ({R_SPD1_PCONFIG_HIGH[15:0],R_SPD1_PCONFIG_LOW[15:0]}),
     .I_load    (R_SPD_LOAD[1:0]), 
     .I_stat    (R_OUTPUT_CONTROL[0] | R_OUTPUT_CONTROL[1]),
     .I_pluse_number (R_SPD1_PLUSE[15:0]), 
     .I_limited_Pluse(R_SPD_MODE[0]), 
     .I_init_pulse({R_SPD1_INIT_PULSE_HIGH[15:0],R_SPD1_INIT_PULSE_LOW[15:0]}),
	 .O_spd1    (W_O_normal_spd1),
     .O_spd2    (W_O_normal_spd2),
     .O_report_pulse({W_SPD1_REPORT_PULSE_HIGH[15:0],W_SPD1_REPORT_PULSE_LOW[15:0]}),
     .O_limited_Pluse_finished(W_SPD_MODE[0])
      );

//-----------------------------freq_output34_normal-----------------------
freq module_freq2(
     .I_reset_n (W_reset_n),
     .I_clk   (W_clk),
     .I_freq    ({R_SPD2_FCONFIG_HIGH[15:0],R_SPD2_FCONFIG_LOW[15:0]}),
     .I_pha     ({R_SPD2_PCONFIG_HIGH[15:0],R_SPD2_PCONFIG_LOW[15:0]}),
     .I_load    (R_SPD_LOAD[3:2]), 
     .I_stat    (R_OUTPUT_CONTROL[2] | R_OUTPUT_CONTROL[3]),
     .I_pluse_number (R_SPD2_PLUSE[15:0]), 
     .I_limited_Pluse(R_SPD_MODE[1]), 
     .I_init_pulse({R_SPD2_INIT_PULSE_HIGH[15:0],R_SPD2_INIT_PULSE_LOW[15:0]}),
	 .O_spd1    (W_O_normal_spd3),
     .O_spd2    (W_O_normal_spd4),
     .O_report_pulse({W_SPD2_REPORT_PULSE_HIGH[15:0],W_SPD2_REPORT_PULSE_LOW[15:0]}),
     .O_limited_Pluse_finished(W_SPD_MODE[1])
      );

//-----------------------------freq_output56_normal-----------------------
freq module_freq3(
     .I_reset_n (W_reset_n),
     .I_clk   (W_clk),
     .I_freq    ({R_SPD3_FCONFIG_HIGH[15:0],R_SPD3_FCONFIG_LOW[15:0]}),
     .I_pha     ({R_SPD3_PCONFIG_HIGH[15:0],R_SPD3_PCONFIG_LOW[15:0]}),
     .I_load    (R_SPD_LOAD[5:4]), 
     .I_stat    (R_OUTPUT_CONTROL[4] | R_OUTPUT_CONTROL[5]),
     .I_pluse_number (R_SPD3_PLUSE[15:0]), 
     .I_limited_Pluse(R_SPD_MODE[2]), 
     .I_init_pulse({R_SPD3_INIT_PULSE_HIGH[15:0],R_SPD3_INIT_PULSE_LOW[15:0]}),
	 .O_spd1    (W_O_normal_spd5),
     .O_spd2    (W_O_normal_spd6),
     .O_report_pulse({W_SPD3_REPORT_PULSE_HIGH[15:0],W_SPD3_REPORT_PULSE_LOW[15:0]}),
     .O_limited_Pluse_finished(W_SPD_MODE[2])
      );

//-----------------------------freq_output78_normal-----------------------
freq module_freq4(
     .I_reset_n (W_reset_n),
     .I_clk   (W_clk),
     .I_freq    ({R_SPD4_FCONFIG_HIGH[15:0],R_SPD4_FCONFIG_LOW[15:0]}),
     .I_pha     ({R_SPD4_PCONFIG_HIGH[15:0],R_SPD4_PCONFIG_LOW[15:0]}),
     .I_load    (R_SPD_LOAD[7:6]), 
     .I_stat    (R_OUTPUT_CONTROL[6] | R_OUTPUT_CONTROL[7]),
     .I_pluse_number (R_SPD4_PLUSE[15:0]), 
     .I_limited_Pluse(R_SPD_MODE[3]), 
     .I_init_pulse({R_SPD4_INIT_PULSE_HIGH[15:0],R_SPD4_INIT_PULSE_LOW[15:0]}),
	 .O_spd1    (W_O_normal_spd7),
     .O_spd2    (W_O_normal_spd8),
     .O_report_pulse({W_SPD4_REPORT_PULSE_HIGH[15:0],W_SPD4_REPORT_PULSE_LOW[15:0]}),
     .O_limited_Pluse_finished(W_SPD_MODE[3])
      );

//-----------------------------freq_output910_normal-----------------------
freq module_freq5(
     .I_reset_n (W_reset_n),
     .I_clk   (W_clk),
     .I_freq    ({R_SPD5_FCONFIG_HIGH[15:0],R_SPD5_FCONFIG_LOW[15:0]}),
     .I_pha     ({R_SPD5_PCONFIG_HIGH[15:0],R_SPD5_PCONFIG_LOW[15:0]}),
     .I_load    (R_SPD_LOAD[9:8]), 
     .I_stat    (R_OUTPUT_CONTROL[8] | R_OUTPUT_CONTROL[9]),
     .I_pluse_number (R_SPD5_PLUSE[15:0]), 
     .I_limited_Pluse(R_SPD_MODE[4]), 
     .I_init_pulse({R_SPD5_INIT_PULSE_HIGH[15:0],R_SPD5_INIT_PULSE_LOW[15:0]}),
	 .O_spd1    (W_O_normal_spd9),
     .O_spd2    (W_O_normal_spd10),
     .O_report_pulse({W_SPD5_REPORT_PULSE_HIGH[15:0],W_SPD5_REPORT_PULSE_LOW[15:0]}),
     .O_limited_Pluse_finished(W_SPD_MODE[4])
      );

//-----------------------------freq_output1112_normal-----------------------
freq module_freq6(
     .I_reset_n (W_reset_n),
     .I_clk   (W_clk),
     .I_freq    ({R_SPD6_FCONFIG_HIGH[15:0],R_SPD6_FCONFIG_LOW[15:0]}),
     .I_pha     ({R_SPD6_PCONFIG_HIGH[15:0],R_SPD6_PCONFIG_LOW[15:0]}),
     .I_load    (R_SPD_LOAD[11:10]), 
     .I_stat    (R_OUTPUT_CONTROL[10] | R_OUTPUT_CONTROL[11]),
     .I_pluse_number (R_SPD6_PLUSE[15:0]), 
     .I_limited_Pluse(R_SPD_MODE[5]), 
     .I_init_pulse({R_SPD6_INIT_PULSE_HIGH[15:0],R_SPD6_INIT_PULSE_LOW[15:0]}),
	 .O_spd1    (W_O_normal_spd11),
     .O_spd2    (W_O_normal_spd12),
     .O_report_pulse({W_SPD6_REPORT_PULSE_HIGH[15:0],W_SPD6_REPORT_PULSE_LOW[15:0]}),
     .O_limited_Pluse_finished(W_SPD_MODE[5])
      );

//----------------------flash led------------------------           
led module_led(
    .I_reset_n(W_reset_n),
	.I_clk(W_clk),
	.O_led(O_ti_led)
	);

endmodule