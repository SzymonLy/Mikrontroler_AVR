library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.Numeric_Std.all;
use work.INTERFACE_regs.ALL;


entity I2C is
	generic(
		input_i_clk : integer := 50_000_000; --input clock speed from user logic in Hz
		bus_i_clk	 : integer := 400_000);	 --speed the i2c bus (scl) will run at in Hz
	port(
		i_clk			: in std_logic;				
		i_rst	 		: in std_logic;				
		i_tx_ena		: in std_logic;										
		i_tx_addr		: in std_logic_vector(6 downto 0); --address of target slave
		i_rw			: in std_logic;			--'0' is write, '1' is read
		i_tx_data	 	: in std_logic_vector(7 downto 0); --data to write to slave
		o_busy			: out std_logic;		--indicates transaction in progress
		o_rx_data	 	: out std_logic_vector(7 downto 0); --data read from slave
		o_ack_error 	: out std_logic;		--flag if improper acknowledge from slave
		io_sda			: inout	std_logic;		--serial data output of i2c bus
		io_clk			: inout	std_logic);		--serial clock output of i2c bus
end I2C;

architecture Behavioral of I2C is
	constant divider	:	integer := (input_i_clk/bus_i_clk)/4; --number of clocks in 1/4 cycle of io_clk
	type machine is(ready, start, command, slv_ack1, wr, rd, slv_ack2, mstr_ack, stop); --needed states
	signal state			 : machine;					--state machine
	signal data_i_clk		: std_logic;				--data clock for io_sda
	signal ack_error		: std_logic; 
	signal data_i_clk_prev 	: std_logic;				--data clock during previous system clock
	signal scl_i_clk		: std_logic;				--constantly running internal io_clk
	signal scl_ena			: std_logic := '0';		 	--enables internal io_clk to output
	signal sda_int			: std_logic := '1';			--internal io_sda
	signal sda_ena_n		: std_logic;				--enables internal io_sda to output
	signal addr_rw			: std_logic_vector(7 downto 0);	 --latched in address and read/write
	signal data_tx			: std_logic_vector(7 downto 0);	 --latched in data to write to slave
	signal data_rx			: std_logic_vector(7 downto 0);	 --data received from slave
	signal bit_cnt			: integer range 0 to 7 := 7;	--tracks bit number in transaction
	signal stretch			: std_logic := '0';				 --identifies if slave is stretching io_clk
begin
	o_ack_error <= ack_error;
	--generate the timing for the bus clock (scl_i_clk) and the data clock (data_i_clk)
	process(i_clk, i_rst)
		variable count	:	integer range 0 to divider*4;	--timing for clock generation
	begin
		if(i_rst = '1') then								--reset asserted
			stretch <= '0';
			count := 0;
		elsif rising_edge(i_clk) then
			data_i_clk_prev <= data_i_clk;					--store previous value of data clock
			if(count = divider*4-1) then				--end of timing cycle
				count := 0;											 --reset timer
			elsif(stretch = '0') then					 --clock stretching from slave not detected
				count := count + 1;							 --continue clock generation timing
			end if;
			case count is
				when 0 to divider-1 =>						--first 1/4 cycle of clocking
					scl_i_clk <= '0';
					data_i_clk <= '0';
				when divider to divider*2-1 =>		--second 1/4 cycle of clocking
					scl_i_clk <= '0';
					data_i_clk <= '1';
				when divider*2 to divider*3-1 =>	--third 1/4 cycle of clocking
					scl_i_clk <= '1';								 --release io_clk
					if(io_clk = '0') then							--detect if slave is stretching clock
						stretch <= '1';
					else
						stretch <= '0';
					end if;
					data_i_clk <= '1';
				when others =>										--last 1/4 cycle of clocking
					scl_i_clk <= '1';
					data_i_clk <= '0';
			end case;
		end if;
	end process;

	--state machine and writing to io_sda during io_clk low (data_i_clk rising edge)
	process(i_clk, i_rst)
	begin
		if(i_rst = '1') then								 --reset asserted
			state <= ready;											--return to initial state
			o_busy <= '1';												 --indicate not available
			scl_ena <= '0';											--sets io_clk high impedance
			sda_int <= '1';											--sets io_sda high impedance
			o_ack_error <= '0';										--clear acknowledge error flag
			bit_cnt <= 7;												--restarts data bit counter
			o_rx_data <= "00000000";							 --clear data read port
		elsif rising_edge(i_clk) then
			if(data_i_clk = '1' and data_i_clk_prev = '0') then	--data clock rising edge
				case state is
					when ready =>											--idle state
						if(i_tx_ena = '1') then							 --transaction requested
							o_busy <= '1';									 --flag o_busy
							addr_rw <= i_tx_addr & i_rw;					--collect requested slave address and command
							data_tx <= i_tx_data;						--collect requested data to write
							state <= start;								--go to start bit
						else														 --remain idle
							o_busy <= '0';									 --unflag o_busy
							state <= ready;								--remain idle
						end if;
					when start =>											--start bit of transaction
						o_busy <= '1';										 --resume o_busy if continuous mode
						sda_int <= addr_rw(bit_cnt);		 --set first address bit to bus
						state <= command;								--go to command
					when command =>										--address and command byte of transaction
						if(bit_cnt = 0) then						 --command transmit finished
							sda_int <= '1';								--release io_sda for slave acknowledge
							bit_cnt <= 7;									--reset bit counter for "byte" states
							state <= slv_ack1;						 --go to slave acknowledge (command)
						else														 --next clock cycle of command state
							bit_cnt <= bit_cnt - 1;				--keep track of transaction bits
							sda_int <= addr_rw(bit_cnt-1); --write address/command bit to bus
							state <= command;							--continue with command
						end if;
					when slv_ack1 =>									 --slave acknowledge bit (command)
						if(addr_rw(0) = '0') then				--write command
							sda_int <= data_tx(bit_cnt);	 --write first bit of data
							state <= wr;									 --go to write byte
						else														 --read command
							sda_int <= '1';								--release io_sda from incoming data
							state <= rd;									 --go to read byte
						end if;
					when wr =>												 --write byte of transaction
						o_busy <= '1';										 --resume o_busy if continuous mode
						if(bit_cnt = 0) then						 --write byte transmit finished
							sda_int <= '1';								--release io_sda for slave acknowledge
							bit_cnt <= 7;									--reset bit counter for "byte" states
							state <= slv_ack2;						 --go to slave acknowledge (write)
						else														 --next clock cycle of write state
							bit_cnt <= bit_cnt - 1;				--keep track of transaction bits
							sda_int <= data_tx(bit_cnt-1); --write next bit to bus
							state <= wr;									 --continue writing
						end if;
					when rd =>												 --read byte of transaction
						o_busy <= '1';										 --resume o_busy if continuous mode
						if(bit_cnt = 0) then						 --read byte receive finished
							if(i_tx_ena = '1' and addr_rw = i_tx_addr & i_rw) then	--continuing with another read at same address
								sda_int <= '0';							--acknowledge the byte has been received
							else													 --stopping or continuing with a write
								sda_int <= '1';							--send a no-acknowledge (before stop or repeated start)
							end if;
							bit_cnt <= 7;									--reset bit counter for "byte" states
							o_rx_data <= data_rx;						--output received data
							state <= mstr_ack;						 --go to master acknowledge
						else														 --next clock cycle of read state
							bit_cnt <= bit_cnt - 1;				--keep track of transaction bits
							state <= rd;									 --continue reading
						end if;
					when slv_ack2 =>									 --slave acknowledge bit (write)
						if(i_tx_ena = '1') then							 --continue transaction
							o_busy <= '0';									 --continue is accepted
							addr_rw <= i_tx_addr & i_rw;					--collect requested slave address and command
							data_tx <= i_tx_data;						--collect requested data to write
							if(addr_rw = i_tx_addr & i_rw) then	 --continue transaction with another write
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
							addr_rw <= i_tx_addr & i_rw;					--collect requested slave address and command
							data_tx <= i_tx_data;						--collect requested data to write
							if(addr_rw = i_tx_addr & i_rw) then	 --continue transaction with another read
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
				end case;		
			elsif(data_i_clk = '0' and data_i_clk_prev = '1') then	--data clock falling edge
				case state is
					when start =>									
						if(scl_ena = '0') then									--starting new transaction
							scl_ena <= '1';											 --enable io_clk output
							o_ack_error <= '0';										 --reset acknowledge error output
						end if;
					when slv_ack1 =>													--receiving slave acknowledge (command)
						if(io_sda /= '0' OR ack_error = '1') then	--no-acknowledge or previous no-acknowledge
							o_ack_error <= '1';										 --set error output if no-acknowledge
						end if;
					when rd =>																--receiving slave data
						data_rx(bit_cnt) <= io_sda;								--receive current slave data bit
					when slv_ack2 =>													--receiving slave acknowledge (write)
						if(io_sda /= '0' OR ack_error = '1') then	--no-acknowledge or previous no-acknowledge
							o_ack_error <= '1';										 --set error output if no-acknowledge
						end if;
					when stop =>
						scl_ena <= '0';												 --disable io_clk
					when others =>
						null;
				end case;
			end if;
		end if;
	end process;	


	--set io_sda output
	with state SELECT
		sda_ena_n <= data_i_clk_prev when start,		 --generate start condition
								 not data_i_clk_prev when stop,	--generate stop condition
								 sda_int when others;					--set to internal io_sda signal		
			
	--set io_clk and io_sda outputs
	io_clk <= '0' when (scl_ena = '1' and scl_i_clk = '0') else 'Z';
	io_sda <= '0' when sda_ena_n = '0' else 'Z';
	
end Behavioral;
