library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.Numeric_Std.all;
use work.INTERFACE_regs.ALL;

entity PWM_module is
	Port(
        i_clk			: in std_logic;				
		i_rst	 		: in std_logic;	
		i_interupt : 	in std_logic;
		i_reg_we: 		in std_logic; 
		i_reg_data : 	in std_logic_vector(7 downto 0);
		i_reg_addr	: 	in std_logic_vector(4 downto 0); 
				
		o_pwm			: out	std_logic);		--serial clock output of i2c bus
end PWM_module;

		
architecture Behavioral of PWM_module is
signal tx_ena : std_logic;
signal duty_we : std_logic;

signal clk_div : std_logic_vector(15 downto 0);
signal duty : std_logic_vector(15 downto 0);
signal tx_done_tick :std_logic;
signal read_tx_fifo :std_logic;

signal tx_full :std_logic;
signal rx_fifo_empty, tx_fifo_empty :std_logic;

begin

    pwm_unit: entity work.PWM_master(Behavioral)
        port map(	
        	i_clk=>i_clk, 
			i_rst=>i_rst, 
			i_tx_ena=>tx_ena,
			
			i_duty_we=>duty_we,
			i_pwm_div=>unsigned(clk_div),
			i_duty=>unsigned(duty),
			o_pwm=>o_pwm
			);


	process(i_clk, i_reg_addr, i_reg_we) 
	begin
		if rising_edge(i_clk) then
			duty_we <= '0';
			if(i_reg_we = '1') then
				case i_reg_addr(4 downto 0) is
	          		when PWM_DUTY_HIGH => 
	          			duty(15 downto 8) 	<= i_reg_data;
	          			duty_we <= '1';
					when PWM_DUTY_LOW =>
						duty(7 downto 0) 	<= i_reg_data; 
						duty_we <= '1';
					when PWM_FREQ_DIV_HIGH =>
						clk_div(15 downto 8)<= i_reg_data; 
					when PWM_FREQ_DIV_LOW =>
						clk_div(7 downto 0) <= i_reg_data;
					when PWM_ENABLE =>
						tx_ena<= i_reg_data(0);
					when OTHERS =>
					
				end case;
			end if;
		end if;
	end process;
end Behavioral;
