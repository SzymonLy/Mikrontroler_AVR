

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity CPU_Core is
    port (  i_clk       		: IN  STD_LOGIC;
            i_rst       		: IN  STD_LOGIC;
            i_interrupt_vec    	: IN  STD_LOGIC_VECTOR( 5 DOWNTO 0);
            i_data       : IN  STD_LOGIC_VECTOR( 7 DOWNTO 0);
            o_opc       		: out STD_LOGIC_VECTOR(15 DOWNTO 0);
            o_pc        		: out STD_LOGIC_VECTOR(15 DOWNTO 0);-- used to debug
            o_data      		: out STD_LOGIC_VECTOR( 7 DOWNTO 0);
            o_addr_io   		: out STD_LOGIC_VECTOR( 4 DOWNTO 0);
            o_rd_io     		: out STD_LOGIC;
            o_we_io     		: out STD_LOGIC;
            o_inter_done		: out STD_LOGIC;
            --writing program memory
            i_rst_pm			: IN  STD_LOGIC;
            i_prog_mem_addr		: IN  STD_LOGIC_VECTOR(11 DOWNTO 0);
            i_prog_mem_we		: IN  STD_LOGIC;
            i_prog_mem_data		: IN  STD_LOGIC_VECTOR( 15 DOWNTO 0)
            );
end CPU_Core;

architecture Behavioral of CPU_Core is

component CPU_opc_fetch
    port(   i_clk       		: IN  STD_LOGIC;

            i_rst, i_rst_pm		: IN  STD_LOGIC;
            i_interrupt_vec    	: IN  STD_LOGIC_VECTOR( 4 DOWNTO 0);
            i_interrupt_en		: IN  STD_LOGIC;
            i_pc_new    		: IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
            i_load_new_pc   	: IN  STD_LOGIC;
            i_prog_mem_adr    	: IN  STD_LOGIC_VECTOR(11 DOWNTO 0);
            i_skip      		: IN  STD_LOGIC;

            o_opc       		: out STD_LOGIC_VECTOR(15 DOWNTO 0);
            o_opc_h       		: out STD_LOGIC_VECTOR(15 DOWNTO 0);
            o_pc        		: out STD_LOGIC_VECTOR(15 DOWNTO 0);
            o_prog_mem_out   	: out STD_LOGIC_VECTOR( 7 DOWNTO 0);
            o_first_cycle       : out STD_LOGIC;
            
            i_prog_mem_we		: IN  STD_LOGIC;
            i_prog_mem_data		: IN  STD_LOGIC_VECTOR( 15 DOWNTO 0)
            
            );
end component;

signal cpu_enable 		: STD_LOGIC;  
signal pc             : STD_LOGIC_VECTOR(15 DOWNTO 0);
signal opcode         : STD_LOGIC_VECTOR(15 DOWNTO 0);
signal opc_h         : STD_LOGIC_VECTOR(15 DOWNTO 0);
signal prog_mem_out   : STD_LOGIC_VECTOR( 7 DOWNTO 0);
signal first_cycle    : STD_LOGIC;  --'1' on first cycle in two cycle instuction

component CPU_opc_deco is
    port (  i_clk       		: IN  STD_LOGIC;
            i_opcode       		: IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
            i_opc_h       		: IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
            i_pc        		: IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
            i_first_cycle   	: IN  STD_LOGIC;

            o_alu_opcode    	: out STD_LOGIC_VECTOR( 4 DOWNTO 0);
            o_addr_mode     	: out STD_LOGIC_VECTOR( 5 DOWNTO 0);
            o_opc_pc       	: out STD_LOGIC_VECTOR( 3 DOWNTO 0);
            o_reg1_addr     	: out STD_LOGIC_VECTOR( 4 DOWNTO 0);
            o_immidiate_data    : out STD_LOGIC_VECTOR(15 DOWNTO 0);
            o_jump_addr      	: out STD_LOGIC_VECTOR(15 DOWNTO 0);
            o_opc       		: out STD_LOGIC_VECTOR(15 DOWNTO 0);
            o_pc        		: out STD_LOGIC_VECTOR(15 DOWNTO 0);
            o_pc_opcode     	: out STD_LOGIC_VECTOR( 2 DOWNTO 0);
            o_prog_mem_sel      : out STD_LOGIC;  -- program memory select
            o_data_mem_read     : out STD_LOGIC;
            o_reg2_addr     	: out STD_LOGIC_VECTOR( 4 DOWNTO 0);
            o_alu_im_sel : out STD_LOGIC_VECTOR( 1 DOWNTO 0);
            o_we_01_regs     	: out STD_LOGIC;
            o_we_a_regs      	: out STD_LOGIC_VECTOR( 1 DOWNTO 0);
            o_we_status     : out STD_LOGIC;
            o_we_mem      		: out STD_LOGIC_VECTOR( 1 DOWNTO 0);
            o_we_xyzs   		: out STD_LOGIC);
end component;

signal alu_opcode         	: STD_LOGIC_VECTOR( 4 DOWNTO 0);
signal addr_mode           	: STD_LOGIC_VECTOR( 5 DOWNTO 0);
signal opc_status            	: STD_LOGIC_VECTOR( 3 DOWNTO 0);
signal reg1_addr          	: STD_LOGIC_VECTOR( 4 DOWNTO 0);
signal immidiate_data       : STD_LOGIC_VECTOR(15 DOWNTO 0);
signal jump_addr           	: STD_LOGIC_VECTOR(15 DOWNTO 0);
signal opc            		: STD_LOGIC_VECTOR(15 DOWNTO 0);
signal pc1             		: STD_LOGIC_VECTOR(15 DOWNTO 0);
signal pc_opc          		: STD_LOGIC_VECTOR(2 DOWNTO 0);
signal program_mem_sel      : STD_LOGIC;
signal data_mem_rd          : STD_LOGIC;
signal reg2_addr          	: STD_LOGIC_VECTOR( 4 DOWNTO 0);
signal alu_im_sel    : STD_LOGIC_VECTOR( 1 DOWNTO 0);
signal we_01_regs          	: STD_LOGIC;
signal we_a_regs           	: STD_LOGIC_VECTOR( 1 DOWNTO 0);
signal we_status           	: STD_LOGIC;
signal we_dm          	 	: STD_LOGIC_VECTOR( 1 DOWNTO 0);
signal we_xyzs        		: STD_LOGIC;

component CPU_data_path
    port(   i_clk       		: IN    STD_LOGIC;

            i_alu_opcode    	: IN  STD_LOGIC_VECTOR( 4 DOWNTO 0);
            i_addr_mode    : IN  STD_LOGIC_VECTOR( 5 DOWNTO 0);
            i_opc_2       	: IN  STD_LOGIC_VECTOR( 3 DOWNTO 0);
            i_addr_a     		: IN  STD_LOGIC_VECTOR( 4 DOWNTO 0);
            i_data_mem       : IN  STD_LOGIC_VECTOR( 7 DOWNTO 0);
            i_data_imm       	: IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
            i_jump_addr      	: IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
            i_pc_opcode     		: IN  STD_LOGIC_VECTOR( 2 DOWNTO 0);
            i_opcode       		: IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
            i_pc        		: IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
            i_prog_mem_sel      : IN  STD_LOGIC;  -- program memory select
            i_rd_mem      		: IN  STD_LOGIC;
            i_addr_b     		: IN  STD_LOGIC_VECTOR( 4 DOWNTO 0);
            i_alu_imm_sel     : IN  STD_LOGIC_VECTOR( 1 DOWNTO 0);
            i_we_reg_01     	: IN  STD_LOGIC;
            i_we_reg_a      	: IN  STD_LOGIC_VECTOR( 1 DOWNTO 0);
            i_we_flag      		: IN  STD_LOGIC;
            i_we_dm      		: IN  STD_LOGIC_VECTOR( 1 DOWNTO 0);
            i_we_xyzs   		: IN  STD_LOGIC;
 
            o_addr       		: out STD_LOGIC_VECTOR(15 DOWNTO 0);
            o_data      		: out STD_LOGIC_VECTOR( 7 DOWNTO 0);
            o_interrupt_ena   	: out STD_LOGIC;
            o_load_new_pc   	: out STD_LOGIC;
            o_new_pc    		: out STD_LOGIC_VECTOR(15 DOWNTO 0);
            o_opc       		: out STD_LOGIC_VECTOR(15 DOWNTO 0);
            o_pc        		: out STD_LOGIC_VECTOR(15 DOWNTO 0);
            o_rd_io     		: out STD_LOGIC;
            o_skip_instr      	: out STD_LOGIC;
            o_we_io     		: out STD_LOGIC;
            o_inter_done		: out STD_LOGIC);
end component;

signal interrupt_ena        	: STD_LOGIC; --interrupt enable
signal pc_new         			: STD_LOGIC_VECTOR(15 DOWNTO 0);
signal load_new_pc        		: STD_LOGIC; --when '1' pc_new will be loaded 
signal skip           			: STD_LOGIC;
signal we_io           			: STD_LOGIC;
signal rd_io           			: STD_LOGIC;
signal addr_out            		: STD_LOGIC_VECTOR(15 DOWNTO 0);
signal data_out            		: STD_LOGIC_VECTOR(7 DOWNTO 0);
signal prog_addr            	: STD_LOGIC_VECTOR(11 DOWNTO 0);

-- local signals
--
signal status_data            	: STD_LOGIC_VECTOR( 7 DOWNTO 0);
signal interrupt_vec_5       	: STD_LOGIC;


	component ila_1 is
  Port ( 
    clk: in STD_LOGIC;
   probe0 : 		 in std_logic_vector(0 downto 0);
   probe1 : 		 in std_logic_vector(0 downto 0);
   probe2 : 	in std_logic_vector(5 downto 0);
    probe3 : in STD_LOGIC_VECTOR ( 7 downto 0 );
    probe4 : in STD_LOGIC_VECTOR ( 15 downto 0 );
    probe5 : in STD_LOGIC_VECTOR ( 15 downto 0 );
    probe6 : in std_logic_vector(7 downto 0);
    probe7 : in std_logic_vector(4 downto 0);
    probe8 : in std_logic_vector(0 downto 0);
    probe9 : in std_logic_vector(0 downto 0)
  );
  end component;
begin

	cpu_ila : ila_1
	port map ( 
		clk=>		i_clk,
		probe0(0)=>i_clk,
		probe1(0)=> i_rst,
		probe2=>	i_interrupt_vec,
		probe3=>	i_data,
		probe4=>	opcode,
		probe5=>	pc,
		probe6=>	data_out,
		probe7=>	addr_out(4 DOWNTO 0),
		probe8(0)=> rd_io,
		probe9(0)=> we_io
	); 
	
	prog_addr <= i_prog_mem_addr when i_prog_mem_we = '1' else addr_out(11 DOWNTO 0);
	
    Pobieranie_instrukcji : CPU_opc_fetch
    port map(   i_clk=>i_clk,
                i_rst=>i_rst,
                i_rst_pm=>i_rst_pm,
                i_interrupt_en=>interrupt_ena,
                i_interrupt_vec(4 DOWNTO 0)=>i_interrupt_vec(4 DOWNTO 0),
                i_load_new_pc=>load_new_pc,
                i_pc_new=>pc_new,
                i_prog_mem_adr=>prog_addr,
                i_skip=>skip,

                o_pc=>pc,
                o_opc=>opcode,
                o_opc_h =>opc_h,
                o_first_cycle=>first_cycle,
                o_prog_mem_out=>prog_mem_out,
                
                i_prog_mem_we=>i_prog_mem_we,
            	i_prog_mem_data=>i_prog_mem_data	
            );
 
    Dekodowanie_kodu : CPU_opc_deco
    port map(   i_clk=>i_clk,

                i_opcode=>opcode,
                i_opc_h=>opc_h,
                i_pc=>pc,
                i_first_cycle=>first_cycle,

                o_alu_opcode=>alu_opcode,
                o_addr_mode=>addr_mode,
                o_opc_pc=>opc_status,
                o_reg1_addr=>reg1_addr,
                o_immidiate_data=>immidiate_data,
                o_jump_addr=>jump_addr,
                o_opc=>opc,
                o_pc=>pc1,
                o_pc_opcode=>pc_opc,
                o_prog_mem_sel=>program_mem_sel,
                o_data_mem_read=>data_mem_rd,
                o_reg2_addr=>reg2_addr,
                o_alu_im_sel=>alu_im_sel,
                o_we_01_regs=>we_01_regs,
                o_we_a_regs=>we_a_regs,
                o_we_status=>we_status,
                o_we_mem=>we_dm,
                o_we_xyzs=>we_xyzs);

    Wykonywanie : CPU_data_path
    port map(   i_clk=>i_clk,

                i_alu_opcode=>alu_opcode,
                i_addr_mode=>addr_mode,
                i_opc_2=>opc_status,
                i_addr_a=>reg1_addr,
                i_data_mem=>status_data,
                i_data_imm=>immidiate_data,
                i_jump_addr=>jump_addr,
                i_opcode=>opc,
                i_pc=>pc1,
                i_pc_opcode=>pc_opc,
                i_prog_mem_sel=>program_mem_sel,
                i_rd_mem=>data_mem_rd,
                i_addr_b=>reg2_addr,
                i_alu_imm_sel=>alu_im_sel,
                i_we_reg_01=>we_01_regs,
                i_we_reg_a=>we_a_regs,
                i_we_flag=>we_status,
                i_we_dm=>we_dm,
                i_we_xyzs=>we_xyzs,

                o_addr=>addr_out,
                o_data=>data_out,
                o_interrupt_ena=>interrupt_ena,
                o_new_pc=>pc_new,
                o_opc=>o_opc,
                o_pc=>o_pc,
                o_load_new_pc=>load_new_pc,
                o_rd_io=>rd_io,
                o_skip_instr=>skip,
                o_we_io=>we_io,
                o_inter_done=>o_inter_done
                );

    status_data <= prog_mem_out when (program_mem_sel = '1') else i_data(7 DOWNTO 0);
    o_addr_io <= addr_out(4 DOWNTO 0);
    o_data <= data_out;
    o_rd_io <= rd_io;
    o_we_io <= we_io;
    
end Behavioral;
