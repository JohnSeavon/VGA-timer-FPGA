LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY PixelGen IS
		
	generic( 
				f	: integer := 1	--	generico para definir a frequencia de atualização do relogio	
	);

	PORT(
		RESET : IN STD_LOGIC; -- Entrada para reiniciar o estado do controlador
		F_CLOCK : IN STD_LOGIC; -- Entrada de clock (50 MHz)
		F_ON : IN STD_LOGIC; --Indica a região ativa do frame
		F_ROW : IN STD_LOGIC_VECTOR(9 DOWNTO 0); -- Índice da linha que está sendo processada
		F_COLUMN : IN STD_LOGIC_VECTOR(10 DOWNTO 0); -- Índice da coluna que está sendo processada
		R_OUT : OUT STD_LOGIC_VECTOR (0 TO 3); -- Componente R
		G_OUT : OUT STD_LOGIC_VECTOR (0 To 3); -- Componente G
		B_OUT : OUT STD_LOGIC_VECTOR (0 TO 3)-- Componente B
	);

END ENTITY PixelGen;

ARCHITECTURE arch OF PixelGen IS

		
COMPONENT font_rom IS
		port(
			clk: in std_logic;
			addr: in std_logic_vector(10 downto 0);
			data: out std_logic_vector(7 downto 0)
		);
	END COMPONENT font_rom;
	
	--Coordenadas X e Y do pixel atual
   SIGNAL pix_x, pix_y: UNSIGNED(9 DOWNTO 0);
	
	--Endereço que será acessado na memória de caracteres
   SIGNAL rom_addr: STD_LOGIC_VECTOR(10 DOWNTO 0);
	
	--Código ASCII do caractere atual (parte do endereço)
   SIGNAL char_addr: STD_LOGIC_VECTOR(6 DOWNTO 0);
	
	--Parte do caractere (0~15) que está sendo exibida na linha atual Y
   SIGNAL row_addr: STD_LOGIC_VECTOR(3 DOWNTO 0);
	
	--Pixel relativo a coordenada X atual
   SIGNAL bit_addr: STD_LOGIC_VECTOR(2 DOWNTO 0);
	
	--Conteúdo armazenado no endereço indicado por 'rom_addr'
   SIGNAL font_word: STD_LOGIC_VECTOR(7 DOWNTO 0);
	
	--Valor do bit 'bit_addr' na palavra 'font_word'
   SIGNAL font_bit: STD_LOGIC;
	
	--Valor das componentes rgb
   SIGNAL font_rgb: STD_LOGIC_VECTOR(2 DOWNTO 0);
	
	--Flag que indica se a frase deve ser exibida
   SIGNAL txt_on: STD_LOGIC;

	-- sinais inteiros auxiliares
	signal h_d 		  : integer range 0 to 2 := 0;		
	signal h_u		  : integer range 0 to 9 := 0; 
	signal m_d 		  : integer range 0 to 6 := 0;		
	signal m_u		  : integer range 0 to 9 := 0; 
	signal s_d 		  : integer range 0 to 6 := 0;		
	signal s_u		  : integer range 0 to 9 := 0; 
	
	signal s		  	  : integer range 0 to 50000000 := 0; 
	
	signal hora_d 	  : std_LOGIC_VECTOR (6 downto 0) := "0110000"; -- sinal hora dezena
	signal hora_u 	  : std_LOGIC_vector (6 downto 0) := "0110000";	-- sinal hora unidade
	signal minuto_d  : std_LOGIC_VECTOR (6 downto 0) := "0110000";	-- sinal minuto dezena
	signal minuto_u  : std_LOGIC_vector (6 downto 0) := "0110000";	-- sinal minuto unidade
	signal segundo_d : std_LOGIC_VECTOR (6 downto 0) := "0110000";	-- sinal segundo dezena
	signal segundo_u : std_LOGIC_vector (6 downto 0) := "0110000";	-- sinal segundo unidade
	
BEGIN
	
	contador_signal: process(F_CLOCK,reset,s,hora_d,hora_u,minuto_d,minuto_u,segundo_d,segundo_u,h_d,h_u,m_d,m_u,s_d,s_u) -- neste processo realiza-se a logica de atuzalização do tempo, com o auxilo dos contadores dezena e unidade
	
	begin
	
	if 	reset = '0' then			-- chave de reset em nivel baixo
			-- limpa todos os contadores
			hora_d <= "0110000";
			h_d <= 0;
			hora_u <= "0110000";
			h_u <= 0;
			minuto_d <= "0110000";
			m_d <= 0;
			minuto_u <= "0110000";
			m_u <= 0;
			segundo_d <= "0110000";
			s_d <= 0;
			segundo_u <= "0110000";
			s_u <= 0;
			
	elsif F_CLOCK'event and F_CLOCK = '1' then	-- calculo d clock com a frequencia desejada
			s <= s + 1;
			if s = (50000000/(f*1)) then
				s <= 0;
				s_u <= s_u + 1;
				segundo_u <= std_LOGIC_VECTOR (unsigned(segundo_u) + 1); -- incrementa 1  de acordo com a frequencia desejada
				
				if	s_u = 9 then	-- limpa o estouro do segundo unidade e acrescenta no segundo dezena
					s_d <= s_d + 1;
					segundo_d <= std_LOGIC_VECTOR (unsigned(segundo_d) + 1);
					s_u <= 0;
					segundo_u <= "0110000";
				end if;
				
				if s_d = 5 then		-- limpa o estouro do segundo unidade e segundo dezena
					if s_u = 9 then
						s_d <= 0;
						segundo_d <= "0110000";
						s_u <= 0;
						segundo_u <= "0110000";
						m_u <= m_u + 1;
					   minuto_u <= std_LOGIC_VECTOR (unsigned(minuto_u) + 1);
					end if;
				end if;
				
				if	m_u = 9 and s_d = 5 and s_u = 9 then	--condição do incremento no minuto dezena para 9 minutos e 59 segundos
					m_d <= m_d + 1;
					minuto_d <= std_LOGIC_VECTOR (unsigned(minuto_d) + 1);
					m_u <= 0;
					minuto_u <= "0110000";
				end if;
				
				if m_d = 5  then		-- condição de 59 minutos e 59 segundos
					if m_u = 9 and s_d = 5 and s_u = 9 then
						m_d <= 0;
						minuto_d <= "0110000";
						m_u <= 0;
						minuto_u <= "0110000";
						h_u <= h_u + 1;
					   hora_u <= std_LOGIC_VECTOR (unsigned(hora_u) + 1);
					end if;
				end if;
				
				if	h_u = 10  then	-- limpa o estouro da hora unidade e acrescenta na hora dezena
					h_d <= h_d + 1;
					hora_d <= std_LOGIC_VECTOR (unsigned(hora_d) + 1);
					h_u <= 0;
					hora_u <= "0110000";
				end if;
				
				if h_d = 2 then		-- limpa o estouro do final do dia
					if h_u = 4 then
						h_d <= 0;
						hora_d <= "0110000";
						h_u <= 0;
						hora_u <= "0110000";
						m_d <= 0;
						minuto_d <= "0110000";
						m_u <= 0;
						minuto_u <= "0110000";
						s_d <= 0;
						segundo_d <= "0110000";
						s_u <= 0;
						segundo_u <= "0110000";
					end if;
				end if;
				
			end if;
		end if;
	end process;	

	-- Coordenadas XY atuais
	pix_x <= UNSIGNED(F_COLUMN(9 DOWNTO 0));
	pix_y <= UNSIGNED(F_ROW);
	
	-- Memória dos caracteres
	font_unit: font_rom PORT MAP(clk=>not F_CLOCK, addr=>rom_addr, data=>font_word);
	
	-- Determinação do endereço que será acessado
	row_addr <= STD_LOGIC_VECTOR(pix_y(3 DOWNTO 0));
	rom_addr <= char_addr & row_addr;
	
   txt_on <= '1' WHEN (pix_x >= 320 AND pix_x <= 455) AND (pix_y >= 290 AND pix_y <= 305) ELSE
              '0';
				  
   WITH pix_x(7 DOWNTO 3) SELECT
     char_addr <=
				hora_d		WHEN "01000", -- hora dezena
				hora_u		WHEN "01001", -- hora unidade
				"0111010" 	WHEN "01010", -- :
				minuto_d 	WHEN "01011", -- minuto dezena
				minuto_u 	WHEN "01100", -- minuto unidade
				"0111010" 	WHEN "01101", -- :
				segundo_d   WHEN "01110", -- segundo dezena
				segundo_u 	WHEN "01111", -- segundo unidade
				"0000000" WHEN OTHERS;
   
	
	bit_addr <= NOT STD_LOGIC_VECTOR(pix_x(2 DOWNTO 0));
	font_bit <= font_word(to_integer(UNSIGNED( bit_addr))); 
	
	font_rgb <="111" WHEN font_bit='1' ELSE "000";

	PROCESS(F_ON,font_rgb,txt_on)
	BEGIN
		
		IF F_ON ='0' or txt_on='0' THEN
			 R_OUT <= "0000";
			 G_OUT <= "0000";
			 B_OUT <= "0000";
		ELSE
			 R_OUT(0) <= font_rgb(0);
			 R_OUT(1) <= font_rgb(0);
			 R_OUT(2) <= font_rgb(0);
			 R_OUT(3) <= font_rgb(0);
			 
			 G_OUT(0) <= font_rgb(1); 
			 G_OUT(1) <= font_rgb(1);
			 G_OUT(2) <= font_rgb(1); 
			 G_OUT(3) <= font_rgb(1);
			 
			 B_OUT(0) <= font_rgb(2);	
			 B_OUT(1) <= font_rgb(2);
			 B_OUT(2) <= font_rgb(2);	
			 B_OUT(3) <= font_rgb(2);		
			 
		END IF;
	END PROCESS; 
	
END ARCHITECTURE arch;