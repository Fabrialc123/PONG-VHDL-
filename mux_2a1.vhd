----------------------------------------------------------------------------------
-- Company: Universidad Complutense de Madrid, Facultad de Informática
-- Engineer: Fabrizio Alcaraz Escobar 
-- 
-- Create Date: 11.04.2021 23:03:36
-- Design Name: 
-- Module Name: mux_2a1 - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: Multiplexor de 2 entradas a 1 salida
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity mux_2a1 is
  Port ( e1: in STD_LOGIC_VECTOR(11 downto 0);
            e2: in STD_LOGIC_VECTOR (11 downto 0);
            sel: in STD_LOGIC;
            sal: out STD_LOGIC_VECTOR (11 downto 0) );
end mux_2a1;

architecture Behavioral of mux_2a1 is

begin
sal <= e1 when sel='0' else 
            e2 when sel='1'  else
            (others => '1');
end Behavioral;
