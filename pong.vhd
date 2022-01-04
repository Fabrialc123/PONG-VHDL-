----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 24.04.2021 20:59:09
-- Design Name: 
-- Module Name: pong - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
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
use IEEE.std_logic_unsigned.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity pong is
 Port ( reset: in std_logic;	
		clkFPGA: in std_logic;
		PS2CLK: in std_logic;
		PS2DATA: in std_logic;
		hsyncb: buffer std_logic;	
		vsyncb: out std_logic;	
		rgb: out std_logic_vector(11 downto 0);
		seg: out std_logic_vector(6 downto 0) );
end pong;

architecture Behavioral of pong is
  component clock_divider is
      Port ( clock_100MHz: in STD_LOGIC;
                reset: in STD_LOGIC;
                dividendo : in STD_LOGIC_VECTOR (25 downto 0);
                clock_out: out STD_LOGIC );
    end component clock_divider;
    
    component mux_2a1 is
      Port ( e1: in STD_LOGIC_VECTOR(11 downto 0);
                e2: in STD_LOGIC_VECTOR (11 downto 0);
                sel: in STD_LOGIC;
                sal: out STD_LOGIC_VECTOR (11 downto 0) );
    end component mux_2a1;
    
    component ControlTeclado is
      Port (    PS2CLK: in std_logic;
                PS2DATA: in std_logic;
                scancode: out std_logic_vector (7 downto 0);
                nueva_tecla: out std_logic; 
                teclDer: out std_logic;
                teclIzq: out std_logic);
    end component ControlTeclado;
    
    component conv_7seg is
        Port ( x : in  STD_LOGIC_VECTOR (3 downto 0);
               display : out  STD_LOGIC_VECTOR (6 downto 0));
    end component conv_7seg;
    
    component miRAM8w12b is
      Port ( clkFPGA: in std_logic;
                we: in std_logic;
                addr: in std_logic_vector (2 downto 0);
                data_in: in std_logic_vector (11 downto 0);
                data_out: out std_logic_vector (11 downto 0) );
     end component miRAM8w12b;

signal hcnt: std_logic_vector(10 downto 0);	
signal vcnt: std_logic_vector(9 downto 0);	

signal clock: std_logic;  --este es el pixel_clock

signal disp_area : std_logic;
signal salRGB: STD_LOGIC_VECTOR (11 downto 0);

signal teclDer, teclIzq: std_logic;
signal px: std_logic_vector(10 downto 0);   -- Pixel X a pintar
signal py: std_logic_vector(9 downto 0);    -- Pixel Y a pintar
--- SEÑALES PARA LOS BORDES ---
signal bordeIzq,bordeDer: std_logic_vector(10 downto 0);
signal bordeArr: std_logic_vector(9 downto 0);
signal colorBorde: STD_LOGIC_VECTOR (11 downto 0);
--- SEÑALES PARA LA PELOTA ----
type ESTS_PELOTA is (DAI, DAD, DBI, DBD);    -- Diagonal Arriba/Bajo Izquierda/Derecha
signal EST_PELOTA, SIG_EST_PELOTA: ESTS_PELOTA;
signal clk_pelota: std_logic;
signal pxi_pelota,pxd_pelota: std_logic_vector(10 downto 0); -- Coordenadas en X de la pelota
signal pya_pelota,pyb_pelota: std_logic_vector(9 downto 0); -- Coordenadas en Y de la pelota
signal colorPelota: STD_LOGIC_VECTOR (11 downto 0);
--- SEÑALES PARA LA BARRA ----
type ESTS_BARRA is (DERECHA, IZQUIERDA, QUIETO);    
signal EST_BARRA, SIG_EST_BARRA: ESTS_BARRA;
signal clk_barra: std_logic;
signal pxi_barra,pxd_barra: std_logic_vector(10 downto 0);  -- Coordenadas en X de la barra
signal pya_barra,pyb_barra: std_logic_vector(9 downto 0);   -- Coordenadas en Y de la barra
signal colorBarra: STD_LOGIC_VECTOR (11 downto 0);

signal enPuntuacion: std_logic;
signal puntuacion: std_logic_vector(2 downto 0);

begin

A: process(clock,reset) -- Es el contador de pixeles horizontales
begin
	-- reset asynchronously clears pixel counter
	if reset='1' then
		hcnt <= (others => '0');
	-- horiz. pixel counter increments on rising edge of dot clock
	elsif (clock'event and clock='1') then
		-- horiz. pixel counter rolls-over after 1040 pixels
		if hcnt<1040 then
			hcnt <= hcnt + 1;
		else
			hcnt <= (others => '0');
		end if;
	end if;
end process;


B: process(hsyncb,reset)    -- Es el contador de filas 
begin
	-- reset asynchronously clears line counter
	if reset='1' then
		vcnt <= (others => '0');
	-- vert. line counter increments after every horiz. line
	elsif (hsyncb'event and hsyncb='1') then
		-- vert. line counter rolls-over after 666 lines
		if vcnt<666 then
			vcnt <= vcnt + 1;
		else
			vcnt <= (others => '0');
		end if;
	end if;
end process;


C: process(clock,reset)     -- Es el comparador encargado de indicar el momento en el que se sincroniza horizontalmente
begin
	-- reset asynchronously sets horizontal sync to inactive
	if reset='1' then
		hsyncb <= '1';
	-- horizontal sync is recomputed on the rising edge of every dot clock
	elsif (clock'event and clock='1') then
		-- horiz. sync is low in this interval to signal start of a new line
		if (hcnt>=0 and hcnt<120) then
			hsyncb <= '0';
		else
			hsyncb <= '1';
		end if;
	end if;
end process;

D: process(hsyncb,reset)    -- Comparador que activa la señal de sincronización vertical
begin
	-- reset asynchronously sets vertical sync to inactive
	if reset='1' then
		vsyncb <= '1';
	-- vertical sync is recomputed at the end of every line of pixels
	elsif (hsyncb'event and hsyncb='1') then
		-- vert. sync is low in this interval to signal start of a new frame
		if (vcnt>=0 and vcnt<6) then
			vsyncb <= '0';
		else
			vsyncb <= '1';
		end if;
	end if;
end process;

div_imagen: clock_divider port map (clock_100MHZ => clkFPGA, reset => reset,dividendo(25 downto 1) => (others => '0'),dividendo(0) => '1' , clock_out => clock); -- Componente que fija el pixel clock

p_display_area: process(clock, reset)   -- Comparador que indica el momento en el que se deben de pasar los colores a mostrar en pantalla
begin
if reset = '1' then
    disp_area <= '0';
elsif rising_edge(clock) then
    if (hcnt >= 184 and hcnt < 984) and (vcnt >= 29 and vcnt < 629) then
        disp_area <= '1';
    else disp_area <= '0';
    end if;
end if;
end process p_display_area;

-- A partir de aqui implementar los módulos que faltan, necesarios para dibujar en el monitor

div_pelota: clock_divider port map (clock_100MHZ => clkFPGA, reset => reset,dividendo=> "00000101111101011110000100" , clock_out => clk_pelota); 
div_barra: clock_divider port map (clock_100MHZ => clkFPGA, reset => reset,dividendo=> "00001011111010111100001000" , clock_out => clk_barra);
salidaRGB: mux_2a1 port map (e1 => (others => '0'), e2 => salRGB, sel => disp_area, sal => rgb); -- Multiplexor que muestra colores cuando se encuentra en el "display zone", en caso contrario pone a 0s
teclado: ControlTeclado port map(PS2CLK => PS2CLK, PS2DATA => PS2DATA, scancode => open, nueva_tecla => open, teclDer => teclDer, teclIzq => teclIzq);
memColores: miRAM8w12b port map(clkFPGA => clkFPGA, we => '0', addr => puntuacion, data_in => (others => '0'), data_out => colorBorde);
display: conv_7seg port map (x(3) => '0', x(2 downto 0) => puntuacion, display => seg);

px <= (others => '0') when hcnt < 184 else hcnt - 184;
py <= (others => '0') when vcnt < 29 else vcnt - 29;

bordeIzq <= "00000001010";
bordeDer <= "01100010110";
bordeArr <= "0000001010";

--colorBorde <= "111100001111";
colorPelota <= (others => '1');
colorBarra <= "111100000000";

salRGB <= colorBorde when ((px < bordeIzq) or (px > bordeDer) or (py < bordeArr)) else
          colorPelota when ((px >= pxi_pelota) and ( px <= pxd_pelota) and ( py >= pya_pelota) and (py <= pyb_pelota)) else
          colorBarra when ((px >= pxi_barra) and (px <= pxd_barra) and (py >= pya_barra) and (py <= pyb_barra)) else
          (others => '0');
          

--p_dib_borde:process (px,py,bordeIzq,bordeDer,bordeArr)
--begin
--if ((px < bordeIzq) or (px > bordeDer) or (py < bordeArr)) then
--    salRGB <= colorBorde;
--end if;
--end process p_dib_borde;

               ----------  GESTIÓN DE LA PELOTA    -------------
               
p_cambioest_pelota: process (clkFPGA, reset)
begin
    if reset = '1' then
        EST_PELOTA <= DAD;
    elsif rising_edge(clkFPGA) then
        EST_PELOTA <= SIG_EST_PELOTA;
    end if;
end process p_cambioest_pelota;

p_dir_pelota: process(EST_PELOTA, pxi_pelota, pxd_pelota, pya_pelota, pyb_pelota, pya_barra, pxi_barra, pxd_barra)
begin
enPuntuacion <= '0';
case EST_PELOTA is
    when DAI =>       
        if (pya_pelota = bordeArr) then
            SIG_EST_PELOTA <= DBI;
        elsif (pxi_pelota = bordeIzq) then
          SIG_EST_PELOTA <= DAD;          
        else SIG_EST_PELOTA <= DAI;
        end if;        
    when DAD =>
        if (pya_pelota = bordeArr) then
            SIG_EST_PELOTA <= DBD;   
        elsif (pxd_pelota = bordeDer) then
          SIG_EST_PELOTA <= DAI;          
        else SIG_EST_PELOTA <= DAD;
        end if;     
    when DBI =>
        if (pya_barra=pyb_pelota) and ((pxi_barra <= pxd_pelota and pxd_barra >= pxd_pelota) or (pxi_barra >= pxi_pelota and pxi_barra <= pxd_pelota) or (pxd_barra >= pxi_pelota and pxd_barra <= pxd_pelota)) then
          enPuntuacion <= '1';
          SIG_EST_PELOTA <= DAI;
        elsif (pxi_pelota = bordeIzq) then
          SIG_EST_PELOTA <= DBD;
        else SIG_EST_PELOTA <= DBI;
        end if;
    when DBD =>
        if (pya_barra=pyb_pelota) and ((pxi_barra <= pxd_pelota and pxd_barra >= pxd_pelota) or (pxi_barra >= pxi_pelota and pxi_barra <= pxd_pelota) or (pxd_barra >= pxi_pelota and pxd_barra <= pxd_pelota)) then
          enPuntuacion <= '1';
          SIG_EST_PELOTA <= DAD;
        elsif (pxd_pelota = bordeDer) then
          SIG_EST_PELOTA <= DBI;          
        else SIG_EST_PELOTA <= DBD;
        end if;    
    when others => SIG_EST_PELOTA <= DAI;
end case;
end process p_dir_pelota;

p_mov_pelota: process(EST_PELOTA, clk_pelota, reset)
begin
if (reset = '1') then
    pxi_pelota <= "00110001101";
    pxd_pelota <= "00110010011";
    pya_pelota <= "0001100100";
    pyb_pelota <= "0001101010";
elsif (rising_edge(clk_pelota)) then
    case EST_PELOTA is
        when DAI =>
            pxi_pelota <= pxi_pelota - 1;
            pxd_pelota <= pxd_pelota - 1;
            pya_pelota <= pya_pelota - 1;
            pyb_pelota <= pyb_pelota - 1;
        when DAD =>
            pxi_pelota <= pxi_pelota + 1;
            pxd_pelota <= pxd_pelota + 1;
            pya_pelota <= pya_pelota - 1;
            pyb_pelota <= pyb_pelota - 1;        
        when DBI =>
            pxi_pelota <= pxi_pelota - 1;
            pxd_pelota <= pxd_pelota - 1;
            pya_pelota <= pya_pelota + 1;
            pyb_pelota <= pyb_pelota + 1;        
        when DBD =>
            pxi_pelota <= pxi_pelota + 1;
            pxd_pelota <= pxd_pelota + 1;
            pya_pelota <= pya_pelota + 1;
            pyb_pelota <= pyb_pelota + 1;
        when others =>
     end case;
end if;
end process p_mov_pelota;

--p_dib_pelota: process(px,py,pxi_pelota,pxd_pelota,pya_pelota,pyb_pelota)
--begin
--if ((px >= pxi_pelota) and ( px <= pxd_pelota) and ( py >= pya_pelota) and (py <= pyb_pelota)) then
--    salRGB <= (others => '0');
--end if;
--end process p_dib_pelota;

               ----------  GESTIÓN DE LA BARRA    -------------

p_cambioest_barra: process (clkFPGA, reset)
begin
    if reset = '1' then
        EST_BARRA <= QUIETO;
    elsif rising_edge(clkFPGA) then
        EST_BARRA <= SIG_EST_BARRA;
    end if;
end process p_cambioest_barra;

p_dir_barra: process(EST_BARRA, teclDer, teclIzq)
begin
case EST_BARRA is
    when QUIETO =>
        if (teclDer = '1') then
            SIG_EST_BARRA <= DERECHA;
        elsif (teclIzq = '1') then
            SIG_EST_BARRA <= IZQUIERDA;
        else SIG_EST_BARRA <= QUIETO;
        end if;       
    when DERECHA =>
        if (teclDer = '1') then
            SIG_EST_BARRA <= DERECHA;
        elsif (teclIzq = '1') then
            SIG_EST_BARRA <= IZQUIERDA;
        else SIG_EST_BARRA <= QUIETO;
        end if;            
    when IZQUIERDA => 
        if (teclDer = '1') then
            SIG_EST_BARRA <= DERECHA;
        elsif (teclIzq = '1') then
            SIG_EST_BARRA <= IZQUIERDA;
        else SIG_EST_BARRA <= QUIETO;
        end if;      
    when others => SIG_EST_BARRA <= QUIETO;
end case;
end process p_dir_barra;

pya_barra <= "1001000100";
pyb_barra <= "1001001110";
p_mov_barra: process(EST_BARRA, clk_barra, reset)
begin
if (reset = '1') then
    pxi_barra <= "00101110111";
    pxd_barra <= "00110101001";
elsif (rising_edge(clk_barra)) then
    case EST_BARRA is
        when DERECHA =>
            if (pxd_barra > bordeDer) then
                pxi_barra <= "00000001010"; 
                pxd_barra <= "00000111100";
            else 
                pxi_barra <= pxi_barra + 5;
                pxd_barra <= pxd_barra + 5;
             end if;
        when IZQUIERDA =>
            if (pxi_barra < bordeIzq) then
                pxi_barra <= "01011100100"; 
                pxd_barra <= "01100010110";
            else 
                pxi_barra <= pxi_barra - 5;
                pxd_barra <= pxd_barra - 5;
             end if;        
        when others =>
     end case;
end if;
end process p_mov_barra;



r_puntuacion:process(enPuntuacion, reset)
begin
if (reset = '1') then
    puntuacion <= (others => '0');
elsif (rising_edge(enPuntuacion)) then
    puntuacion <= puntuacion + 1;
end if;
end process r_puntuacion;

end Behavioral;
