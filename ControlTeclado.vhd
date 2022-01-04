----------------------------------------------------------------------------------
-- Company: Universidad Complutense de Madrid, Facultad de Informática
-- Engineer: Fabrizio Alcaraz Escobar
-- 
-- Module Name: ControlTeclado - Behavioral
-- Project Name: Controlador de teclado
-- Description: 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity ControlTeclado is
      Port (    PS2CLK: in std_logic;
                PS2DATA: in std_logic;
                scancode: out std_logic_vector (7 downto 0);
                nueva_tecla: out std_logic; 
                teclDer: out std_logic;
                teclIzq: out std_logic);
end ControlTeclado;

architecture Behavioral of ControlTeclado is
signal newKey: std_logic;
signal tecla: std_logic_vector(7 downto 0);
signal lectura: std_logic_vector(20 downto 0);
begin
scancode <= tecla;
newKey <= '1' when lectura(7 downto 0) = "11110000" else '0';
nueva_tecla <= newKey;
teclDer <= '1' when tecla = x"74" else '0';
teclIzq <= '1' when tecla = x"6b" else '0';

-- Registro para guardar el último scancode recibido
r_tecla:process(newKey)
begin
    if rising_edge(newKey) then
        tecla <= lectura(18 downto 11);
    end if;
end process r_tecla;

-- Registro con desplazamiento para leer los bits obtenidos por PS2DATA
sr_lectura:process(PS2CLK)
begin
if falling_edge(PS2CLK) then
    lectura <= PS2DATA & lectura(20 downto 1);
end if;
end process sr_lectura;

end Behavioral;
