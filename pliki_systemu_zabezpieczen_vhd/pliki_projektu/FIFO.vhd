library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity FIFO is
    Generic (WIDTH: integer := 8; --how many bits has a single cell
            LENGHT: integer := 8 --how many cells the fifo has
       ); 
    Port ( i_clk : in STD_LOGIC;
           i_rst : in STD_LOGIC;
           i_loop : in STD_LOGIC;
           o_return : out STD_LOGIC;
           i_write, i_read: in STD_LOGIC; -- write and read input signal
           o_full, o_empty : out STD_LOGIC;
           i_data : in std_logic_vector (WIDTH-1 downto 0); --input data
           o_data : out std_logic_vector (WIDTH-1 downto 0) -- output data
           --o_data_last : out std_logic_vector (WIDTH-1 downto 0) -- output data
           );
end FIFO;

architecture Behavioral of FIFO is

    type t_data is array (0 to LENGHT-1) of std_logic_vector(WIDTH-1 downto 0);
    signal r_data : t_data := (others => (others => '0'));
    signal s_full, s_empty: STD_LOGIC ;
    
    subtype t_index is integer range t_data'range;
    signal r_read_index, r_write_index, r_fill_count : t_index;
 
    procedure increment(signal index : inout t_index) is
    begin
 		if index = t_index'high then
 			index <= t_index'low;
 		else
        	index <= index + 1;
      	end if;
    end procedure;
begin

    o_full <= s_full;
    --o_empty <= s_empty;
    
    

    s_empty <= '1' when r_fill_count = 0 else '0';
    s_full <= '1' when r_fill_count > LENGHT - 1 else '0';
    
    -- r_fill_count = 0 when there is nothing more to read. 
    process(r_write_index, r_read_index)
    begin
        if r_write_index < r_read_index then
            r_fill_count <= r_write_index - r_read_index + LENGHT;
        else
            r_fill_count <= r_write_index - r_read_index;
        end if;
    end process;

    -- there is a significan(1 clock cycles) tlatency between i_read signal and chencging o_data output
    process (i_clk , i_rst )
	begin
        if i_rst='1' then
            r_write_index <= 0;
            r_read_index <= 0;
            --clearing data in all registers is not important as long, as there is good restriction to it. 
        elsif(i_clk'event and i_clk='1')then 
        	o_return <= '0';
        	o_empty<=s_empty; --there have to be a small latency, because data is awaible 1 clock cycle later, than s_empty is high.
            r_data(r_write_index) <= i_data; -- there is a problem, as it contantly write new information to the ram, which can decrease it's memory life
           
           	if s_empty = '1' then 
           		o_data <= (others=>'Z');
           	else  
            	o_data <= r_data(r_read_index);   
            end if;
            if i_write = '1' then
                if s_full='0' then
                    increment(r_write_index);
                end if;
            end if;   
            if i_read = '1' then
            	if r_fill_count = 1 and i_loop = '1' then -- data that is going to be readed does not exist, has the same addres as writing
    				r_read_index <= 0;
    				o_return <= '1';
   				elsif s_empty='0' then
                    increment(r_read_index);             
                end if;
            end if;            
        end if; 
    end process;
end Behavioral;
