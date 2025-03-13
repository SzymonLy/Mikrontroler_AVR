library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.std_logic_ARITH.ALL;
use IEEE.std_logic_UNSIGNED.ALL;

use work.CPU_intruction_set.ALL;

entity CPU_data_path is
    port(   i_clk         		: IN  STD_LOGIC;
            i_alu_opcode    	: IN  STD_LOGIC_VECTOR( 4 DOWNTO 0);
            i_addr_mode    : IN  STD_LOGIC_VECTOR( 5 DOWNTO 0);
            i_opc_2       	: IN  STD_LOGIC_VECTOR( 3 DOWNTO 0);
            i_addr_a     		: IN  STD_LOGIC_VECTOR( 4 DOWNTO 0);
            i_data_mem       : IN  STD_LOGIC_VECTOR( 7 DOWNTO 0);
            i_data_imm       	: IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
            i_jump_addr      	: IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
            i_opcode       		: IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
            i_pc        		: IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
            i_pc_opcode     	: IN  STD_LOGIC_VECTOR( 2 DOWNTO 0);
            i_prog_mem_sel      : IN  STD_LOGIC;  -- program memory select
            i_rd_mem      		: IN  STD_LOGIC;
            i_addr_b     		: IN  STD_LOGIC_VECTOR( 4 DOWNTO 0);
            i_alu_imm_sel     : IN  STD_LOGIC_VECTOR( 1 DOWNTO 0);
            i_we_reg_01     	: IN  STD_LOGIC;
            i_we_reg_a      	: IN  STD_LOGIC_VECTOR( 1 DOWNTO 0);
            i_we_flag      		: IN  STD_LOGIC;
            i_we_dm      		: IN  STD_LOGIC_VECTOR( 1 DOWNTO 0);
            i_we_xyzs   		: IN  STD_LOGIC;
 
            o_addr       		: OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            o_data      		: OUT STD_LOGIC_VECTOR( 7 DOWNTO 0);
            o_interrupt_ena   	: OUT STD_LOGIC;       
            o_load_new_pc   	: OUT STD_LOGIC;
            o_new_pc    		: OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            o_opc       		: OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            o_pc        		: OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            o_rd_io    		 	: OUT STD_LOGIC;
            o_skip_instr      	: OUT STD_LOGIC;
            o_we_io     		: OUT STD_LOGIC;
            o_inter_done    	: out  STD_LOGIC
            );
end CPU_data_path;

architecture Behavioral of CPU_data_path is

component CPU_ALU
    port (  i_alu_opcode    	: IN  STD_LOGIC_VECTOR( 4 DOWNTO 0);
            i_opc_2       	: IN  STD_LOGIC_VECTOR( 3 DOWNTO 0);
            i_data_a         	: IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
            i_addr_a_0        	: IN  STD_LOGIC;
            i_data_mem       : IN  STD_LOGIC_VECTOR( 7 DOWNTO 0);
            i_flag_data     	: IN  STD_LOGIC_VECTOR( 7 DOWNTO 0);
            i_data_imm       	: IN  STD_LOGIC_VECTOR( 7 DOWNTO 0);
            i_pc        		: IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
            i_data_b         	: IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
            i_addr_b_0        	: IN  STD_LOGIC;
            i_alu_imm_sel     : IN  STD_LOGIC_VECTOR( 1 DOWNTO 0);
			o_inter_done    	: out  STD_LOGIC;
            o_flags_data     	: OUT STD_LOGIC_VECTOR( 7 DOWNTO 0);
            o_skip_SBIS     	: OUT STD_LOGIC_VECTOR( 1 DOWNTO 0);
            o_data      		: OUT STD_LOGIC_VECTOR(15 DOWNTO 0));
end component;

signal alu_data_out           	: STD_LOGIC_VECTOR(15 DOWNTO 0);
signal alu_flags_out         	: STD_LOGIC_VECTOR( 7 DOWNTO 0);
signal skip_SBIS         		: STD_LOGIC_VECTOR( 1 DOWNTO 0);

component CPU_registers
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
            i_we_dm      		: IN  STD_LOGIC;
            i_we_xyzs   		: IN  STD_LOGIC;

            o_addr       		: OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            o_opc_2        	: OUT STD_LOGIC;
            o_data_a         	: OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            o_flags_data     	: OUT STD_LOGIC_VECTOR( 7 DOWNTO 0);
            o_data_b         	: OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            o_c_data        	: OUT STD_LOGIC_VECTOR( 7 DOWNTO 0);
            o_z_data        	: OUT STD_LOGIC_VECTOR(15 DOWNTO 0));
end component;

component CPU_exec_logic 
 port( 
	i_clk		 	: in STD_LOGIC;
	i_pc_opcode 	: IN  STD_LOGIC_VECTOR( 2 DOWNTO 0);
	i_opc_2 		: IN  STD_LOGIC;
	i_alu_flags_out : IN  STD_LOGIC_VECTOR( 7 DOWNTO 0);
	i_skip_SBIS 	: IN  STD_LOGIC_VECTOR( 1 DOWNTO 0);
	i_data_addr 	: IN  STD_LOGIC_VECTOR( 15 DOWNTO 0);
	i_we_dm      	: IN  STD_LOGIC_VECTOR( 1 DOWNTO 0);
	i_data_mem		: IN  STD_LOGIC_VECTOR( 7 DOWNTO 0);
	i_data_c 		: IN  STD_LOGIC_VECTOR( 7 DOWNTO 0);
	i_prog_mem_sel	: IN  STD_LOGIC;
	i_data_mem_a_out: IN  STD_LOGIC_VECTOR( 15 DOWNTO 0);
	i_data_z		: IN  STD_LOGIC_VECTOR( 15 DOWNTO 0);
	i_rd_mem 		: IN  STD_LOGIC;
	i_jump_addr		: IN  STD_LOGIC_VECTOR( 15 DOWNTO 0); 
	
	o_data_mem 	: out STD_LOGIC_VECTOR( 7 DOWNTO 0);
	o_new_pc 		: out STD_LOGIC_VECTOR( 15 DOWNTO 0);
	o_we_io 		: out STD_LOGIC;
	o_rd_io 		: out STD_LOGIC;
	o_load_new_pc 	: out STD_LOGIC;
	o_skip_instr 	: out STD_LOGIC;
	o_data_mem_we_a : out STD_LOGIC_VECTOR( 1 DOWNTO 0)
   );
end component;

signal data_addr            : STD_LOGIC_VECTOR(15 DOWNTO 0);
signal opc_2             	: STD_LOGIC;
signal data_a              	: STD_LOGIC_VECTOR(15 DOWNTO 0);
signal flags          		: STD_LOGIC_VECTOR( 7 DOWNTO 0);
signal data_b              	: STD_LOGIC_VECTOR(15 DOWNTO 0);
signal data_io              	: STD_LOGIC_VECTOR( 7 DOWNTO 0);
signal data_z              	: STD_LOGIC_VECTOR(15 DOWNTO 0);
    
component CPU_data_mem
    port (      
		clka 	: IN STD_LOGIC;
		ena 	: IN STD_LOGIC;
		wea 	: IN STD_LOGIC_VECTOR(1 DOWNTO 0);
		addra 	: IN STD_LOGIC_VECTOR(11 DOWNTO 0);
		dina 	: IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		douta 	: OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
    );
end component;

signal data_mem_a_out       : STD_LOGIC_VECTOR(15 DOWNTO 0);
signal data_mem_a_out_first : STD_LOGIC_VECTOR(15 DOWNTO 0);
signal data_mem_a_input     : STD_LOGIC_VECTOR(15 DOWNTO 0);
signal data_mem       		: STD_LOGIC_VECTOR( 7 DOWNTO 0); -- from multiplexer to alu
signal data_mem_we_a        : STD_LOGIC_VECTOR(1 DOWNTO 0);


begin

    ALU : CPU_ALU
    port map(   i_alu_opcode   	=>i_alu_opcode,
                i_opc_2      	=>i_opc_2,
                i_data_a       	=>data_a,
                i_addr_a_0     	=>i_addr_a(0),
                i_data_mem  	=>data_mem,
                i_flag_data    	=>flags,
                i_data_imm    	=>i_data_imm(7 DOWNTO 0),
                i_pc       		=>i_pc,
                i_data_b        =>data_b,
                i_addr_b_0      =>i_addr_b(0),
                i_alu_imm_sel =>i_alu_imm_sel,
 				o_inter_done    =>o_inter_done,
                o_flags_data    =>alu_flags_out,
                o_skip_SBIS		=>skip_SBIS, 
                o_data     		=>alu_data_out);

    REGISTERS : CPU_registers
    port map(   i_clk=>i_clk,
                i_addr_mode			=>i_addr_mode,
                i_status_reg_addr(3)=>i_opcode(10),
                i_status_reg_addr(2 DOWNTO 0)=>i_opcode(2 DOWNTO 0),
                i_addr_a 			=>i_addr_a,
                i_input_data 		=>alu_data_out,
                i_flag_data			=>alu_flags_out(7 DOWNTO 0),
                i_data_imm			=>i_data_imm,
                i_addr_b 			=>i_addr_b(4 DOWNTO 1),
                i_we_reg_01			=>i_we_reg_01,
                i_we_reg_a			=>i_we_reg_a,
                i_we_flag 			=>i_we_flag,
                i_we_dm			=>i_we_dm(0),
                i_we_xyzs			=>i_we_xyzs,

                o_addr 				=>data_addr,
                o_opc_2       		=>opc_2,
                o_data_a        	=>data_a,
                o_flags_data    	=>flags,
                o_data_b        	=>data_b,
                o_c_data        	=>data_io,   
                o_z_data        	=>data_z);

    DATA_MEM_module : CPU_data_mem
    port map(   clka   	=>i_clk, --clkb=>i_clk,
                addra  	=> data_addr(11 DOWNTO 0),
               -- addrb 	=> (others=>'0'), --placeholder
                dina   	=>data_mem_a_input,
                --dinb 	=>(others=>'0'), --placeholder
                ena    	=>'1', --enable read, write and reset
                --enb 	=>'0',
				wea 	=>data_mem_we_a,-- enable write
				--web 	=>(others=>'0'),
                douta 	=>data_mem_a_out_first
               -- doutb 	=>open
    );
    -- if the adrres is even, the input and output data has to be swaped
    data_mem_a_out <= 
    		data_mem_a_out_first(7 downto 0) & data_mem_a_out_first(15 downto 8) when data_addr(0) = '1' 
    		else data_mem_a_out_first(15 downto 8) & data_mem_a_out_first(7 downto 0);

    data_mem_a_input <= 
    		alu_data_out(7 downto 0) & alu_data_out(15 downto 8) when data_addr(0) = '1'
    	 	else alu_data_out(15 downto 8) & alu_data_out(7 downto 0);


	EXECUTION_UNIT:CPU_exec_logic
	port map(
		i_clk=>i_clk,
		i_pc_opcode=>i_pc_opcode,
		i_opc_2=>opc_2,
		i_alu_flags_out=>alu_flags_out,
		i_skip_SBIS=>skip_SBIS,
		i_data_addr=>data_addr,
		i_we_dm  =>i_we_dm,
		i_data_mem=>i_data_mem,
		i_data_c=>data_io,
		i_prog_mem_sel=>i_prog_mem_sel,
		i_data_mem_a_out=>data_mem_a_out,
		i_data_z	=>data_z,
		i_rd_mem 	=>i_rd_mem,
		i_jump_addr	=>i_jump_addr,
		
		o_data_mem =>data_mem,
		o_new_pc 	=>o_new_pc,
		o_we_io 		=>o_we_io,
		o_rd_io 		=>o_rd_io,
		o_load_new_pc 	=>o_load_new_pc,
		o_skip_instr 	=>o_skip_instr,
		o_data_mem_we_a =>data_mem_we_a
	); 
    o_addr     <= data_addr;
    o_data    <= alu_data_out(7 DOWNTO 0);
    o_interrupt_ena <= alu_flags_out(7);
    o_opc     <= i_opcode;
    o_pc      <= i_pc;


end Behavioral;
