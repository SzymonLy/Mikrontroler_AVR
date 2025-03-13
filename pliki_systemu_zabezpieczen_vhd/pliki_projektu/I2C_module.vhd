library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.Numeric_Std.all;
use IEEE.NUMERIC_STD.ALL;
use work.INTERFACE_regs.ALL;

entity I2C_module is
	generic(
		FIFO_LENGHT : integer := 8;
		WIDTH : integer := 8); 
	Port(
		i_clk			: in std_logic;				
		i_rst	 		: in std_logic;	
		i_rst_tx 		: in std_logic;	
		
		i_read_rx , i_write_tx : in std_logic; -- write 1 for one clock cycle to read or write something 
		i_sett_we: in std_logic; 
		i_sett_data : in std_logic_vector(7 downto 0);
		i_sett_add	: in std_logic_vector(4 downto 0); 
		
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
signal rst_tx : std_logic;

signal tx_ena : std_logic;

signal tx_addr : std_logic_vector(9 downto 0);

signal clk_div : unsigned(15 downto 0);
signal ext_addr_bit : std_logic;


signal tx_data :std_logic_vector(7 downto 0);
signal busy :std_logic;
signal rx_data :std_logic_vector(7 downto 0);

signal ack_error :std_logic;

signal tx_done_tick :std_logic;
signal read_tx_fifo :std_logic;
signal read_tx :std_logic;
signal rx_done_tick :std_logic;


signal tx_full :std_logic;
signal rx_fifo_empty, tx_fifo_empty :std_logic;

signal loop_return :std_logic;
signal data_loop :std_logic;
signal tx_ena_loop :std_logic;

signal read_now :std_logic;
signal fifo_read_write_empty :std_logic;


signal write_read : std_logic;
signal write_read_fifo_we : std_logic;
signal write_read_fifo :std_logic_vector(15 downto 0);
signal write_read_fifo_in :std_logic;

begin

    i2c_unit: entity work.I2C_master(Behavioral)
        port map(	
        	i_clk=>i_clk, 
			i_rst=>i_rst, 
			
			i_ext_addr =>ext_addr_bit,
			i_clk_div => clk_div,
		
			i_tx_ena=>tx_ena,
			i_tx_addr=>tx_addr,--address of the slave (6 downto 0)
			i_write_read=>write_read,--'0' is write, '1' is read
			i_tx_data=>tx_data,--data to write to slave
			o_busy=>busy,--indicates transaction in progress
			o_rx_data=>rx_data,--data read from slave
			o_ack_error=>ack_error,--flag if improper acknowledge from slave
			
			io_sda=>io_sda,--serial data output of i2c bus
			io_scl=>io_scl,--serial clock output of i2c bus
			
			o_tx_done_tick=>tx_done_tick,
			o_read_fifo=>read_tx,
			o_rx_done_tick=>rx_done_tick
			);
		
	
--	tx_ena <= (not tx_fifo_empty and i_tx_enable and tx_ena_loop) or read_now;
	tx_ena <= (not fifo_read_write_empty);
	-- not_empty and 
	
	o_tx_finish <= tx_fifo_empty and tx_done_tick; -- it need verification, is it work properly for one clock cycle. 
	o_status_data(0) <= tx_fifo_empty and tx_done_tick;
	o_status_data(1) <= tx_full;
	o_status_data(2) <= rx_done_tick;
	o_status_data(3) <= rx_fifo_empty;		
	
	rst_tx <= i_rst when i_rst = '1' else i_rst_tx;
	o_rx_finish <= rx_done_tick;
	
	fifo_tx_unit: entity work.FIFO(Behavioral)
	generic map(LENGHT=>FIFO_LENGHT , WIDTH=>WIDTH)
	port map(i_clk=>i_clk, i_rst=>rst_tx,
		i_loop=>i_loop,
		o_return=>loop_return,
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
	process(i_clk)
	begin
		if rising_edge(i_clk) then
			if data_loop = '1' then
				if loop_return = '1' then
					tx_ena_loop <= '0';
				end if;
				if tx_done_tick = '1' then
					tx_ena_loop <= '1';
				end if;
				if i_write_tx = '1' then
					tx_ena_loop <= '1';
				end if;
			else
				tx_ena_loop <= '1';
			end if;
		end if;
	end process;
	
	read_tx_fifo <= read_tx when write_read = '0' else '0';

	fifo_read_write: entity work.FIFO(Behavioral)
	generic map(LENGHT=>FIFO_LENGHT , WIDTH=>1)
	port map(i_clk=>i_clk, i_rst=>i_rst,
		i_loop=>'0',
		o_data(0)=>write_read, 
		i_data(0)=>write_read_fifo_in,
		i_write=>write_read_fifo_we,
		i_read =>read_tx,
		o_full => open, 
		o_empty=> fifo_read_write_empty
	);

	process(i_clk, i_sett_add, i_sett_we) 
	begin
		if rising_edge(i_clk) then
			read_now <= '0';
			write_read_fifo_we 	<= '0';
			if(i_sett_we = '1') then
				case i_sett_add(4 downto 0) is
	          		when I2C_UPPER_ADDR => 
	          			ext_addr_bit <= i_sett_data(7);
	          			tx_addr(9 downto 8) <= i_sett_data(1 downto 0);
					when I2C_LOWER_ADDR =>
						tx_addr(7 downto 0) <= i_sett_data(7 downto 0);-- in 7 bit addresing mode only the lower 7 bits are used. 
					when I2C_READ_WRITE =>
						write_read_fifo_in 	<= i_sett_data(0); 
						write_read_fifo_we 	<= '1';
--						read_now <= i_sett_data(0);
					when I2C_CLK_DIV_LOW =>
						clk_div(7 downto 0) <= unsigned(i_sett_data);
					when I2C_CLK_DIV_HIGH =>
						clk_div(15 downto 8) <= unsigned(i_sett_data);
					when I2C_CONT_MODE_SEL => -- two options. one ADDR, cont data or one addr, one loop of data. 
						data_loop <= i_sett_data(0);
					when OTHERS =>
					
				end case;
			end if;
		end if;
	end process;
	
end Behavioral;
