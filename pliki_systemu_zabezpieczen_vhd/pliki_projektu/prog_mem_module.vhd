
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.NUMERIC_STD.ALL;
use work.INTERFACE_regs.ALL;

entity prog_mem_module is
	generic(
		--UART SETTING FOR TRANSMISSION
		WIDHT: integer :=8; -- number of bits in a single uart signal
		PARITY: std_logic :='0'; -- enables or disables parity
		ODD_EVEN_PAR: std_logic :='0'; -- odd parity
		STOP_TICKS : integer := 31; -- its 16
		--BAUD_RATE: unsigned := x"0A";
		BAUD_RATE: unsigned(15 downto 0) := x"001B"; --
		FIFO_LENGHT: integer :=65 -- there is some bug in fifo, it has to be 1 and i dont have a mind to solve it now
		--hex setting
		--PROG_MEM_SIZE_LOG: integer :=14 -- 
	);
	port(
		i_clk, i_rst :in std_logic;
		-- reading from an uart
		i_rx :in std_logic;
		o_tx: out std_logic;
		-- writing to the memory
		o_mem_data :out std_logic_vector(15 downto 0);
		o_mem_wr :out std_logic; 
		o_mem_addr :out std_logic_vector(31 downto 0);
		o_wait:out std_logic;
		
		i_data : in std_logic_vector(7 downto 0);-- writing to fifo memory, 
		i_wr: in std_logic;
		o_tx_full : out std_logic;
		
		o_rx_data :out std_logic_vector(7 downto 0);
		i_rx_read :in std_logic; --------
		o_rx_not_empty :out std_logic ----
	);
end prog_mem_module;

architecture Behavioral of prog_mem_module is

	signal s_rx_done_tick : std_logic;
	signal s_tick : std_logic;
	signal rx_data, tx_mod_data, fifo_data :std_logic_vector(7 downto 0);
	signal fifo_i_data, tx_send_data :std_logic_vector(7 downto 0);
	signal tx_start: std_logic;
	signal read_tx, tx_write, read_mem: std_logic;
	signal tx_fifo_write,tx_module_wr: std_logic;
	signal read_tx_fifo: std_logic;
	signal mem_wr: std_logic;
	signal waiting: std_logic;
	--signal waiting_rx_signal: std_logic;
	signal s_tx_empty, tx_full: std_logic;
	
	signal rst_rx_tick : std_logic;
	signal tx_tick, rx_tick: std_logic;

--component ila_0 is
--  Port ( 
--    clk: in STD_LOGIC;
--    probe0 : in STD_LOGIC_VECTOR ( 7 downto 0 );
--    probe1 : in STD_LOGIC_VECTOR ( 0 to 0 );
--    probe2 : in STD_LOGIC_VECTOR ( 15 downto 0 );
--    probe3 : in STD_LOGIC_VECTOR ( 0 to 0 );
--    probe4 : in STD_LOGIC_VECTOR ( 31 downto 0 );
--    probe5 : in STD_LOGIC_VECTOR ( 0 to 0 );
--    probe6 : in STD_LOGIC_VECTOR ( 0 to 0 );
--    probe7 : in STD_LOGIC_VECTOR ( 0 to 0 );
--    probe8 : in STD_LOGIC_VECTOR ( 0 to 0 );
--    probe9 : in STD_LOGIC_VECTOR ( 7 downto 0 )
--  );
--  end component;
  
component uart_rx_2 is
  Port ( 
    clk: in STD_LOGIC;
    i_RX_Serial: in STD_LOGIC;
    o_RX_DV: out STD_LOGIC;
    o_RX_Byte : out STD_LOGIC_VECTOR ( 7 downto 0 )
  );
  end component;
  
  
begin

--entity UART_RX is
--  generic (
--    g_CLKS_PER_BIT : integer := 2592     -- Needs to be set correctly
--    );
--  port (
--    i_Clk       : in  std_logic;
--    i_RX_Serial : in  std_logic;
--    o_RX_DV     : out std_logic;
--    o_RX_Byte   : out std_logic_vector(7 downto 0)
--    );
--end UART_RX;

		uart_rx_unit: entity work.uart_rx_2(Behavioral)
		port map(i_clk=>i_clk, 
			i_RX_Serial=>i_rx, 
			o_RX_DV => s_rx_done_tick,
			o_RX_Byte => rx_data
		);	
	
	

--		uart_rx_unit: entity work.UART_RX(Behavioral)
--		port map(i_clk=>i_clk, i_rst=>i_rst, 
--			i_lenght => std_logic_vector(to_unsigned(WIDHT, 4)),
--			i_parity => PARITY,
--			i_stop_bits => to_unsigned(STOP_TICKS, 5),
--			i_rx=>i_rx, --main input
--			i_tick=>rx_tick, 
--			o_rst_tick => rst_rx_tick,
--			i_odd_even=>ODD_EVEN_PAR,
--			o_rx_done_tick=>s_rx_done_tick, --tick after receiving every byte
--			o_data=>rx_data,
--			o_idle=>open
--		);	
	
--	my_ila : ila_0
--	port map ( 
--		clk=>		i_clk,
--		probe0=>	rx_data,
--		probe1(0)=>	s_rx_done_tick,
--		probe2=>	o_mem_data,
--		probe3(0)=>	o_mem_wr,
--		probe4=>	o_mem_addr,
--		probe5(0)=> waiting,
--		probe6(0)=>	read_tx,
--		probe7(0)=>	read_mem,
--		probe8(0)=>	tx_module_wr,
--		probe9=>	tx_mod_data
--	); 
	o_mem_wr<= mem_wr;
	o_wait<= waiting;
	prog_mem: entity work.prog_mem_writing(Behavioral)
	    port map (
		i_clk=>i_clk, i_rst=>i_rst,
		i_data=>rx_data, 
		i_wr=>s_rx_done_tick,
		o_mem_data=>o_mem_data,
		o_mem_wr=>mem_wr,
		o_mem_addr=>o_mem_addr,
		o_wait=>waiting,
		i_read_tx =>read_tx,
		o_tx_write=>tx_module_wr, 
		o_tx_data=>tx_mod_data,
		i_read_mem=>read_mem
	    );
	   
	   
	
		
	o_rx_data <=   rx_data    ;             
--	process(i_clk, i_rst)
--	begin
--		if i_rst = '1' then
--			waiting_rx_signal <= '0';
--		elsif rising_edge(i_clk) then
--			if mem_wr = '1' or waiting='1' or i_rx_read = '1' then
--				waiting_rx_signal <= '0';
--			elsif s_rx_done_tick = '1' then
--				waiting_rx_signal <= '1';
--			end if;
--		end if; 
--	end process;
--	o_rx_not_empty <=	'0' when i_rst = '1' or mem_wr = '1' or waiting='1' or i_rx_read = '1' else
--						'1' when s_rx_done_tick = '1';
	o_rx_not_empty <= 	s_rx_done_tick;
	
	tx_baud_gen_unit: entity work.Binary_Counter(Behavioral)
		--generic map(BAUD_RATE_DIV=>BAUD_RATE_DIV, BAUD_RATE_DIV_LOG=>BAUD_RATE_DIV_LOG)
		port map(i_clk=>i_clk, i_rst=>i_rst ,
		 o_max_ticks=>tx_tick, 
		 i_baud_rate => BAUD_RATE
		 );

	rx_baud_gen_unit: entity work.Binary_Counter(Behavioral)
		--generic map(BAUD_RATE_DIV=>BAUD_RATE_DIV, BAUD_RATE_DIV_LOG=>BAUD_RATE_DIV_LOG)
		port map(i_clk=>i_clk, i_rst=>rst_rx_tick ,
		 o_max_ticks=>rx_tick, 
		 i_baud_rate => BAUD_RATE
		 ); 
		 
	-- debug
		-- 
	uart_tx_unit: entity work.UART_TX(Behavioral)
		port map(i_clk=>i_clk, i_rst=>i_rst, 
			i_lenght => std_logic_vector(to_unsigned(WIDHT, 4)),
			i_parity => PARITY,
			i_stop_bits => to_unsigned(STOP_TICKS, 5),
			o_tx=>o_tx, 
			i_tick=>tx_tick, 
			i_odd_even=>ODD_EVEN_PAR,
			
			o_tx_done_tick =>read_tx_fifo,

			i_data=>tx_send_data,
--			i_data=>"01011110",
			i_tx_start=> (not s_tx_empty),
--			i_tx_start=> '1',
			o_read_tx_fifo=> read_mem
		);		

	fifo_i_data <= tx_mod_data when i_wr = '0' else i_data;
	tx_fifo_write <= i_wr or tx_module_wr;
	fifo_tx_unit: entity work.FIFO(Behavioral)
		generic map(LENGHT=>FIFO_LENGHT)
		port map(i_clk=>i_clk, i_rst=>i_rst, 
			i_loop=>'0',
			i_data=>fifo_i_data, --data input
			o_data=>tx_send_data, 
			i_write => tx_fifo_write, --write bit
			i_read =>read_tx_fifo, --read bit, conectet to the tx
			o_full=>tx_full,
			o_empty=>s_tx_empty
		);  
	
end Behavioral;
