library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.Numeric_Std.all;

entity PWM_master is
	--generic(
			--CLK_FREQ	: integer := 8_000_000; --CHANGE
			--PWM_FREQ	: integer := 10_000;	--pwm switching freq
			--DUTY_RES 	: integer := 8);		
	port(
			i_clk		: in std_logic;	
			i_rst	 	: in std_logic;	
			i_tx_ena	: in std_logic;
			i_duty_we	: in std_logic;			
			
			i_pwm_div	: in unsigned(15 downto 0); --how many clock cycles are in one pwm period
			i_duty		: in unsigned(15 downto 0); -- how many clock cycles are in one high output
			--real duty in % = i_duty/i_pwm_div
			--if pwm_div_freq is equal or lower than pwm_duty then o_pwm = 1
			-- pwm period = i_pwm_div/freq
			o_pwm	 	: out std_logic);	
end PWM_master;

architecture Behavioral of PWM_master is
	--constant period		 			:natural := CLK_FREQ/PWM_FREQ;		
	signal	count						:unsigned(15 downto 0) := (others=>'0');		
	signal	half_duty, half_duty_new	:unsigned(15 downto 0) := (others=>'0');		
begin
	process(i_clk, i_rst)
	begin
		if(i_rst = '1') then																								
			count <= to_unsigned(0, 16);																		
			o_pwm <= '0';											
		elsif rising_edge(i_clk) then
			if(i_duty_we = '1') then			 --read new duty cycle
				--half_duty_new <= conv_integer(i_duty)*period/(2**DUTY_RES)/2;
				half_duty_new <= i_duty;
			end if;	
			if i_tx_ena = '1' then
				--counting
				if(count = i_pwm_div-1) then	
					count <= to_unsigned(0, 16);	
					half_duty <= half_duty_new;
					--o_pwm <= '1';
				else	
					count <= count + 1;
				end if;	
				
				if count = 0 then
					o_pwm <= '1';	
				end if;
				if count = half_duty then
					o_pwm <= '0';
				end if;
				--output
			
				--elsif(count = i_pwm_div - half_duty) then	
					--o_pwm <= '1';	
				
				
			else 
				o_pwm <= '0';	
				count <= to_unsigned(0, 16);
			end if;
		end if;
	end process;
end Behavioral;


