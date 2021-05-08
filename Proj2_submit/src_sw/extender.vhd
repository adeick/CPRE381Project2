-------------------------------------------------------------------------
-- Andrew Deick
-- Department of Software Engineering
-- Iowa State University
-------------------------------------------------------------------------


-- extender.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: 
--
--
-- NOTES:
-- 8/19/16 by JAZ::Design created.
-- 11/25/19 by H3:Changed name to avoid name conflict with Quartus
--          primitives.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

entity extender is
  port(i_I          : in std_logic_vector(15 downto 0);     -- Data value input
	   i_C			: in std_logic; --0 for zero, 1 for signextension
       o_O          : out std_logic_vector(31 downto 0));   -- Data value output

end extender;

architecture behavior of extender is
 
 --signal s1 : std_logic;
 
begin
	process (i_I, i_C)
	begin
		for i in 0 to 15 loop
			o_O(i) <= i_I(i);
		end loop;
		for i in 16 to 31 loop
			o_O(i) <= (i_I(15) and i_C);
		end loop;
	end process;
end behavior;
