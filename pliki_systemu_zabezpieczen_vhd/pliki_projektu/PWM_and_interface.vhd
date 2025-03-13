library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity PWM_and_interface is
	generic(
		MAX_SLAVES	: integer := 4); 
	Port(
        i_clk, i_rst: 	in std_logic;
        i_interupt : 	in std_logic;
        i_reg_we : 		in std_logic;
        i_reg_addr : 	in std_logic_vector(4 downto 0);
        i_reg_data : 	in std_logic_vector(7 downto 0);
      
        o_reg_data : 	out std_logic_vector(7 downto 0);
        o_intt :		out std_logic;
        
		i_pwm			: in	std_logic;		--serial data output of i2c bus
		o_pwm			: out	std_logic	
        );
        
        

		
end PWM_and_interface;

architecture Behavioral of PWM_and_interface is

--	signal uart_tx_enable:	std_logic;
--    signal uart_read_rx	: 	std_logic;
--	signal uart_write_tx  : std_logic;
--	signal uart_write_data: std_logic_vector (7 downto 0);
--	signal rewrite_fifo : 	std_logic; 
--	signal rst_tx : 		std_logic; 
--	signal int_sett_we: 	std_logic; 
--	signal tx_finish:		std_logic;
--	signal rx_finish:		std_logic;
--	signal status_data:		std_logic_vector (7 downto 0);
--	signal uart_read_data:	std_logic_vector (7 downto 0);
begin

    pwm_module: entity work.PWM_module(Behavioral)
        port map(	
        	i_clk=>i_clk, 
			i_rst=>i_rst, 		
			--conections to cpu
			i_sett_data => i_reg_data,
			i_sett_add => i_reg_addr,
			--conections to interface
			i_read_rx=>uart_read_rx, 
			i_write_tx=>uart_write_tx,
			i_rst_tx=>rst_tx,
			i_sett_we => i_reg_we,
			o_tx_finish=>tx_finish,
			o_rx_finish =>rx_finish,
			o_status_data=>status_data,
			i_data=>uart_write_data, 
			o_data=>uart_read_data,			
			i_loop => rewrite_fifo,
			i_tx_enable=>uart_tx_enable,
			
			--outside connection
			io_sda=>io_sda,
			io_scl=>io_scl
			);
	pwm_interface: entity work.Interface(Behavioral)
        port map(	
        	i_clk=>i_clk, 
			i_rst=>i_rst, 
			--conection to cpu
			i_interupt =>i_interupt,
			i_reg_we =>i_reg_we,
			i_reg_addr =>i_reg_addr,
			i_reg_data=>i_reg_data,
			o_reg_data=>o_reg_data,
			o_intt=>o_intt, 
			
			--conection to spi module
			 o_uart_tx_enable=>uart_tx_enable,
			 o_uart_read_rx=>uart_read_rx,	
			 o_uart_write_tx=>uart_write_tx, 
			 o_uart_write_data=>uart_write_data,
			 o_rewrite_fifo =>rewrite_fifo,
			 o_rst_tx =>rst_tx,
			 --o_int_sett_we=>int_sett_we,
			 i_tx_finish=>tx_finish,
			 i_rx_finish=>rx_finish,
			 i_data_mem=>status_data,
			 i_uart_read_data=>uart_read_data
        );

end Behavioral;
