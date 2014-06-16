/** 
 * \brief led flash
 * \copyright 1999-2013, Zhejiang United Electronic Industry Co.,Ltd.
 * \author   Qixb
 * \file     led.v
 * 
 *
 * \note : I_clk is 25MHz.
 * 
 * \version :V1.0
 * \date :2014-03-29 Qixb
 * \description : init file.
 *
 * \version :V1.2
 * \date :2014-05-02 Qixb
 * \description : .
 *
 */

`timescale 1ns/100ps
module led(
     input            I_reset_n,
     input            I_clk,
     output           O_led
);
    parameter T1000MS = 25000000;  // 25M Clock, debug led timeout 1s
    
    reg [25:0] R_cnt;    // conter
    reg R_led;

    assign O_led = R_led;

    always@(posedge I_clk or negedge I_reset_n)
    begin 
         if(!I_reset_n)
         begin   
           R_cnt <= 26'b0;
           R_led <= 1'b0;
         end 
         else if(R_cnt >= T1000MS)
         begin
            R_led <= !R_led;
            R_cnt <= 26'b0;
         end
         else
         begin
            R_cnt <= R_cnt + 1'b1;
         end
    end

endmodule