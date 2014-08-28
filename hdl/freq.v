/** 
 * \brief techometer frequency module
 * \copyright 1999-2013, Zhejiang United Electronic Industry Co.,Ltd.
 * \author   Qixb
 * \file     freq.v
 * 
 *
 * please reference to docs.
 * \note : I_clk is 25MHz.
 * 
 * \version :V1.0
 * \date :2014-03-29 Qixb
 * \description :init file.
 *
 * \version :V1.1
 * \date :2014-05-05 Qixb
 * \description : fixed R_Spd2's 1/4 pulse.
 *
 * \version :V1.2
 * \date :2014-05-17 Qixb
 * \description : fixed Pluse1,2 difference frequency.
 *
 * \version :V1.3
 * \date :2014-07-08 Qixb
 * \description : modify limited-mode pulse to (pulse + 1).
 *
 * \version :V1.4
 * \date :2014-07-23 Qixb
 * \description : modify O_report_pulse can dec.
 */

`timescale 1ns/100ps
module freq(
     input            I_reset_n,
     input            I_clk,
     input    [31:0]  I_freq,      // frequency config
     input    [31:0]  I_pha,       // phase config
     input    [1:0]   I_load,      // load register cmd, positive-edge valid
     input            I_stat,      // enable cmd, active high
     input    [15:0]  I_pluse_number,  // pluse number when in limited mode
     input            I_limited_Pluse, // pulse mode config 
     input    [31:0]  I_init_pulse,    // init pulse config 
     
     output           O_spd1,      // channel 1 frequency 
     output           O_spd2,      // channel 2 frequency 
     output  [31:0]   O_report_pulse,  // pulse counts 
     output           O_limited_Pluse_finished  // finished flag when in limited mode 
   );

   reg            R_spd1;
   reg            R_spd2;
   reg            R_spd2_p1;   // reflect of R_spd2

   reg [27:0]     R_I_freq;    // frequency config 
   reg [30:0]     R_I_pha;     // phase config
 
   reg            R_load_pulse1;
   reg            R_load_pulse2;
   reg            R_load_pulse3;
   reg            R_load_pulse;       // load init_pulse
   
   reg            R_load1;
   reg            R_load2;
   reg            R_load3;
   reg            R_load;             // load register
   
   reg            R_load_pulse_flag;  // load init_pulse
   reg            R_load_flag;        // load register (freq and pha register)
   reg            R_dir;              // tachometer director flag
   
   reg            R_O_spd1 ;
   reg            R_O_spd2 ;
   reg [16:0]     R_pluse_number;     // pluse number when in limited mode
 
   reg [28:0]     cnt;
   reg [7:0]      R_spd_cnt;
   reg [31:0]     R_pulse_cnt;  // report pulse counter
   
   //----------------------------------------------------------
   always @(negedge I_reset_n or posedge I_clk)   
   begin                     
      if (!I_reset_n)   
      begin
         R_spd1        <= 1'b0;
         R_spd2        <= 1'b0;
	 R_spd2_p1     <= 1'b0;
         
         R_I_freq      <= 28'b0;
         R_I_pha       <= 31'b0;
         
         R_load_pulse1 <= 1'b0;
         R_load_pulse2 <= 1'b0;
         R_load_pulse3 <= 1'b0;
         R_load_pulse  <= 1'b0;
         
         R_load1                <= 1'b0;
         R_load2                <= 1'b0;
         R_load3                <= 1'b0;
         R_load                 <= 1'b0;
         
         R_load_pulse_flag      <= 1'b0;
         R_load_flag            <= 1'b0;
         R_dir                  <= 1'b0;
         
         R_O_spd1               <=0;
         R_O_spd2               <=0;
         R_pluse_number         <= 17'h1fffe;  // is non-limited mode
         
         cnt                    <= 29'b0;
	 R_spd_cnt              <= 8'b0;
         R_pulse_cnt            <= 32'b0; 
      end                           
      else        
      begin
          R_load_pulse1 <= I_load[1];
          R_load_pulse2 <= R_load_pulse1;
          R_load_pulse3 <= R_load_pulse2;
          R_load_pulse  <= !R_load_pulse3&R_load_pulse2;  // check positive edge
          
          R_load1       <= I_load[0];
          R_load2       <= R_load1;
          R_load3       <= R_load2;
          R_load        <= !R_load3&R_load2;  // check positive edge
	  
	  R_spd2_p1     <= R_spd2;
	  
       
         // load freq and pha register
         if( R_load & (!R_load_flag))
           begin
            R_load_flag <= 1'b1;         
           end
         
         // load init pulse register
         if( R_load_pulse & (!R_load_pulse_flag))
           begin
            R_load_pulse_flag <= 1'b1;         
           end
        
        // comments "R_dir = 0 : spd1 > spd2; R_dir = 1 : spd2 > spd1"
        if(!R_dir)
         begin
         R_O_spd1      <=  R_spd1  ;
         R_O_spd2      <=  R_spd2  ;
         end
        else
         begin
         R_O_spd1      <=  R_spd2  ;
         R_O_spd2      <=  R_spd1  ;
         end

        
        // load init pulse to pulse counter
        if(R_load_pulse_flag)
            begin
            R_pulse_cnt[31:0]       <= I_init_pulse[31:0];
            R_load_pulse_flag       <= 1'b0;
            end
        
        if(I_stat == 1) 
         begin
            cnt    <=  cnt + 1;
			
            if(R_I_freq == 0)
              begin
               R_spd1  <= 1'b0;
               R_spd2  <= 1'b0;
              end
            else 
            begin
                if(cnt[27:0]  ==  R_I_freq[27:1])
                  begin
                    R_spd2    <=  !R_spd2;
                    cnt       <=  29'b0;
                  end
				
         		if(R_I_pha[26:0] == 0)
				  begin
				    if((R_spd2 == 1) && (R_spd2_p1 == 0))
					  begin
					    R_spd_cnt <= R_spd_cnt + 1;
					  end
					
					// multiple frequency if PHA is 0
					if(R_spd_cnt == 2)
					  begin
						R_spd1 <= !R_spd1;
						R_spd_cnt <= 8'h00;
					  end
				  end
				else
				  begin
                  if (cnt == R_I_pha[27:0])
                    begin
                      R_spd1    <=  !R_spd1;
                    
					  // pulse counter addition
                      if(R_spd1 == 1'b1)
                        begin
						  if(R_dir == 1'b0)
						  begin
							R_pulse_cnt <= R_pulse_cnt + 1'b1;
						  end
						  else // (R_dir == 1'b1)
						  begin
							R_pulse_cnt <= R_pulse_cnt - 1'b1;
						  end
                        end
                    
					  // in limited mode
                      //if((R_pluse_number != 0) && (R_pluse_number != 17'h1fffe))
					  if((R_pluse_number != 0) && (I_limited_Pluse == 1'b1))
					    begin
                          R_pluse_number      <=    R_pluse_number - 1'b1;
					    end
                    end
				  end
            end

            // R_load valid
            if  ((R_load_flag&(I_freq[27:1] <= cnt[26:0])) | (R_load_flag&(R_I_freq[27:0] == 0)))
                begin
                if((R_I_freq == 0) | (I_freq == 0))
                    begin
                    R_spd1          <= 1'b1;
                    R_spd2          <= 1'b1;  
                    cnt             <= 29'b0;
                    R_I_pha[30:0]   <= I_pha[30:0];
                    R_dir           <= I_pha[31];
                    R_I_freq[27:0]  <= I_freq[27:0];
                    R_load_flag     <= 1'b0;
                    end 
                
                if (I_limited_Pluse)
                 begin
                  R_pluse_number[16:1]      <= I_pluse_number[15:0] + 1; 
                 end
                else
                 begin
                  R_pluse_number            <= 17'h1fffe; 
                 end

                if((cnt >= (R_I_pha[27:0] + R_I_pha[27:0])) & (R_I_freq[27:0] != 0))
                  begin                 
                  R_spd2                  <= !R_spd2;                                
                  cnt                     <= 27'b0;                
                  R_I_pha[30:0]           <= I_pha[30:0];
                  R_dir                   <= I_pha[31];
                  R_I_freq[27:0]          <= I_freq[27:0];
                  R_load_flag             <= 1'b0;
                  end
                  
              end    
             else if(R_load_flag & (cnt==0) & (R_I_freq[27:0] != 0))
                begin
                  if(I_freq == 0)
                    begin
                      R_spd1  <= 1'b1;
                      R_spd2  <= 1'b1;               
                    end
				  // if limited pulse mode
                  if (I_limited_Pluse)
                    begin
                       R_pluse_number[16:1]      <= I_pluse_number[15:0] + 1;
                    end
                  else
                   begin
                       R_pluse_number            <= 17'h1fffe;
                   end
                   
                  R_I_pha[30:0]           <= I_pha[30:0];
                  R_dir                   <= I_pha[31];
                  R_I_freq[27:0]          <= I_freq[27:0];
                  R_load_flag             <= 1'b0;
                end
              end
            else
              begin          
              R_spd1                 <= 1'b1;
              R_spd2                 <= 1'b1;
              cnt                    <= 29'b0;
              R_pulse_cnt            <= 32'b0;
              end               
      end
   end
//----------------------------------------------------------------------
   assign  O_spd1      =  (R_pluse_number == 0)? ((R_dir == 1'b0)? 0:1) : R_O_spd1;
   assign  O_spd2      =  (R_pluse_number == 0)? ((R_dir == 1'b0)? 1:0) : R_O_spd2;
   assign  O_report_pulse[31:0] = R_pulse_cnt[31:0];
   // if 1, pulse is over in limited mode
   assign  O_limited_Pluse_finished = (R_pluse_number == 0)? 1:0;
endmodule