-------------------------------------------------------------------------
-- John Brose
-------------------------------------------------------------------------


-- dffg_N.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file contains an implementation of a positive edge 
-- d-flip-flop with parallel access and reset
--
-- NOTES:
-- 2/11/21 by JB::Design created.
-------------------------------------------------------------------------
-- library declaration
library IEEE;
use IEEE.std_logic_1164.all;

-- entity
entity MIPS_pc is
  --generic(N : integer := 32); -- Generic of type integer for input/output data width. Default value is 32.
  port(i_CLK        : in std_logic;     -- Clock input
       i_RST        : in std_logic;     -- Reset input
       --i_WE         : in std_logic;     -- Write enable input
       i_D          : in std_logic_vector(31 downto 0);     -- Data value input
       o_Q          : out std_logic_vector(31 downto 0));   -- Data value output
end MIPS_pc;

-- architecture
architecture structural of MIPS_pc is

  component MIPS_pc_dffg is
  port(i_CLK        : in std_logic;     -- Clock input
       i_RST        : in std_logic;     -- Reset input
       i_RST_data   : in std_logic;     -- Write enable input
       i_D          : in std_logic;     -- Data value input
       o_Q          : out std_logic);   -- Data value output
  end component;

  signal s_RST_data : std_logic_vector(31 downto 0) := X"00400000";

begin

  -- Instantiate N dff instances.
  G_NBit_DFFG: for i in 0 to 31 generate
    ONESCOMPI: MIPS_pc_dffg port map(
              i_CLK     => i_CLK,  -- every dff has the same clock
	      i_RST	=> i_RST,  -- parallel rst
	      i_RST_data=> s_RST_data(i),   -- parallel write enable
	      i_D	=> i_D(i), -- N bit long dff reg input
              o_Q       => o_Q(i));-- N bit long dff reg output
  end generate G_NBit_DFFG;
  
end structural;