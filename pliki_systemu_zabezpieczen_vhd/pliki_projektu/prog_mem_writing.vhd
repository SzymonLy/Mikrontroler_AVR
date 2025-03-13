library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.INTERFACE_regs.ALL;
use IEEE.NUMERIC_STD.ALL;


entity prog_mem_writing is
	Generic(
		MESS_SIZE: integer := 16
		--MAX_LENGHT : integer :=8 	
		);
	Port(
		i_clk, i_rst :in std_logic;
		-- reading from an uart
		i_data :in std_logic_vector(7 downto 0);		
		i_wr :in std_logic;
		-- writing to the memory
		o_mem_data :out std_logic_vector(15 downto 0);
		o_mem_wr :out std_logic; 
		o_mem_addr :out std_logic_vector(31 downto 0);
		
		-- 
		o_wait :out std_logic;
		i_read_tx :in std_logic;
		i_read_mem :in std_logic;
		o_tx_write :out std_logic;
		o_tx_data :out std_logic_vector(7 downto 0)	
	);

end prog_mem_writing;


  
architecture Behavioral of prog_mem_writing is
	type state_type is (idle, start_s, byte_count_s,address_s, record_type_s, data_s, checksum_s, end_file);
	signal state, state_next: state_type;
	--signal last_byte : std_logic_vector(7 downto 0);
	signal addr_temp, addr_temp_next : unsigned(3 downto 0);
	signal read_count, read_count_next : unsigned(7 downto 0);
	signal sent_count, sent_count_next, sent_size : unsigned(7 downto 0);
	signal byte_count, byte_count_next, max_bytes : unsigned(7 downto 0); -- max is 16, because of memory optimalization
	signal read_address : unsigned(15 downto 0);
	signal sending_address : unsigned(15 downto 0);
	signal mem_addr_offset : unsigned(19 downto 0);
	--signal wr_reg :std_logic;
	signal wr_temp :std_logic;
	signal mem_wr_en :std_logic;
	signal temp_rst :std_logic;
	signal checksum_valid :std_logic;
	signal first_byte :std_logic;
	signal mem_offset_en :std_logic;
	signal second_clock_cycle :std_logic;
	signal pc_wait :std_logic;
	
	signal record_type : std_logic_vector(7 downto 0);
	signal mem_data : std_logic_vector(15 downto 0);
	signal temp_out : std_logic_vector(7 downto 0);
	signal temp_in : std_logic_vector(15 downto 0);
	signal mem_addr : unsigned(31 downto 0);
	signal checksum, checksum_next : unsigned(7 downto 0);
	
	
	signal send_tx, tx_sending:std_logic;
	signal tx_mess : std_logic_vector(127 downto 0);
	signal sent_bytes : unsigned(4 downto 0);

	signal read_3_rx	:std_logic;
	signal data_0_rx	:std_logic_vector(7 downto 0);
	signal data_1_rx	:std_logic_vector(7 downto 0);
	signal data_2_rx	:std_logic_vector(7 downto 0);
	signal data_rx_final	:std_logic_vector(7 downto 0);
	signal data_counter	:unsigned(1 downto 0);
	
	-- good converter : https://www.rapidtables.com/convert/number/ascii-to-hex.html
	constant START_BYTE : std_logic_vector(7 downto 0) := x"3a"; -- : code
	constant RESET_BYTE : std_logic_vector(7 downto 0) := x"ff"; -- : code
	constant HEX_RECEIVED : std_logic_vector(87 downto 0) := x"68_65_78_20_72_65_63_69_76_65_64"; -- 	hex recived
	constant HEX_FINISH: std_logic_vector(95 downto 0) := x"68_65_78_20_66_69_6E_69_73_68_65_64"; -- 		hex finished
	constant RESET_DONE: std_logic_vector(79 downto 0) := x"72_65_73_65_74_20_64_6F_6E_65"; -- 		reset done
	constant ERROR_MES: std_logic_vector(39 downto 0) := x"65_72_72_6F_72"; 	-- 		error
	constant NEXT_LINE_MES: std_logic_vector(7 downto 0) := x"0A"; 	-- 		error

	
	component temp_prog_mem
	port( 
		clka 	: IN STD_LOGIC;
		rsta	: IN STD_LOGIC;
		wea 	: IN STD_LOGIC_VECTOR ( 0 DOWNTO 0 );
		addra 	: IN STD_LOGIC_VECTOR ( 3 DOWNTO 0 );
		dina 	: IN STD_LOGIC_VECTOR ( 7 DOWNTO 0 );
		douta 	: OUT STD_LOGIC_VECTOR ( 7 DOWNTO 0 )
	);
	end component;
	
begin

	
	temp_mem : temp_prog_mem
	port map ( 
		clka=>	i_clk,
		dina=>	data_rx_final,
		rsta=> temp_rst,
		wea(0)=>wr_temp, --enable write and read
		addra=>	std_logic_vector(addr_temp),
		douta=> temp_out
	); 
	
	read_3_rx <= i_wr;
	data_rx_final <= i_data;
--	process (i_clk) begin
--		if rising_edge(i_clk) then
--			read_3_rx <= '0';
--			if i_wr = '1' then
--				case data_counter is 
--				when "00" =>
--					data_0_rx <= i_data;
--					data_counter <= data_counter + 1;
--				when "01" =>
--					data_1_rx <= i_data;
--					data_counter <= data_counter + 1;
--				when "10" =>
----					data_2_rx <= i_data;
--					if (data_0_rx = data_1_rx) and (i_data = data_1_rx) then
--						data_rx_final <= i_data;
--					elsif data_0_rx = data_1_rx then
--						data_rx_final <= data_0_rx;
--					elsif data_1_rx = i_data then
--						data_rx_final <= i_data;
--					elsif data_0_rx = i_data then
--						data_rx_final <= data_0_rx;
--					else 
--						data_rx_final <= "00000000";
--					end if;
--					data_counter <= "00";
--					read_3_rx <= '1';
--				when others =>
--					data_counter <= "00";
--				end case;
--			end if;
--		end if;
--	end process;
	
	process(i_clk, i_rst)
		begin
		if i_rst = '1' then
			state_next <= idle;
			mem_addr <= (others =>'0');
			o_wait <= '1';
			tx_mess <= (others=>'0');
			send_tx <= '0';
		elsif rising_edge(i_clk) then
			wr_temp <= '0';
			send_tx <= '0';
			if read_3_rx = '1' then
		--		last_byte <= i_data; --used only to debug, to delete
				read_count_next <= read_count + 1;
				temp_rst <= '0';
				case state is
				when idle =>
					
					if data_rx_final = START_BYTE then
						state_next <= byte_count_s;
						read_count_next <= (others=>'0');
						o_wait <= '1';
						send_tx <= '1';
--						tx_mess<= ( HEX_RECEIVED'length+7 downto 0 => ,
--						others => '0' );
						tx_mess(HEX_RECEIVED'length+7 downto 0) <= HEX_RECEIVED & NEXT_LINE_MES;
						tx_mess(tx_mess'length-1 downto HEX_RECEIVED'length+8) <= (others=>'0');
					end if;
					
				when start_s => 
					read_count_next <= (others=>'0');
					if data_rx_final = START_BYTE then
						state_next <= byte_count_s;
						o_wait <= '1';
					end if;
				when byte_count_s =>
					byte_count_next <= unsigned(data_rx_final);
					state_next <= address_s;
					checksum_next <= unsigned(data_rx_final);
					max_bytes <=  unsigned(data_rx_final); -- max byte number
				when address_s =>
					if read_count = 2 then --after start byte
						read_address(7 downto 0) <= unsigned(data_rx_final);
						state_next <= record_type_s;
					else
						read_address(15 downto 8) <= unsigned(data_rx_final);
					end if;
					checksum_next <= checksum+unsigned(data_rx_final); 
				when record_type_s =>
					record_type <= data_rx_final;
					if byte_count = 0 then--only end of file
						state_next <= checksum_s;
						checksum_next 	<= not(checksum+unsigned(data_rx_final)-1);
					else 
						state_next <= data_s;
						byte_count_next <= byte_count - 1;
						addr_temp_next <= (others=>'0');
						checksum_next <= checksum+unsigned(data_rx_final);	
					end if;
				when data_s=>
					wr_temp <= '1';				
					if byte_count > 0 then
						byte_count_next <= byte_count - 1;
						addr_temp_next <= addr_temp + 1;			
						checksum_next <= checksum+unsigned(data_rx_final);
					else 
						state_next <= checksum_s;
						checksum_next 	<= not(checksum+unsigned(data_rx_final))+1;
						
						-- making copy of readed valeus because they can be edited in some fast transmission before 
						-- writing whole temp memory to prog memory
						-- they are used in checksum state, because checksum_valid high activate sending data immidietly
						--sent_size <= max_bytes;
						sending_address <= '0' & read_address(15 downto 1);-- mem has 16 bits adressing, not 8bit like hex compiler mem address
							
						addr_temp_next <= (others => '0');	
						sent_count_next <= (others => '0'); -- its used during sending 
						byte_count_next <= (others=>'0'); -- its equal to 0 anyway
						second_clock_cycle <= '0' ;
					end if;
				
				when checksum_s => 
					--checksum_next <= not checksum + 1;
					if checksum_next = unsigned(data_rx_final) then
						checksum_valid <= '1';
					else --wrong checksum
						checksum_valid <= '0';
						temp_rst <= '1';
						send_tx <= '1';
						tx_mess(ERROR_MES'length+7 downto 0) <= ERROR_MES & NEXT_LINE_MES;	
						tx_mess(tx_mess'length-1 downto ERROR_MES'length+8) <= (others=>'0');
					end if;
					state_next<= start_s;
				when end_file=>
					temp_rst <= '1';--not required like everythink here
					mem_addr <= (others =>'0');
					mem_addr_offset <= (others =>'0');
					mem_offset_en <= '0';			
					state_next<= idle; --waitng for some other hex file		

				when others =>

					
				end case;
			end if; --not i_wr
			
			o_mem_wr <= '0';
			if checksum_valid = '1' then
				if max_bytes = 0 then --only option is end of the file or maybe some other special comunication
					case record_type is
						when x"01" => -- end of the file activate procesors
							o_wait <= '0';
							state_next <= idle;
							send_tx <= '1';
							tx_mess(HEX_FINISH'length+7 downto 0) <= HEX_FINISH & NEXT_LINE_MES;	
							tx_mess(tx_mess'length-1 downto HEX_FINISH'length+8) <= (others=>'0');
							checksum_valid <= '0'; --exit this branch
						when others=>
				
					end case;
				--sent_count is not always valid during checksum computation
				elsif sent_count /= max_bytes then -- not readed whole temp memory
					sent_count_next <= sent_count + 1; --increment counter and address
					addr_temp_next <= sent_count(3 downto 0) +1;--address of readed temp memory. Starts from 0 to sent_size-1
					
					--first_byte <= not first_byte; -
					byte_count_next <= byte_count - 1;
					-- bytes are always parity, and the par has to reversed before writing it to the memory
					if sent_count(0) = '0' then -- first byte become lower one
						mem_data(7 downto 0) <= temp_out;
					else -- second byte is higher one
						mem_data(15 downto 8) <= temp_out;
						
						case record_type is
							when x"00" =>
								if mem_offset_en= '1' then
									mem_addr(19 downto 0) <= sending_address + mem_addr_offset + sent_count; -- writing to external memory
									mem_addr(31 downto 20) <= (others=>'0'); -- writing to external memory
								else
									mem_addr(15 downto 0) <= sending_address + sent_count(7 downto 1);
								end if;
								if second_clock_cycle = '1' then
									o_mem_wr <= '1';
									second_clock_cycle <= '0' ;
								else
									o_mem_wr <= '0';
									second_clock_cycle <= '1' ;
								end if;
							when x"02" =>-- not used but implemented for compatibility with varius compilers
								mem_addr_offset(19 downto 4) <= unsigned(mem_data);
								mem_addr_offset(3 downto 0) <= (others=>'0');
								mem_offset_en <= '1';
							when x"03" => -- this function is not implemented
								--sets new pc value from 4 data bytes
								--o_pc(15 downto 0) <= mem_data;
								--o_pc_enabled
							when x"04" =>
								mem_offset_en <= '0';
								mem_addr(23 downto 16) <= unsigned(temp_out);
								mem_addr(31 downto 24) <= unsigned(mem_data(7 downto 0));
							when x"05" =>-- not implemented
							-- Start Linear Address Records. 
							-- Explanation https://developer.arm.com/documentation/ka003292/latest
							when others =>
							
						end case;
					end if; 
				else --all temp memory has ben read					
					checksum_valid <= '0';
				end if;
				
			end if;
			
			
			o_tx_write <= '0';
			if send_tx = '1' then
				tx_sending <= '1';
				--o_tx_write <= '1';
				o_tx_data <= tx_mess(tx_mess'length-1 downto tx_mess'length -8);
				sent_bytes <= (others=>'0');
			end if;
			if tx_sending = '1'  then
				--if i_read_tx = '1' then
					if sent_bytes < MESS_SIZE then
						o_tx_write <= '1';
						o_tx_data <= tx_mess(tx_mess'length-1 downto tx_mess'length -8);
						tx_mess(tx_mess'length-1 downto 8) <= tx_mess(tx_mess'length-9 downto 0); --rotate left
						sent_bytes <= sent_bytes + 1;
					else
						sent_bytes <= (others=>'0');
						tx_sending <= '0';
					end if;
				--elsif i_read_mem = '1' then
				--	tx_mess(tx_mess'length-1 downto 8) <= tx_mess(tx_mess'length-9 downto 0); --rotate left
				--end if;
			end if;
			
		end if; --rising_edge 
	end process;
	o_mem_data <= mem_data;
	o_mem_addr <= std_logic_vector(mem_addr);
--			addra=>	addr_temp,
--		douta=> temp_out
	--sending messege to fifo
	
--	process(i_clk) begin
--		if rising_edge(i_clk) then
----			o_tx_write <= '0';
----			if send_tx = '1' then
----				tx_sending <= '1';
----				o_tx_write <= '1';
----				o_tx_data <= tx_mess(tx_mess'length-1 downto tx_mess'length -8);
----			end if;
----			if tx_sending = '1'  then
----				if i_read_tx = '1' then
----					if sent_bytes < MESS_SIZE then
----						o_tx_write <= '1';
----						o_tx_data <= tx_mess(tx_mess'length-1 downto tx_mess'length -8);
						
----						sent_bytes <= sent_bytes + 1;
----					else
----						sent_bytes <= (others=>'0');
----						tx_sending <= '0';
----					end if;
----				elsif i_read_mem = '1' then
----					tx_mess(tx_mess'length-1 downto 8) <= tx_mess(tx_mess'length-9 downto 0); --rotate left
----				end if;
----			end if;
--		end if;
--	end process;
	process(i_clk, i_rst)
		begin
		if i_rst = '1' then
			state <= idle;
		elsif rising_edge(i_clk) then
			state <= state_next;
			read_count <= read_count_next;
			byte_count <= byte_count_next;
			addr_temp <= addr_temp_next;
			checksum <= checksum_next;
			sent_count<=sent_count_next;
		--	wr_reg <= i_wr;
		end if;
	end process;
	
end Behavioral;
