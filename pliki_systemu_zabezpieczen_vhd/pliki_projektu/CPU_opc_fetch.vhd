library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity CPU_opc_fetch is
    port (  i_clk       		: IN  STD_LOGIC;
            i_rst, i_rst_pm     : IN  STD_LOGIC;
            i_interrupt_vec    	: IN  STD_LOGIC_VECTOR( 4 DOWNTO 0);
            i_interrupt_en		: IN  STD_LOGIC;
            i_load_new_pc   	: IN  STD_LOGIC;
            i_pc_new    		: IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
            i_prog_mem_adr    	: IN  STD_LOGIC_VECTOR(11 DOWNTO 0);
   		    i_skip      		: IN  STD_LOGIC;

            o_opc      			: OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            o_opc_h				: OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            o_pc        		: OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            o_prog_mem_out   	: OUT STD_LOGIC_VECTOR( 7 DOWNTO 0);
            o_first_cycle       : OUT STD_LOGIC;
            
            --writing program memory
            i_prog_mem_we		: IN  STD_LOGIC;
            i_prog_mem_data		: IN  STD_LOGIC_VECTOR( 15 DOWNTO 0));
end CPU_opc_fetch;

architecture Behavioral of CPU_opc_fetch is

component CPU_prog_mem
    port (  i_clk       	: IN  STD_LOGIC;
            i_rst_pm      	: IN  STD_LOGIC;
            i_wait      	: IN  STD_LOGIC;
            i_pc        	: IN  STD_LOGIC_VECTOR (15 DOWNTO 0); -- word address
            i_pc_h        	: IN  STD_LOGIC_VECTOR (15 DOWNTO 0); 
            i_prog_mem_adr  : IN  STD_LOGIC_VECTOR (11 DOWNTO 0); -- byte address
			i_prog_mem_we	: IN  STD_LOGIC;
            i_prog_mem_data	: IN  STD_LOGIC_VECTOR( 15 DOWNTO 0);
            o_opc       	: OUT STD_LOGIC_VECTOR (15 DOWNTO 0);
            o_opc_h       	: OUT STD_LOGIC_VECTOR (15 DOWNTO 0);
            o_pc        	: OUT STD_LOGIC_VECTOR (15 DOWNTO 0);
            o_prog_mem_out  : OUT STD_LOGIC_VECTOR ( 7 DOWNTO 0));
end component;


signal opcode           : STD_LOGIC_VECTOR(15 DOWNTO 0);
signal pc_from_pm       : STD_LOGIC_VECTOR(15 DOWNTO 0);

signal dont_read     	: STD_LOGIC;
signal long_opc			: STD_LOGIC;

signal cpse_bit     	: STD_LOGIC;
signal ret_bit   		: STD_LOGIC;
signal lpm_bit   		: STD_LOGIC;
signal pop_bit   		: STD_LOGIC;
signal sbic_bit       	: STD_LOGIC;
signal sbrc_bit     	: STD_LOGIC;
signal pc             	: STD_LOGIC_VECTOR(15 DOWNTO 0);
signal pc_next        	: STD_LOGIC_VECTOR(15 DOWNTO 0); -- incremented pc, that after one clock cycle will be pc. 
--signal pc_h             : STD_LOGIC_VECTOR(15 DOWNTO 0);
signal pc_h_next        : STD_LOGIC_VECTOR(15 DOWNTO 0);
signal first_cycle      : STD_LOGIC; -- '1' in first cycle, '0' in second cycle of 2 stage instruction
signal first_cycle_bit  : STD_LOGIC;
signal wait_signal      : STD_LOGIC;
signal interrupt      	: STD_LOGIC;

begin

    pamiec_programu : CPU_prog_mem
    port map(   i_clk      		=>i_clk,
    			i_rst_pm		=>i_rst_pm,
                i_wait     		=>wait_signal,
                i_pc       		=>pc_next,
                i_pc_h			=>pc_h_next,
                i_prog_mem_adr  =>i_prog_mem_adr,
                o_opc       	=>opcode,
                o_opc_h       	=>o_opc_h,
                o_pc        	=>pc_from_pm,
                o_prog_mem_out  =>o_prog_mem_out,
                i_prog_mem_we	=>i_prog_mem_we,
                i_prog_mem_data=>i_prog_mem_data
                );
	
    process(i_clk)
    begin
        if (rising_edge(i_clk)) then
            pc <= pc_next;
            --pc_h<=pc_h_next;
            first_cycle <= not wait_signal;
        end if; 
          
    end process;

	 long_opc <= '1' when (((opcode(15 downto 9) = "1001010") and
			(opcode( 3 downto 2) = "11")) -- JMP, CALL
			 or ((opcode(15 downto 10) = "100100") and
			 (opcode( 3 downto 0) = "0000"))) -- LDS, STS
			 else '0';

	
	-- LDD, LD, POP...
	-- Push...
	pop_bit <=	'1' when (opcode(15 DOWNTO 10) = "100100") else '0';

	
    -- 0001 00rd dddd rrrr  CPSE compare skip if equal
    cpse_bit      <= '1' when  (opcode(15 DOWNTO 10) = "000100" )else '0';


    -- 1001 0101 0000 1000 - RET 	return from subrutine
    -- 1001 0101 0001 1000 - RETI 	return from interrupt
    ret_bit <= '1' when ((opcode(15 DOWNTO  5) = "10010101000")
                              and  (opcode( 3 DOWNTO  0) = "1000"))
                    else '0';

    -- 1001 0101 1100 1000 - LPM (i) --Program Memory Constant Addressing but incremeted
    -- 1001 0101 1101 1000 - ELPM
    lpm_bit <= '1' when ((opcode(15 DOWNTO  5) = "10010101110") and  (opcode( 3 DOWNTO  0) = "1000")) else '0';

    -- 1001 1001 AAAA Abbb - SBIC
    -- 1001 1011 AAAA Abbb - SBIS
    sbic_bit <= '1' when ((opcode(15 DOWNTO 10) = "100110") and  (opcode(8) = '1'))else '0';

    -- 1111 110r rrrr 0bbb - SBRC
    -- 1111 111r rrrr 0bbb - SBRS
    sbrc_bit <= '1' when ( opcode(15 DOWNTO  10) = "111111") else '0';

--    wait_signal <=  first_cycle and (not dont_read) and (not interrupt)
--			and (cpse_bit or ret_bit or lpm_bit or sbic_bit  or sbrc_bit);             

--	wait_signal <= (
--		(not dont_read) or (not interrupt) or 
--		( first_cycle and (cpse_bit or ret_bit or lpm_bit or sbic_bit  or sbrc_bit))
--		);
	interrupt <= '0' when (i_interrupt_vec(4 downto 0) = "00000") 
			else '1' when i_interrupt_en = '1'
			else '0';
	
	
	wait_signal <= '0'  when dont_read = '1' 
			else '0'    when interrupt = '1' else 
			first_cycle when first_cycle_bit = '1' 
			else '0';
	first_cycle_bit <= cpse_bit or ret_bit or lpm_bit or sbic_bit  or sbrc_bit or pop_bit;
    dont_read <= i_rst or i_skip;
	
	pc_next <= X"0000"        when (i_rst = '1' or i_prog_mem_we = '1' or i_rst_pm = '1')
		else pc           when (wait_signal = '1' and long_opc = '0')
		else i_pc_new     when (i_load_new_pc = '1')
		--else pc + X"0002" when long_opc = '1' 
		else pc + X"0001";
	pc_h_next <= pc_next + X"0001";
            
	--o_opc_h <= opcode when (long_opc = '1' and first_cycle = '0') else x"0000";
	
	
    o_opc <= X"0000" 		when (dont_read = '1')
        	else opcode     when (interrupt = '0') 
        	else (X"00" & "001" & i_interrupt_vec) when (interrupt = '1') ;    
        	
--    o_opc <= (X"00" & "001" & i_interrupt_vec) 	when (interrupt = '1') 
--    	else  X"0000" 							when (dont_read = '1')
--        else  opcode ;    					
        
    o_pc <= pc_from_pm;
    o_first_cycle <= first_cycle;

end Behavioral;
