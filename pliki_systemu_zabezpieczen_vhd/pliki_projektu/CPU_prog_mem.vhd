library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- the content of the program memory.

--use work.CPU_prog_mem_content.all;

entity CPU_prog_mem is
    port (  i_clk       		: IN  STD_LOGIC;
            i_wait      		: IN  STD_LOGIC; 
            i_rst_pm      		: IN  STD_LOGIC;
            i_pc        		: IN  STD_LOGIC_VECTOR(15 DOWNTO 0); -- word address
            i_pc_h        		: IN  STD_LOGIC_VECTOR(15 DOWNTO 0); -- word address
            i_prog_mem_adr    	: IN  STD_LOGIC_VECTOR(11 DOWNTO 0); -- byte address
            o_opc       		: OUT STD_LOGIC_VECTOR(15 DOWNTO 0); -- 
            o_opc_h       		: OUT STD_LOGIC_VECTOR(15 DOWNTO 0); -- 
            o_pc        		: OUT STD_LOGIC_VECTOR(15 DOWNTO 0); -- = i_pc
            o_prog_mem_out   	: OUT STD_LOGIC_VECTOR( 7 DOWNTO 0);
            
            --writing program memory
            i_prog_mem_we		: IN  STD_LOGIC;
            i_prog_mem_data		: IN  STD_LOGIC_VECTOR( 15 DOWNTO 0)
            );
end CPU_prog_mem;

architecture Behavioral of CPU_prog_mem is

component CPU_program_mem
port( 
	clka 	: IN STD_LOGIC;
	ena 	: IN STD_LOGIC;
	rsta 	: IN STD_LOGIC;
	wea 	: IN STD_LOGIC_VECTOR ( 0 DOWNTO 0 );
	web 	: IN STD_LOGIC_VECTOR ( 0 DOWNTO 0 );
	addra 	: IN STD_LOGIC_VECTOR ( 11 DOWNTO 0 );
	addrb 	: IN STD_LOGIC_VECTOR ( 11 DOWNTO 0 );
	dina 	: IN STD_LOGIC_VECTOR ( 15 DOWNTO 0 );
	dinb 	: IN STD_LOGIC_VECTOR ( 15 DOWNTO 0 );
	clkb 	: IN STD_LOGIC;
	enb 	: IN STD_LOGIC;
	--rstb 	: IN STD_LOGIC;
	douta 	: OUT STD_LOGIC_VECTOR ( 15 DOWNTO 0 );
	doutb 	: OUT STD_LOGIC_VECTOR ( 15 DOWNTO 0 )
);
  
end component;

signal not_wait     		: STD_LOGIC;

signal pc_0       		: STD_LOGIC;
signal pc_a   			: STD_LOGIC_VECTOR(11 DOWNTO 0);
--signal pc_h   			: STD_LOGIC_VECTOR(11 DOWNTO 0);
signal opc  			: STD_LOGIC_VECTOR(15 DOWNTO 0);
signal doutb  			: STD_LOGIC_VECTOR(15 DOWNTO 0);

signal prog_mem_data 	: STD_LOGIC_VECTOR(15 DOWNTO 0);
signal pm_adr_0 		: STD_LOGIC;

begin

prog_mem : CPU_program_mem
port map ( 
	clka=>	i_clk, clkb=>i_clk,
	rsta => i_rst_pm,
	wea(0)=>i_prog_mem_we, --"00" -- write enable. 
	dina=>	i_prog_mem_data,
	dinb=>	(others=>'0'),
	web=>	"0",
	--rstb=>	'0',
	ena=>	not_wait, --enable write and read
	enb=>	not_wait, --enable write and read
	addra=>	pc_a,
	addrb=> i_pc_h(11 DOWNTO 0),
	douta=> opc,
	doutb=> doutb
); 
    not_wait <= (not i_wait) or i_prog_mem_we;
    
	pc0: process(i_clk)
	begin
		if (rising_edge(i_clk)) then
			if i_prog_mem_we = '0' then
				o_pc <= i_pc;
				pm_adr_0 <= i_prog_mem_adr(0);
--				if ((i_wait = '0')) then
--					pc_0 <= i_pc(0);
--				end if;
			end if;
		end if;
	end process;
	-- pc 
 
	pc_a <= i_pc(11 DOWNTO 0) when i_prog_mem_we = '0' else i_prog_mem_adr;
	o_opc <= opc when i_prog_mem_we = '0' else (others =>'0');
	o_opc_h<= doutb;
	
    prog_mem_data <= opc;
    -- used to read data from program memory
    o_prog_mem_out <= prog_mem_data(7 DOWNTO 0) when (pm_adr_0 = '0')	else prog_mem_data(15 DOWNTO 8);

end Behavioral;
