library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;
use work.CPU_intruction_set.ALL;

entity CPU_exec_logic is
 port( 
	i_clk 			: in STD_LOGIC;
	i_pc_opcode 	: IN  STD_LOGIC_VECTOR( 2 DOWNTO 0);
	i_skip_SBIS 	: IN  STD_LOGIC_VECTOR( 1 DOWNTO 0);
	i_opc_2 		: IN  STD_LOGIC;
	i_alu_flags_out : IN  STD_LOGIC_VECTOR( 7 DOWNTO 0);
	i_data_addr 	: IN  STD_LOGIC_VECTOR( 15 DOWNTO 0);
	i_we_dm      	: IN  STD_LOGIC_VECTOR( 1 DOWNTO 0);
	i_data_mem		: IN  STD_LOGIC_VECTOR( 7 DOWNTO 0);
	i_data_c 		: IN  STD_LOGIC_VECTOR( 7 DOWNTO 0);
	i_prog_mem_sel	: in STD_LOGIC;
	i_data_mem_a_out: IN  STD_LOGIC_VECTOR( 15 DOWNTO 0);
	i_data_z		: IN  STD_LOGIC_VECTOR( 15 DOWNTO 0);
	i_rd_mem 		: IN  STD_LOGIC;
	i_jump_addr		: IN  STD_LOGIC_VECTOR( 15 DOWNTO 0); 
	
	o_data_mem 		:out STD_LOGIC_VECTOR( 7 DOWNTO 0);
	o_new_pc 		:out STD_LOGIC_VECTOR( 15 DOWNTO 0);
	o_we_io 		:out STD_LOGIC;
	o_rd_io 		:out STD_LOGIC;
	o_load_new_pc 	:out STD_LOGIC;
	o_skip_instr 	:out STD_LOGIC;
	o_data_mem_we_a :out STD_LOGIC_VECTOR( 1 DOWNTO 0)
   );
end CPU_exec_logic;

architecture Behavioral of CPU_exec_logic is
	signal skip_SBIS : STD_LOGIC_VECTOR( 1 DOWNTO 0);
begin


    -- if PC should be loaded with NEW_PC or not.
    -- if a branch should be taken or not.
    process(i_pc_opcode, i_opc_2)
    begin
        case i_pc_opcode is
            when PC_CC =>
            	o_load_new_pc <= i_opc_2;   
            when PC_LD_I=>
            	o_load_new_pc <= '1';       
            when PC_LD_Z=>
            	o_load_new_pc <= '1';        
            when PC_LD_S=>
            	o_load_new_pc <= '1';       
            when others =>
            	o_load_new_pc <= '0';    
        end case;
    end process;

    -- if the next instruction should be skipped or not
    process(i_pc_opcode, skip_SBIS, i_opc_2)
    begin
        case i_pc_opcode is
            when PC_CC   	=>
            	o_skip_instr <= i_opc_2;         
            when PC_LD_I  	=>
            	o_skip_instr <= '1';            	
            when PC_LD_Z  	=>
            	o_skip_instr <= '1';            	
            when PC_LD_S  	=>
            	o_skip_instr <= '1';            	
            when PC_SKIP_Z 	=>
            	o_skip_instr <= skip_SBIS(1); 
            when PC_SKIP_T	=>
            	o_skip_instr <= skip_SBIS(0); 
            when others   	=>
            	o_skip_instr <= '0';            	
        end case;
    end process;



    -- remember i_alu_flags_out(9 DOWNTO 8) within the current instruction
    process(i_clk)
    begin
        if (rising_edge(i_clk)) then
            skip_SBIS <= i_skip_SBIS;
        end if;
    end process;
    
    o_rd_io   <= '0'                  when (unsigned(i_data_addr) < X"20")
            else (i_rd_mem and not i_prog_mem_sel) when (unsigned(i_data_addr) < X"5D")
            else '0';
    o_we_io   <= '0'                  when (unsigned(i_data_addr) < X"20")
            else i_we_dm(0)           when (unsigned(i_data_addr) < X"5D")
            else '0';
    o_data_mem_we_a <= "00"   when  (unsigned(i_data_addr) < X"0060") else i_we_dm;
    
    -- compute new PC from Z, SP or IMM.
    o_new_pc <= i_data_z    when i_pc_opcode = PC_LD_Z       	-- IJMP, ICALL
           else i_data_mem_a_out when i_pc_opcode = PC_LD_S  	-- RET, RETI
           else i_jump_addr;                           			-- JMP adr


    o_data_mem     <= i_data_mem  when (i_prog_mem_sel = '1')
            else i_data_c    when  (unsigned(i_data_addr) < X"0020")
            else i_data_mem  when  (unsigned(i_data_addr) < X"005D")
            else i_data_c    when  (unsigned(i_data_addr) < X"0060")
            else i_data_mem_a_out(7 DOWNTO 0);
            
end Behavioral;
