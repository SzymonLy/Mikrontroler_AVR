library IEEE;
use ieee.STD_LOGIC_1164.all;
--use ieee.std_logic_unsigned.all;
--use ieee.std_logic_arith.all;
use ieee.numeric_std.all;  
use work.INTERFACE_regs.ALL;

entity SPI_master is
	generic(
		WIDTH : integer := 8); 
	port(
		i_clk	 	: in std_logic;														 
		i_rst 		: in std_logic;																											
		--setting signals
		i_cpol		: in std_logic; 
		i_cpha		: in std_logic;													
		i_cont		: in std_logic;		-- continous mode									
		i_clk_div 	: in unsigned(7 downto 0);		--f_sclk = f_clk/(2*i_clk_div) minimum sclk is 0.5clk, which is ok. 
		--control options
		i_tx_en		: in std_logic;								
		i_addr		: in integer range 0 to SPI_MAX_SLAVE;														
		i_tx_data 	: in std_logic_vector(WIDTH-1 downto 0);												
		-- signal to others modules whichin the controler
		o_busy		: out std_logic;			
		o_rx_data 	: out std_logic_vector(WIDTH-1 downto 0);	
		--output signals to outside devidec
		o_sclk		: out std_logic;											
		o_ss		: out std_logic_vector(SPI_MAX_SLAVE-1 downto 0);	 --slave select			
		i_miso		: in std_logic;	
		o_mosi		: out std_logic;
		
		o_tx_done_tick		: out std_logic;
		o_read_fifo			: out std_logic;
		o_rx_done_tick		: out std_logic
		); 
end SPI_master;

architecture Behavioral of SPI_master is
	type machine is(waiting, transmission, wait_one_cycle);		
	signal state			 : 	machine;	
	signal slave			 : 	integer range 0 to SPI_MAX_SLAVE;							
	signal clk_ratio	 	: 	unsigned(7 downto 0);							
	signal count			 : 	unsigned(7 downto 0);							
		
	signal continue		: std_logic;			--flag to continue transaction
	signal rx_buffer	 : std_logic_vector(WIDTH-1 downto 0); 
	signal tx_buffer	 : std_logic_vector(WIDTH-1 downto 0); 
	signal last_bit_rx : integer range 0 TO WIDTH*2;			
						
	signal sclk_counter : integer range 0 TO WIDTH*2 + 1;		
	signal rx_tx_bit : std_logic;				--high is tx low is rx 

	signal sclk		: std_logic;									
	signal ss		: std_logic_vector(SPI_MAX_SLAVE-1 downto 0);	
begin
	o_sclk<=sclk;
	o_ss<=ss;
	process(i_clk, i_rst)
	begin

		if(i_rst = '1') then				
			o_busy <= '1';								
			ss <= (others => '1');		
			o_mosi <= 'Z';							
			o_rx_data <= (others => '0'); 
			state <= waiting;				

		elsif rising_edge(i_clk) then
			o_tx_done_tick<='0';
			o_rx_done_tick <= '0';
			o_read_fifo <= '0';
			case state is							 
				when waiting =>
					o_busy <= '0';						
					ss <= (others => '1'); 
					o_mosi <= 'Z';					
					continue <= '0';		
					sclk <= i_cpol;			
					--input to start the transmission
					if(i_tx_en = '1') then			 

						if(i_clk_div = 0) then		--if selected spi speed is wrong
							clk_ratio <="00000001";			
							count <= "00000001";				
						else
							clk_ratio <= i_clk_div;	
							count <= i_clk_div;			
						end if;
							
						if(i_addr < SPI_MAX_SLAVE) then	-- if slave address if valid
							slave <= i_addr;			
						else
							slave <= 0;					
						end if;
						
						o_busy <= '1';	
						rx_tx_bit <= NOT i_cpha; 		
						tx_buffer <= i_tx_data;			
						sclk_counter <= 0;			
						if i_cpha = '1' then
							last_bit_rx <= WIDTH*2;
						else
							last_bit_rx <= WIDTH*2-1;
						end if;
						 
						state <= transmission;
						o_read_fifo <= '1';
					else
						state <= waiting;				
					end if;

				when transmission =>
					o_busy <= '1';				
					ss(slave) <= '0'; 
					
					if(count = clk_ratio) then			
						count <= "00000001";				

						if(sclk_counter = WIDTH*2 + 1) then
							sclk_counter <= 0;							
						else
							sclk_counter <= sclk_counter + 1; 
						end if;
						--spi i_clk toggle needed
						if(sclk_counter <= WIDTH*2 and ss(slave) = '0') then 
							sclk <= not sclk; 
						end if;
						
						rx_tx_bit <= not rx_tx_bit; 
						--transmit spi clk
						if(rx_tx_bit = '1' and sclk_counter < last_bit_rx) then 
							o_mosi <= tx_buffer(WIDTH-1);				
							tx_buffer <= tx_buffer(WIDTH-2 downto 0) & '0'; --shift data tx buffer
						end if;
						
						--receive spi clk
						if(rx_tx_bit = '0' and sclk_counter < last_bit_rx + 1 and ss(slave) = '0') then 
							rx_buffer <= rx_buffer(WIDTH-2 downto 0) & i_miso; --shift rx bit
						end if;
						
						--last data received
						if sclk_counter = last_bit_rx then
							o_rx_done_tick <= '1';
							if i_cont = '1' then --continue
								tx_buffer <= i_tx_data;			--read input data					
								sclk_counter <= last_bit_rx - WIDTH*2 + 1; 	--reset counter
								continue <= '1';
							end if;							
						end if;
						
						--normal end of transaction, but continue
						if(continue = '1') then	
							continue <= '0';			
							o_busy <= '0';			
							o_rx_data <= rx_buffer; 
						end if;
						
						--end of transaction
						if((sclk_counter = WIDTH*2 + 1) and i_cont = '0') then	 
							o_busy <= '0';					
							ss <= (others => '1'); 
							o_mosi <= 'Z';					
							o_rx_data <= rx_buffer;		
							state <= waiting;		
							o_tx_done_tick<='1';		
						else					
							state <= transmission;				
						end if;
					
					else	
						count <= count + 1;
						state <= transmission;	
					end if;	
				when others =>
					o_busy <= '1';								
					ss <= (others => '1');		
					o_mosi <= 'Z';							
					o_rx_data <= (others => '0'); 
					state <= waiting;
			end case;
		end if;
	end process; 
end Behavioral;
