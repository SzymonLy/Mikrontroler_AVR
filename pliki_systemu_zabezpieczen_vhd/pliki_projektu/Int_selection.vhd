
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.INTERFACE_regs.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

--	type proc_addr 	is array(0 to PROCESSORS) of STD_LOGIC_VECTOR( 4 DOWNTO 0);
--	type int_addr 	is array(0 to INTERFACES) of STD_LOGIC_VECTOR( 4 DOWNTO 0);
--	type proc_data 	is array(0 to PROCESSORS) of STD_LOGIC_VECTOR( 7 DOWNTO 0);
--	type int_data 	is array(0 to INTERFACES) of STD_LOGIC_VECTOR( 7 DOWNTO 0);
	
entity Int_selection is
--	generic(
--		PROCESSORS : integer := 9;
--		INTERFACES : integer := 17
--		); 
    port (  i_clk       		: in  STD_LOGIC;
            i_rst       		: in  STD_LOGIC;
           -- i_interrupt_vec    	: in  STD_LOGIC_VECTOR( 5 DOWNTO 0);
            
            i_data_cpu       	: in  proc_data_type; --input data from  cpu
            o_data_to_cpu      	: out proc_data_type;-- data to cpu from interface
            i_addr_cpu   		: in proc_addr_type; --input addr from cpu
            o_addr_int			: out int_addr_type; -- addres from cpu to interface
            
            i_we_main			: in STD_LOGIC; --we from main
            i_addr_main			: in STD_LOGIC_VECTOR( 4 DOWNTO 0); --input addr from cpu
            i_data_main			: in STD_LOGIC_VECTOR( 7 DOWNTO 0); --input addr from cpu

			-- write enable signals are to be deleted				
            i_data_from_int		: in int_data_type;--data from interace to dpu
            o_data_to_int		: out int_data_type;--data from dpu to interface
            
            i_interrupt_int		: in STD_LOGIC_VECTOR(INTERFACES-1 downto 0); -- from interface
            o_interupt_cpu		: out STD_LOGIC_VECTOR(PROCESSORS-1 downto 0); -- to cpu
            
            o_we_int			: out STD_LOGIC_VECTOR(INTERFACES-1 downto 0); -- to interface
            i_we				: in STD_LOGIC_VECTOR(PROCESSORS-1 downto 0)	-- from cpu
            
            
            );
end Int_selection;


architecture Behavioral of Int_selection is

	signal proc_num : integer;
	signal int_num : integer;
	type proc_int_type 	is array(0 to PROCESSORS-1) of integer;
	signal proc_int : proc_int_type;
	type int_proc_type 	is array(0 to INTERFACES-1) of integer;
	signal int_proc : int_proc_type;
	signal dpu_en : std_logic_vector(PROCESSORS-1 downto 0);
	signal int_en : std_logic_vector(INTERFACES-1 downto 0);
begin

	proc_num <= to_integer(unsigned(i_addr_main(1) & i_data_main(7 downto 5)));
	int_num <= to_integer(unsigned(i_data_main(4 downto 0)));
	process(i_clk, i_rst) begin
		if i_rst = '1' then
			proc_int 	<= (others=>0);
			int_proc 	<= (others=>0);
			dpu_en 		<= (others=>'0');
			int_en 		<= (others=>'0');
		elsif rising_edge(i_clk) then
			--00011 or 00001
			if i_we_main = '1' then
				if i_addr_main(4 downto 0) = INT_SELECT_1 or  i_addr_main(4 downto 0) = INT_SELECT_2 then -- address is 00010 or 00000, depending on chosen  processor
					if proc_num < PROCESSORS and int_num < INTERFACES then
						dpu_en(proc_num) <= '1';
						proc_int(proc_num) <= int_num;
						int_en(int_num) <= '1';
						int_proc(int_num) <= proc_num;
					end if;
				elsif i_addr_main(4 downto 0) = INT_DESELECT_1 or  i_addr_main(4 downto 0) = INT_DESELECT_2 then 
					if proc_num < PROCESSORS and int_num < INTERFACES then
						dpu_en(proc_num) <= '0';
						int_en(int_num) <= '0';
					end if;
				end if;
			end if;
		end if;
	end process;

	gen1: for i in 0 to PROCESSORS-1 generate	
		o_data_to_cpu(i)	<=	i_data_from_int(proc_int(i)) 	when dpu_en(i) = '1' else (others=>'0'); -- works
		o_interupt_cpu(i) 	<= 	i_interrupt_int(proc_int(i))	when dpu_en(i) = '1' else '0'; --  -WORKS
	end generate gen1;

	gen2: for i in 0 to INTERFACES-1 generate 
		o_data_to_int(i)	<=	i_data_cpu(int_proc(i)) 	when int_en(i) = '1' else (others=>'0'); 
		o_addr_int(i)		<=	i_addr_cpu(int_proc(i))		when int_en(i) = '1' else (others=>'0');
		o_we_int(i) 		<= 	i_we(int_proc(i))			when int_en(i) = '1' else '0'; -- from procesor to interfaces
	end generate gen2;
	
end Behavioral;



