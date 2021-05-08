-------------------------------------------------------------------------
-- Andrew Deick
-- Department of Software Engineering
-- Iowa State University
-------------------------------------------------------------------------


--addersubtractor.vhd
-------------------------------------------------------------------------
--
-- NOTES:
-- 2/8/21 Created.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

entity addersubtractor is
  generic(N : integer := 32); -- Generic of type integer for input/output data width. Default value is 32.
  port( nAdd_Sub: in std_logic;
	    i_A 	: in std_logic_vector(N-1 downto 0);
		i_B		: in std_logic_vector(N-1 downto 0);
		o_Y		: out std_logic_vector(N-1 downto 0);
		o_Cout	: out std_logic);

end addersubtractor;

architecture structural of addersubtractor is
	
  component mux2t1_N is generic(N : integer := 32);
	port(i_S		: in std_logic;
		i_D0        : in std_logic_vector(N-1 downto 0);
		i_D1        : in std_logic_vector(N-1 downto 0);
		o_O         : out std_logic_vector(N-1 downto 0));
	end component;
		
  component onesComp is generic(N : integer := 32);
	port(i_I         : in std_logic_vector(N-1 downto 0);
       o_O        : out std_logic_vector(N-1 downto 0));
end component;

  component fullAdder is
     port(i_X0 	: in std_logic;
	   i_X1		: in std_logic;
	   i_Cin	: in std_logic;
	   o_Y		: out std_logic;
	   o_Cout	: out std_logic);
  end component;
  
  signal c : std_logic_vector(N downto 0);
  signal s1, s2 : std_logic_vector(N-1 downto 0);

begin	
  -- Invert the 2nd input and output it in wire s1.
	inverter: onesComp
	port MAP(i_I   => i_B,
			 o_O   => s1);  
  -- Choose whether to use the original X1 or the inverted X1
	addsubctrl: mux2t1_N 
     port MAP(i_S		=> nAdd_sub, 
		i_D0        => i_B,
		i_D1        => s1,
		o_O         => s2);
  
	c(0) <= nAdd_Sub;
	G_fullAdder: for i in 0 to N-1 generate
	fullAdderlist: fullAdder port map(
	   i_X0 	=> i_A(i),
	   i_X1 	=> s2(i),
	   i_Cin	=> c(i),
	   o_Y 		=> o_Y(i),
	   o_Cout	=> c(i+1));
	end generate G_fullAdder;
	o_Cout <= c(N);

  
end structural;
