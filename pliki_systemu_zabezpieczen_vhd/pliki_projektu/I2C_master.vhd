library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.Numeric_Std.all;
use work.INTERFACE_regs.ALL;


entity I2C_master is
	port(
		i_clk			: in std_logic;				
		i_rst	 		: in std_logic;
		
		i_ext_addr  : in std_logic;							--high if slave address has 10 bits								
		i_clk_div 	: in unsigned(15 downto 0); 				--f_sclk = f_clk/(2*i_clk_div) minimum sclk is 0.5clk, which is ok. 
						
		i_tx_ena		: in std_logic;										
		i_tx_addr		: in std_logic_vector(9 downto 0); 	--address of target slave
		i_write_read	: in std_logic;						--'0' is write, '1' is read 
		i_tx_data	 	: in std_logic_vector(7 downto 0); 	--data to write to slave
		o_busy			: out std_logic;					--indicates transaction in progress
		o_rx_data	 	: out std_logic_vector(7 downto 0); --data read from slave
		o_ack_error 	: out std_logic;					--flag if improper acknowledge from slave
		
		io_sda			: inout	std_logic;					--serial data output of i2c bus
		io_scl			: inout	std_logic;
		
		o_tx_done_tick		: out std_logic;
		--o_tx_read			: out std_logic;
		o_read_fifo			: out std_logic;
		o_rx_done_tick		: out std_logic
		
		
		
		);					--serial clock output of i2c bus
end I2C_master;



architecture Behavioral of I2C_master is
	--constant divider	:	integer := (input_i_clk/bus_i_clk)/4; --number of clocks in 1/4 cycle of io_clk
	type machine is(ready, start, ext_addr_s, ext_addr_ack_s, command, slv_ack1, wr, rd, slv_ack2, mstr_ack, stop); --needed states
	signal state			 : machine;					--state machine
	signal data_i_clk		: std_logic;				--data clock for io_sda
	signal ack_error		: std_logic; 
	signal data_i_clk_prev 	: std_logic;				--data clock during previous system clock
	signal scl_i_clk		: std_logic;				--constantly running internal io_scl
	signal scl_ena			: std_logic := '0';		 	--enables internal io_scl to output
	signal sda_int			: std_logic := '1';			--internal io_sda
	signal sda_ena_n		: std_logic;				--enables internal io_sda to output
	signal addr_rw			: std_logic_vector(7 downto 0);	 --latched in address and read/write
	signal addr_ext			: std_logic_vector(7 downto 0);	 --first byte in extended adress mode
	signal write_read		: std_logic;				
	signal ext_addr			: std_logic;				
	signal rx_done_tick		: std_logic;				
	signal rx_data			: std_logic_vector(7 downto 0);				

	signal data_tx			: std_logic_vector(7 downto 0);	 --latched in data to write to slave
	signal data_rx			: std_logic_vector(7 downto 0);	 --data received from slave
	signal bit_cnt			: integer range 0 to 7 := 7;	--tracks bit number in transaction
	signal stretch			: std_logic := '0';				 --identifies if slave is stretching io_scl
	
	
--	component  ila_2 is
--  Port ( 
--    clk : in STD_LOGIC;
--    probe0 : in STD_LOGIC_VECTOR ( 0 to 0 );
--    probe1 : in STD_LOGIC_VECTOR ( 0 to 0 );
--    probe2 : in STD_LOGIC_VECTOR ( 0 to 0 );
--    probe3 : in STD_LOGIC_VECTOR ( 15 downto 0 );
--    probe4 : in STD_LOGIC_VECTOR ( 0 to 0 );
--    probe5 : in STD_LOGIC_VECTOR ( 0 to 0 );
--    probe6 : in STD_LOGIC_VECTOR ( 0 to 0 );
--    probe7 : in STD_LOGIC_VECTOR ( 8 downto 0 );
--    probe8 : in STD_LOGIC_VECTOR ( 0 to 0 );
--    probe9 : in STD_LOGIC_VECTOR ( 7 downto 0 );
--    probe10 : in STD_LOGIC_VECTOR ( 7 downto 0 );
--    probe11 : in STD_LOGIC_VECTOR ( 0 to 0 )
--  );
--  end component;
  
begin

--	ila_i2c : ila_2
--	port map ( 
--		clk=>		i_clk,
--		probe0(0)=>ack_error,
--		probe1(0)=> io_scl,
--		probe2(0)=>	io_sda,
--		probe3=>	std_logic_vector(i_clk_div),
--		probe4(0)=>	scl_i_clk,
--		probe5(0)=>	data_i_clk,
--		probe6(0)=>	i_tx_ena,
--		probe7=>	i_tx_addr(8 downto 0),
--		probe8(0)=> i_write_read,
--		probe9=> i_tx_data,
--		probe10 => rx_data,
--		probe11(0) => rx_done_tick
--	); 
	o_rx_done_tick <=rx_done_tick;
	o_rx_data <= rx_data ;
	o_ack_error <= ack_error;
	--generate the timing for the bus clock (scl_i_clk) and the data clock (data_i_clk)
	process(i_clk, i_rst)
		variable count			:	integer range 0 to 255;	--timing for clock generation
		variable count_small	:	integer range 0 to 3;	--timing for clock generation
	begin
		if(i_rst = '1') then								--reset asserted
			stretch <= '0';
			count := 0;
			count_small := 0;
		elsif rising_edge(i_clk) then
			data_i_clk_prev <= data_i_clk;					--store previous value of data clock
			if(count >= i_clk_div-1) then				--end of timing cycle
				count := 0;	
				if count_small = 3 then 
					count_small := 0;
				else
					count_small :=	count_small + 1;
				end if;							
			elsif(stretch = '0') then				--clock stretching from slave not detected
				count := count + 1;					--continue clock generation timing
			end if;
			case count_small is
				when 0 =>							--first 1/4 cycle of clocking
					scl_i_clk <= '0';
					data_i_clk <= '0';
				when 1 =>							--second 1/4 cycle of clocking
					scl_i_clk <= '0';
					data_i_clk <= '1';
				when 2 =>							--third 1/4 cycle of clocking
					scl_i_clk <= '1';				--release io_scl
					if(io_scl = '0') then			--detect if slave is stretching clock
						stretch <= '1';
					else
						stretch <= '0';
					end if;
					data_i_clk <= '1';
				when 3 =>							--last 1/4 cycle of clocking
					scl_i_clk <= '1';
					data_i_clk <= '0';
				when others =>	
					count_small := 0;
					count := 0;
					scl_i_clk <= '0';
					data_i_clk <= '0';
			end case;
		end if;
	end process;

	--state machine and writing to io_sda during io_scl low (data_i_clk rising edge)
	process(i_clk, i_rst)
	begin
		if(i_rst = '1') then								 		
			state <= ready;	
			o_busy <= '1';
			scl_ena <= '0';
			sda_int <= '1';
			ack_error <= '0';
			bit_cnt <= 7;
			rx_data <= "00000000";
		elsif rising_edge(i_clk) then
			rx_done_tick <= '0';
			o_tx_done_tick <= '0';
			o_read_fifo <= '0';
			if(data_i_clk = '1' and data_i_clk_prev = '0') then	--data clock rising edge
				case state is
					when ready =>											--idle state
						if(i_tx_ena = '1') then							 --transaction requested
							o_busy <= '1';									 --flag o_busy
							
							write_read <= i_write_read;
							ext_addr <= i_ext_addr;
							if i_ext_addr = '0' then
								addr_rw <= i_tx_addr(6 downto 0) & i_write_read;					--collect requested slave address and command
							else 
								addr_ext <= "11110" & i_tx_addr(9 downto 8) & i_write_read;
								addr_rw <= i_tx_addr(7 downto 0);
							end if;
							data_tx <= i_tx_data;						--collect requested data to write
							o_read_fifo <= '1';
							state <= start;								--go to start bit
						else														 --remain idle
							o_busy <= '0';									 --unflag o_busy
							state <= ready;								--remain idle
						end if;
					when start =>											--start bit of transaction
						o_busy <= '1';
--						write_read <= i_write_read;		
--						ext_addr <= i_ext_addr;
						state <= command;											 --resume o_busy if continuous mode
						if ext_addr = '0' then
							--state <= command;		
							sda_int <= addr_rw(bit_cnt);		 --set first address bit to bus						
						else
							--state <= ext_addr_s;
							sda_int <= addr_ext(bit_cnt);		 --set first address bit to bus
						end if;
					when ext_addr_s =>
						if(bit_cnt = 0) then						 --command transmit finished
							sda_int <= '1';								--release io_sda for slave acknowledge
							bit_cnt <= 7;									--reset bit counter for "byte" states
							state <= slv_ack1;						 --go to slave acknowledge (command)
						else														 --next clock cycle of command state
							bit_cnt <= bit_cnt - 1;				--keep track of transaction bits
							sda_int <= addr_ext(bit_cnt-1); --write address/command bit to bus
							state <= command;							--continue with command
						end if;
					when command =>										--address and command byte of transaction
						if(bit_cnt = 0) then						 --command transmit finished
							sda_int <= '1';								--release io_sda for slave acknowledge
							bit_cnt <= 7;									--reset bit counter for "byte" states
							state <= slv_ack1;						 --go to slave acknowledge (command)
						else														 --next clock cycle of command state
							bit_cnt <= bit_cnt - 1;				--keep track of transaction bits
							if ext_addr = '0' then
								sda_int <= addr_rw(bit_cnt-1); 
							else
								sda_int <= addr_ext(bit_cnt-1);
							end if;
							state <= command;							--continue with command
						end if;
					when slv_ack1 =>
						if ext_addr = '0' then
							if(write_read = '0') then				--write command
								sda_int <= data_tx(bit_cnt);	 --write first bit of data
								state <= wr;									 --go to write byte
							else			--read command
								sda_int <= '1';				--release io_sda from incoming data
								state <= rd;				--go to read byte
							end if;
						else
							ext_addr <= '0';
							state <= command;
							sda_int <= addr_rw(bit_cnt);
						end if;								 
					when wr =>												 --write byte of transaction
						o_busy <= '1';										 --resume o_busy if continuous mode
						if(bit_cnt = 0) then						 --write byte transmit finished
							sda_int <= '1';								--release io_sda for slave acknowledge
							bit_cnt <= 7;									--reset bit counter for "byte" states
							state <= slv_ack2;						 --go to slave acknowledge (write)
							--o_read_fifo <= '1';
						else														 --next clock cycle of write state
							bit_cnt <= bit_cnt - 1;				--keep track of transaction bits
							sda_int <= data_tx(bit_cnt-1); --write next bit to bus
							state <= wr;									 --continue writing
						end if;
					when rd =>												 --read byte of transaction
						o_busy <= '1';										 --resume o_busy if continuous mode
						if(bit_cnt = 0) then						 --read byte receive finished
							if(i_tx_ena = '1' and addr_rw = i_tx_addr(6 downto 0) & i_write_read) then	--continuing with another read at same address
								sda_int <= '0';							--acknowledge the byte has been received
							else													 --stopping or continuing with a write
								sda_int <= '1';							--send a no-acknowledge (before stop or repeated start)
							end if;
							bit_cnt <= 7;									--reset bit counter for "byte" states
							rx_data <= data_rx;						--output received data
							rx_done_tick <= '1';
							state <= mstr_ack;						 --go to master acknowledge
						else														 --next clock cycle of read state
							bit_cnt <= bit_cnt - 1;				--keep track of transaction bits
							state <= rd;									 --continue reading
						end if;
					when slv_ack2 =>	 --slave acknowledge bit (write)
												
						o_tx_done_tick <= '1';
						if(i_tx_ena = '1') then							 --continue transaction
							o_busy <= '0';									 --continue is accepted
							addr_rw <= i_tx_addr(6 downto 0) & i_write_read;					--collect requested slave address and command
							write_read <= i_write_read;
							data_tx <= i_tx_data;						--collect requested data to write
							o_read_fifo <= '1';
							if(i_tx_ena = '1' and addr_rw = i_tx_addr(6 downto 0) & i_write_read) then	 --continue transaction with another write
								sda_int <= i_tx_data(bit_cnt); --write first bit of data
								state <= wr;								 --go to write byte
							else													 --continue transaction with a read or new slave
								state <= start;							--go to repeated start
							end if;
						else														 --complete transaction
							state <= stop;								 --go to stop bit
						end if;
					when mstr_ack =>									 --master acknowledge bit after a read
						if(i_tx_ena = '1') then							 --continue transaction
							o_busy <= '0';									 --continue is accepted and data received is available on bus
							addr_rw <= i_tx_addr(6 downto 0) & i_write_read;
							write_read <= i_write_read;					--collect requested slave address and command
							data_tx <= i_tx_data;						--collect requested data to write
							o_read_fifo <= '1';
							if(i_tx_ena = '1' and addr_rw = i_tx_addr(6 downto 0) & i_write_read) then	 --continue transaction with another read
								sda_int <= '1';							--release io_sda from incoming data
								state <= rd;								 --go to read byte
							else													 --continue transaction with a write or new slave
								state <= start;							--repeated start
							end if;		
						else														 --complete transaction
							state <= stop;								 --go to stop bit
						end if;
					when stop =>											 --stop bit of transaction
						o_busy <= '0';										 --unflag o_busy
						state <= ready;									--go to idle state
					when others =>
						state <= ready;	
						o_busy <= '0';
				end case;		
			elsif(data_i_clk = '0' and data_i_clk_prev = '1') then	--data clock falling edge
				case state is
					when start =>									
						if(scl_ena = '0') then									--starting new transaction
							scl_ena <= '1';											 --enable io_scl output
							ack_error <= '0';										 --reset acknowledge error output
						end if;
					when slv_ack1 =>													--receiving slave acknowledge (command)
						if(io_sda /= '0' or ack_error = '1') then	--no-acknowledge or previous no-acknowledge
							ack_error <= '1';										 --set error output if no-acknowledge
						end if;
					when rd =>																--receiving slave data
						data_rx(bit_cnt) <= io_sda;								--receive current slave data bit
					when slv_ack2 =>													--receiving slave acknowledge (write)
						if(io_sda /= '0' or ack_error = '1') then	--no-acknowledge or previous no-acknowledge
							ack_error <= '1';										 --set error output if no-acknowledge
						end if;
					when stop =>
						scl_ena <= '0';												 --disable io_scl
					when others =>
						null;
				end case;
			end if;
		end if;
	end process;	


	
	--set io_sda output
	with state select
		sda_ena_n <= data_i_clk_prev 		when start,		--generate start condition
					 not data_i_clk_prev 	when stop,		--generate stop condition
					 sda_int 				when others;	--set to internal io_sda signal		
			
	--set io_scl and io_sda outputs
	io_scl <= '0' when (scl_ena = '1' and scl_i_clk = '0') else 'Z';
	io_sda <= '0' when sda_ena_n = '0' else 'Z';
	
end Behavioral;
