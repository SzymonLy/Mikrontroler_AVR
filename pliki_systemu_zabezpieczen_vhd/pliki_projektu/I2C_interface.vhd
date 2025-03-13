

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.Numeric_Std.all;
use IEEE.NUMERIC_STD.ALL;


entity I2C_module is
	Port(
		i_clk			: in std_logic;				
		i_rst	 		: in std_logic;	
		i_rst_tx 		: in std_logic;	
		
		i_read_rx , i_write_tx : in std_logic; -- write 1 for one clock cycle to read or write something 
		i_sett_we: in std_logic; 
		i_sett_data : in std_logic_vector(7 downto 0);
		i_sett_add	: in std_logic_vector(7 downto 0); 
		
		i_data: in std_logic_vector (7 downto 0);--input data port
		o_data: out std_logic_vector (7 downto 0); --output data port
		o_status_data: out std_logic_vector (7 downto 0); --output data port
		o_rx_finish, o_tx_finish: out std_logic; 
		
		i_loop: in std_logic; 
		i_tx_enable: in std_logic;
		
		io_sda			: inout	STD_LOGIC;		--serial data output of i2c bus
		io_scl			: inout	STD_LOGIC);		--serial clock output of i2c bus
end I2C_module;

		
architecture Behavioral of I2C_module is

signal tx_ena : STD_LOGIC;
--signal tx_rx : STD_LOGIC;
signal write_read : STD_LOGIC;
signal tx_addr : STD_LOGIC_VECTOR(6 downto 0);

begin

    i2c_unit: entity work.I2C_master(Behavioral)
        port map(	
        	i_clk=>i_clk, 
			i_rst=>i_rst, 
			
			i_tx_ena=>tx_ena,
			i_tx_addr=>tx_addr,--address of the slave (6 downto 0)
			--i_tx_rx=>tx_rx,	
			i_write_read=>write_read,--'0' is write, '1' is read
			i_tx_data=>tx_data,--data to write to slave
			o_busy=>busy,--indicates transaction in progress
			o_rx_data=>rx_data,--data read from slave
			o_ack_error=>ack_error,--flag if improper acknowledge from slave
			
			io_sda=>io_sda,--serial data output of i2c bus
			io_scl=>io_scl--serial clock output of i2c bus
			);
		
		
	tx_en <= not tx_fifo_empty and i_tx_enable;
	
	o_tx_finish <= tx_fifo_empty and tx_done_tick; -- it need verification, is it work properly for one clock cycle. 
	o_status_data(0) <= tx_fifo_empty and tx_done_tick;
	o_status_data(1) <= tx_full;
	o_status_data(2) <= rx_done_tick;
	o_status_data(3) <= rx_fifo_empty;		
	
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
