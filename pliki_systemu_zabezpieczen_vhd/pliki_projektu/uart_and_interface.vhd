library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


use IEEE.NUMERIC_STD.ALL;

entity uart_and_interface is
	Port(
        i_clk, i_rst: 	in std_logic;
        i_interupt : 	in std_logic;
        i_reg_we : 		in std_logic;
        i_reg_addr : 	in std_logic_vector(4 downto 0);
        i_reg_data : 	in std_logic_vector(7 downto 0);
      
        o_reg_data : 	out std_logic_vector(7 downto 0);
        o_intt :		out std_logic;
        
        i_rx: in std_logic; -- input of the rx signal
		o_tx: out std_logic --ouput of the tx signal
        );
end uart_and_interface;

architecture Behavioral of uart_and_interface is
	--conections bettween interface and uart
	signal uart_tx_enable:	std_logic;
    signal uart_read_rx	: 	std_logic;
	signal uart_write_tx  : std_logic;
	signal uart_write_data: std_logic_vector (7 downto 0);
	signal rewrite_fifo : 	std_logic; 
	signal rst_tx : 		std_logic; 
	signal int_sett_we: 	std_logic; 
	signal tx_finish:		std_logic;
	signal rx_finish:		std_logic;
	signal ILA_INTT:		std_logic;
	signal status_data:		std_logic_vector (7 downto 0);
	signal uart_read_data:	std_logic_vector (7 downto 0);
	
	component ila_uart is
  Port ( 
    clk: in STD_LOGIC;
   probe0 : 		 in std_logic_vector(0 downto 0);
   probe1 : 	in std_logic_vector(4 downto 0);
    probe2 : in STD_LOGIC_VECTOR ( 7 downto 0 );
    probe3 : in STD_LOGIC_VECTOR ( 7 downto 0 );
    probe4 : in std_logic_vector(0 downto 0)
  );
  end component;
begin

--	my_ila : ila_uart
--	port map ( 
--		clk=>		i_clk,
--		probe0(0)=>i_reg_we,
--		probe1=>i_reg_addr,
--		probe2=>	uart_write_data,
--		probe3=>	uart_read_data,
--		probe4(0)=> ILA_INTT
--	); 
	o_intt  <= ILA_INTT;
    uart_module: entity work.UART_module(Behavioral)
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
			i_rx=>i_rx, o_tx=>o_tx
			);
	uart_interface: entity work.Interface(Behavioral)
        port map(	
        	i_clk=>i_clk, 
			i_rst=>i_rst, 
			--conection to cpu
			i_interupt =>i_interupt,
			i_reg_we =>i_reg_we,
			i_reg_addr =>i_reg_addr,
			i_reg_data=>i_reg_data,
			o_reg_data=>o_reg_data,
			o_intt=>ILA_INTT, 
			
			--conection to uart module
			 o_uart_tx_enable=>uart_tx_enable,
			 o_uart_read_rx=>uart_read_rx,	
			 o_uart_write_tx=>uart_write_tx, 
			 o_uart_write_data=>uart_write_data,
			 o_rewrite_fifo =>rewrite_fifo,
			 o_rst_tx =>rst_tx,
			-- o_int_sett_we=>int_sett_we,
			 i_tx_finish=>tx_finish,
			 i_rx_finish=>rx_finish,
			 i_data_mem=>status_data,
			 i_uart_read_data=>uart_read_data
        );
end Behavioral;
