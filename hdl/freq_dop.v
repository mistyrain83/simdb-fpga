/** 
 * \brief doppler rader frequency module
 * \copyright 1999-2013, Zhejiang United Electronic Industry Co.,Ltd.
 * \author   Qixb
 * \file     freq_dop.v
 * 
 *
 * please reference to docs.
 * \note : I_clk is 25MHz.
 * 
 * \version :V1.0
 * \date :2014-03-29 Qixb
 * \description :init file.
 *
 */

`timescale 1ns/100ps
module freq_dop(
     input            I_reset_n,
     input            I_clk,
     input    [31:0]  I_freq,
     input            I_load,    // load cmd, positive edge valid
     input            I_stat,    // enable cmd, active high
     
     output           O_spd
);

reg [27:0] R_count;  // freq counter
reg [27:0] R_I_freq;

reg R_load1;
reg R_load2;
reg R_load3;
reg R_load;
reg R_load_flag;

reg R_spd;

//-------------------------------------------------------------
always @(negedge I_reset_n or posedge I_clk)   
    begin                     
       if (!I_reset_n)                 
            begin                             
               R_count     <= 28'b0;
               R_I_freq    <= 28'b0;
               R_load1     <= 1'b0;
               R_load2     <= 1'b0;
               R_load3     <= 1'b0;
               R_load      <= 1'b0;
               R_load_flag <= 1'b0;
			   R_spd       <= 1'b0;
            end
       else //if(I_stat == 1)          
            begin   
                 R_load1    <= I_load;
                 R_load2    <= R_load1;
                 R_load3    <= R_load2;
                 R_load     <= !R_load3&R_load1;  // check positive edge
                 R_count    <= R_count + 1'b1;
				 
                 if( R_load&(!R_load_flag) )
                   begin
                     R_load_flag <= 1'b1;
                   end
                                         
                          
                 if(R_load_flag)
                     begin                                             	
                        R_I_freq [27:0]  <= I_freq[27:0]; 
                        R_count <= 0;  
                        R_load_flag             <=0;                                           
                     end
                 
                
                 if(I_freq == 0)   
                    begin
                      R_spd <= 1'b1;
                    end
                else if (R_count[27:0] == R_I_freq[27:1])  // half of freq register
                    begin
                        R_spd   <= !R_spd; 
                        R_count <= 0;                   
                    end            
                else
                    begin       
                     R_spd      <= R_spd;
                   end
             end 
         // else
            // begin
               // R_I_freq   <= 0;
               // R_count    <= 0;
               // R_spd      <= 1'b0; 
            // end                                                
    end
//----------------------------------------------------
assign  O_spd      =     R_spd;

endmodule