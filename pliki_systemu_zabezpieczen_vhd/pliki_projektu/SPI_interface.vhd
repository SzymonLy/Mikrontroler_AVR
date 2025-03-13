library IEEE;
use ieee.STD_LOGIC_1164.all;

use ieee.Numeric_Std.all;
use work.INTERFACE_regs.ALL;

entity SPI_module is
	generic(
		MAX_SLAVES	: integer := 4;
		FIFO_LENGHT : integer := 8;
		WIDTH : integer := 8); 
	port(
		i_clk	 	: in std_logic;														 
		i_rst 		: in std_logic;																											
		i_rst_tx 		: in std_logic;																											
		
		i_read_rx , i_write_tx : in std_logic; -- write 1 for one clock cycle to read or write something 
		i_sett_we: in std_logic; 
		i_sett_data : in std_logic_vector(7 downto 0);
		i_sett_add	: in std_logic_vector(4 downto 0); 
		
		i_data: in std_logic_vector (WIDTH-1 downto 0);--input data port
		o_data: out std_logic_vector (WIDTH-1 downto 0); --output data port
		o_status_data: out std_logic_vector (WIDTH-1 downto 0); --output data port
		o_rx_finish, o_tx_finish: out std_logic; 
		i_loop: in std_logic; 
		i_tx_enable: in std_logic;
		--i_rewrite_fifo: in std_logic;

		--output signals to outside devidec
		o_sclk		: out std_logic;											
		o_ss		: out std_logic_vector(MAX_SLAVES-1 downto 0);	 --slave select			
		i_miso		: in std_logic;	
		o_mosi		: out std_logic
		); 
end SPI_module;

		
architecture Behavioral of SPI_module is
	signal rst_tx :	std_logic;	
	signal spi_cpol :	std_logic;	
	signal spi_cpha :	std_logic;	
	signal spi_cont :	std_logic;	
	signal read_tx_fifo :	std_logic;	
	signal spi_clk_div :	unsigned (7 downto 0);
	signal tx_en :		std_logic;	
	signal tx_full :		std_logic;	
	signal spi_addr :	integer range 0 to MAX_SLAVES;		
	signal tx_data :	std_logic_vector(WIDTH-1 downto 0);		
	signal spi_busy :	std_logic;		
	signal rx_data :	std_logic_vector(WIDTH-1 downto 0);		
	signal tx_done_tick, rx_done_tick :	std_logic;	
	signal rx_fifo_empty, tx_fifo_empty :std_logic;
begin

	rst_tx <= i_rst when i_rst = '1' else i_rst_tx;
	
	fifo_tx_unit: entity work.FIFO(Behavioral)
	generic map(LENGHT=>FIFO_LENGHT , WIDTH=>WIDTH)
	port map(i_clk=>i_clk, i_rst=>rst_tx,
		i_loop=>i_loop,
		o_data=>tx_data, --data output 
		i_data=>i_data, --data input, rx uart is connected here,
		i_write=>i_write_tx,--write a byte after receiving it
		i_read =>read_tx_fifo, --read bit
		o_full => tx_full, 
		o_empty=> tx_fifo_empty
	);
	
	fifo_rx_unit: entity work.FIFO(Behavioral)
	generic map(LENGHT=>FIFO_LENGHT , WIDTH=>WIDTH)
	port map(i_clk=>i_clk, i_rst=>i_rst,
		i_loop=>'0',
		o_data=>o_data, --data output 
		i_data=>rx_data, --data input, rx uart is connected here,
		i_write=>rx_done_tick,--write a byte after receiving it
		i_read =>i_read_rx, --read bit
		o_full => open, 
		o_empty=> rx_fifo_empty
	);
	
	SPI_master :entity work.SPI_master(Behavioral)
	generic map(SLAVES=> MAX_SLAVES, WIDTH=>WIDTH)
	port map(i_clk=>i_clk, i_rst=>i_rst,
	
		i_cpol=>spi_cpol,
		i_cpha=>spi_cpha,
		i_cont=>spi_cont,
		i_clk_div=>spi_clk_div,
		
		i_tx_en=>tx_en,-- how does it works?
		i_addr=>spi_addr,
		i_tx_data=>tx_data,
		o_busy=>spi_busy,
		o_rx_data=>rx_data,
		o_sclk=>o_sclk,
		o_ss=>o_ss,
		i_miso=>i_miso,
		o_mosi=>o_mosi,
		o_read_fifo=>read_tx_fifo,
		o_tx_done_tick=>tx_done_tick,
		o_rx_done_tick=>rx_done_tick
	);
	tx_en <= not tx_fifo_empty and i_tx_enable;
	
	o_tx_finish <= tx_fifo_empty and tx_done_tick; -- it need verification, is it work properly for one clock cycle. 
	o_status_data(0) <= tx_fifo_empty and tx_done_tick;
	o_status_data(1) <= tx_full;
	o_status_data(2) <= rx_done_tick;
	o_status_data(3) <= rx_fifo_empty;
	
	process(i_clk, i_sett_add, i_sett_we) 
	begin
		if rising_edge(i_clk) then
			if(i_sett_we = '1') then
				case i_sett_add is
	          		when SPI_CPOL_SELECT => 
						spi_cpol 		<= i_sett_data(0);
					when SPI_CPHA_SELECT =>
						spi_cpha	 		<= i_sett_data(0);
					when SPI_CONT_SELECT =>
						spi_cont 			<= i_sett_data(0); 
					when SPI_CLK_DIV_SELECT =>
						spi_clk_div 		<= unsigned(i_sett_data);
					when SPI_ADDRES_SELECT =>
						spi_addr 		<= to_integer(unsigned(i_sett_data));
					when OTHERS =>
					
				end case;
			end if;
		end if;
	end process;
end Behavioral;

