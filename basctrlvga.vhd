library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity vgacore is
	port
	(
		reset: in std_logic;	
		clk_in: in std_logic;
		hsyncb: buffer std_logic;	
		vsyncb: out std_logic;	
		rgb: out std_logic_vector(11 downto 0) 
	);
end vgacore;

architecture vgacore_arch of vgacore is

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
    
    component imagen_vhga is
        Port ( px : in STD_LOGIC_VECTOR(10 downto 0);
                py: in STD_LOGIC_VECTOR (10 downto 0);
                clock_1Hz: in STD_LOGIC;
                rgb: out STD_LOGIC_VECTOR (11 downto 0)  );
     end component imagen_vhga;

signal hcnt: std_logic_vector(10 downto 0);	
signal vcnt: std_logic_vector(9 downto 0);	

signal clock: std_logic;  --este es el pixel_clock

signal disp_area : std_logic;
signal salRGB: STD_LOGIC_VECTOR (11 downto 0);
signal clk_1Hz: STD_LOGIC;
signal px, py: STD_LOGIC_VECTOR (10 downto 0);

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

-- A partir de aqui implementar los módulos que faltan, necesarios para dibujar en el monitor

divisor_frec: clock_divider port map (clock_100MHZ => clk_in, reset => reset,dividendo(25 downto 1) => (others => '0'),dividendo(0) => '1' , clock_out => clock); -- Componente que fija el pixel clock
div_1Hz: clock_divider port map (clock_100MHZ => clk_in, reset => reset,dividendo=> "10111110101111000010000000" , clock_out => clk_1Hz); -- Componente para fijar un reloj de 1Hz, util para el componente imagen_vhga
imagen: imagen_vhga port map (px => px, py => py, clock_1Hz => clk_1Hz, rgb => salRGB); -- Componente para visualizar imágenes
salidaRGB: mux_2a1 port map (e1 => (others => '0'), e2 => salRGB, sel => disp_area, sal => rgb); -- Multiplexor que muestra colores cuando se encuentra en el "display zone", en caso contrario pone a 0s


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

p_r_px: process(clock,reset)    -- Contador de pixel en X , útil para el componente imagen_vhga 
begin
if reset = '1' then
    px <= (others => '0');
elsif rising_edge(clock) then
    if (hcnt >= 184 and hcnt < 984) then
        px <= px + 1;
    else 
        px <= (others => '0');
    end if;
end if;
end process p_r_px;

p_r_py: process(hsyncb,reset) -- Contador de pixel en Y , útil para el componente imagen_vhga 
begin
if reset = '1' then
    py <= (others => '0');
elsif rising_edge(hsyncb) then
    if (vcnt >= 29 and vcnt < 629) then
        py <= py + 1;
    else 
        py <= (others => '0');
    end if;
end if;
end process p_r_py;

end vgacore_arch;


