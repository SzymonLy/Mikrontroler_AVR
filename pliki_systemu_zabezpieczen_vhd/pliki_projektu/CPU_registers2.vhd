library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

use work.CPU_intruction_set.ALL;

entity CPU_registers2 is
    port (  i_clk       		: IN  STD_LOGIC;
            i_addr_mode    : IN  STD_LOGIC_VECTOR( 5 DOWNTO 0);
            i_status_reg_addr   : IN  STD_LOGIC_VECTOR( 3 DOWNTO 0);
            i_input_data        : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
            i_flag_data     	: IN  STD_LOGIC_VECTOR( 7 DOWNTO 0);
            i_data_imm       	: IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
            i_addr_a     		: IN  STD_LOGIC_VECTOR( 4 DOWNTO 0);
            i_addr_b      		: IN  STD_LOGIC_VECTOR( 4 DOWNTO 1);
            
            i_we_reg_01     	: IN  STD_LOGIC;
            i_we_reg_a      	: IN  STD_LOGIC_VECTOR( 1 DOWNTO 0);
            i_we_flag      		: IN  STD_LOGIC;
            i_we_io      		: IN  STD_LOGIC;
            i_we_xyzs   		: IN  STD_LOGIC;

            o_addr       		: OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            o_opc_2        	: OUT STD_LOGIC;
            o_data_a         	: OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            o_flags_data     	: OUT STD_LOGIC_VECTOR( 7 DOWNTO 0);
            o_data_b         	: OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            o_c_data         	: OUT STD_LOGIC_VECTOR( 7 DOWNTO 0);
            o_z_data         	: OUT STD_LOGIC_VECTOR(15 DOWNTO 0));
end CPU_registers2;

architecture Behavioral of CPU_registers2 is

component reg_16
    port (  i_clk		: IN    STD_LOGIC;
            i_data_a    : IN    STD_LOGIC_VECTOR(15 DOWNTO 0);
            i_we        : IN    STD_LOGIC_VECTOR( 1 DOWNTO 0);
            o_data      : OUT   STD_LOGIC_VECTOR(15 DOWNTO 0));
end component;

component CPU_status_regs is
    port (  i_clk       		: IN  STD_LOGIC;
            i_status_reg_addr  	:  IN  STD_LOGIC_VECTOR ( 3 DOWNTO 0);
            i_data_mem       : IN  STD_LOGIC_VECTOR ( 7 DOWNTO 0);
            i_flag_data     	: IN  STD_LOGIC_VECTOR ( 7 DOWNTO 0);
            i_we_flag      		: IN  STD_LOGIC;
            i_status_we     	: IN  STD_LOGIC;
            o_data           	: OUT STD_LOGIC_VECTOR ( 7 DOWNTO 0);
            o_opc_2        	: OUT STD_LOGIC);
end component;

component Regs_mem IS
  PORT (
    clka : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    clkb : IN STD_LOGIC;
    web : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    addrb : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    dinb : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    doutb : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
  );
end component Regs_mem;

   signal  wea :  STD_LOGIC_VECTOR(1 DOWNTO 0);
   signal addra :  STD_LOGIC_VECTOR(3 DOWNTO 0);
   signal dina :  STD_LOGIC_VECTOR(15 DOWNTO 0);
   signal douta :  STD_LOGIC_VECTOR(15 DOWNTO 0);
   signal web :  STD_LOGIC_VECTOR(1 DOWNTO 0);
   signal addrb :  STD_LOGIC_VECTOR(3 DOWNTO 0);
   signal dinb :  STD_LOGIC_VECTOR(15 DOWNTO 0);
   signal doutb :  STD_LOGIC_VECTOR(15 DOWNTO 0);
   
	signal flags_data          		: STD_LOGIC_VECTOR( 7 DOWNTO 0);
	signal status_we         		: STD_LOGIC;
	
	signal x_input_data             : STD_LOGIC_VECTOR(15 DOWNTO 0);
	signal y_input_data             : STD_LOGIC_VECTOR(15 DOWNTO 0);
	signal z_input_data             : STD_LOGIC_VECTOR(15 DOWNTO 0);

	signal regX_data            	: STD_LOGIC_VECTOR(15 DOWNTO 0);
	signal regY_data            	: STD_LOGIC_VECTOR(15 DOWNTO 0);
	signal regZ_data            	: STD_LOGIC_VECTOR(15 DOWNTO 0);
	signal regSP_data          	 	: STD_LOGIC_VECTOR(15 DOWNTO 0);  
	
	signal xyzs_we        			: STD_LOGIC_VECTOR(31 DOWNTO 0);
	signal x_we           			: STD_LOGIC;
	signal y_we           			: STD_LOGIC;
	signal z_we           			: STD_LOGIC;
	signal we_sp          			: STD_LOGIC_VECTOR( 1 DOWNTO 0);
	signal regs_we          		: STD_LOGIC_VECTOR( 5 DOWNTO 0);
	signal xyzs_value           	: STD_LOGIC_VECTOR(15 DOWNTO 0);
	
begin

	my_regs_mem:  Regs_mem 
	port map(
		clka=>i_clk, clkb=>i_clk, 
		wea=>wea,
		addra=>addra,
		dina=>dina,
		douta=>douta,
		web=>web,
		addrb=>addrb,
		dinb=>dinb,
		doutb=>doutb
	);
	my_status_reg: CPU_status_regs
    port map(   i_clk      			=>i_clk,
                i_status_reg_addr   =>i_status_reg_addr,
                i_data_mem      	=>i_input_data(7 DOWNTO 0),
                i_flag_data    		=>i_flag_data,
                i_we_flag     		=>i_we_flag,
                i_status_we    		=>status_we,
                o_data          	=>flags_data,
                o_opc_2       	=>o_opc_2);

	regX: 	reg_16 port map(i_clk=>i_clk, i_we=>regs_we(1 downto 0), i_data_a=>x_input_data,  o_data=>regX_data);
    regY: 	reg_16 port map(i_clk=>i_clk, i_we=>regs_we(3 DOWNTO 2), i_data_a=>y_input_data,  o_data=>regY_data);
    regZ: 	reg_16 port map(i_clk=>i_clk, i_we=>regs_we(5 DOWNTO 4), i_data_a=>z_input_data,  o_data=>regZ_data);
    regSP:  reg_16 port map(i_clk=>i_clk, i_we=>we_sp,            i_data_a=>sp_input_data, o_data=>regSP_data);
    
	--X,Y,Z,sp -- special registers
	--web<=
	--dinb<= i_input_data;
	
	o_data_b<=doutb;
	
	
	addra<=i_addr_a;
	o_data_a<= douta;
	dina<= i_input_data;
	wea<=i_we_reg_a;
	    -- the base value of the X/Y/Z/SP register as per i_addr_mode
    process(i_addr_mode(2 DOWNTO 0), i_data_imm)
    begin
        case i_addr_mode(2 DOWNTO 0) is
        
        	
            when AS_SP =>base_value <= reg_sp;
            when AS_Z  =>
            	addrb <= "1111";
            	base_value<=doutb;
            when AS_Y  =>
           	 	addrb <= "1110";
           	 	base_value<=doutb;
            when AS_X  =>
           		addrb <= "1101";
           		base_value<=doutb;
            when AS_IMM=>
            	addrb<=i_addr_b;
            	base_value <= i_data_imm;
            when others=>
            	base_value <= X"0000";
            	addrb<=i_addr_b;
        end case;
    end process;

    -- the value of the X/Y/Z/SP register after a potential PRE-inc/decrement
    -- (by 1 or 2) and POST-inc/decrement (by 1 or 2)
    process(i_addr_mode, i_data_imm)
    begin
        case i_addr_mode is
            when AMOD_Xq | AMOD_Yq | AMOD_Zq =>
                preicrementation_value <= i_data_imm;      postincrementation_value <= X"0000";
            when AMOD_Xi | AMOD_Yi | AMOD_Zi =>
                preicrementation_value <= X"0000";    postincrementation_value <= X"0001";
            when AMOD_dX  | AMOD_dY  | AMOD_dZ =>
                preicrementation_value <= X"FFFF";    postincrementation_value <= X"FFFF";
            when AMOD_iSP=>
                preicrementation_value <= X"0001";    postincrementation_value <= X"0001";
            when AMOD_iiSP=>
                preicrementation_value <= X"0001";    postincrementation_value <= X"0002";
            when AMOD_SPd=>
                preicrementation_value <= X"0000";    postincrementation_value <= X"FFFF";
            when AMOD_SPdd=>
                preicrementation_value <= X"FFFF";    postincrementation_value <= X"FFFE";
            when others=>
                preicrementation_value <= X"0000";    postincrementation_value <= X"0000";
        end case;
    end process;

    xyzs_value <= base_value + postincrementation_value; --posticremenctation
    addr_c_reg  <= base_value + preicrementation_value; --preincrementation
    
    a_we <= i_we_io when (addr_c_reg(15 DOWNTO 5) = "00000000000") else '0';
    status_we    <= i_we_io when (addr_c_reg = X"005F") else '0';
    sp_we_mode <= i_we_xyzs when (i_addr_mode(2 DOWNTO 0) = AS_SP) else '0';
    we_sp(1) <= i_we_io when (addr_c_reg = X"005E") else sp_we_mode;
    we_sp(0) <= i_we_io when (addr_c_reg = X"005D") else sp_we_mode;

    x_input_data  <= xyzs_value when (xyzs_we(26) = '1')        else i_input_data;
    y_input_data  <= xyzs_value when (xyzs_we(28) = '1')        else i_input_data;
    z_input_data  <= xyzs_value when (xyzs_we(30) = '1')        else i_input_data;
    sp_input_data <= xyzs_value when (i_addr_mode(3 DOWNTO 0) = AM_WS) else i_input_data;

end Behavioral;
