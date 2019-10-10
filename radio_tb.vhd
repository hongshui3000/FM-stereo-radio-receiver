library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_textio.all;
use STD.textio.all;

entity radio_tb is
generic
(
	constant IN_NAME : string(9 downto 1) := "input.dat";
	constant LEFT_NAME : string(8 downto 1) := "left.txt";
	constant RIGHT_NAME : string(9 downto 1) := "right.txt";
	constant CLOCK_PERIOD : time := 10 ns
	--constant DATA_SIZE : integer := 64
);
end entity radio_tb;

architecture behavior of radio_tb is
	type raw_file is file of character;
	function to_slv(c : character) return std_logic_vector is
    begin
        return std_logic_vector(to_unsigned(character'pos(c),8));
    end function to_slv;
	
	signal clock : std_logic := '1';
	signal reset : std_logic := '0';

	signal x_din : std_logic_vector(7 downto 0) := X"00";
	signal x_wr_en: std_logic;
	signal x_full : std_logic;
	signal left_dout: std_logic_vector(31 downto 0) := X"00000000";
	signal left_rd_en: std_logic;
	signal left_empty : std_logic;
	signal right_dout: std_logic_vector(31 downto 0) := X"00000000";
	signal right_rd_en: std_logic;
	signal right_empty : std_logic;

	signal hold_clock : std_logic := '0';
	signal x_write_done : std_logic := '0';
	signal left_read_done : std_logic := '0';
	signal right_read_done : std_logic := '0';
	signal left_errors : integer := 0;
	signal right_errors : integer := 0;

	--constant PI : std_logic_vector(31 downto 0) := X"0000c90f";

	component radio_top
	port
	(
		signal clock : in std_logic;
		signal reset : in std_logic;
		signal x_full: out std_logic;
		signal x_wr_en: in std_logic;
		signal x_din : in std_logic_vector(7 downto 0);
		signal left_audio_empty : out std_logic;
		signal left_audio_rd_en : in std_logic;
		signal left_audio_dout : out std_logic_vector(31 downto 0);
		signal right_audio_empty : out std_logic;
		signal right_audio_rd_en : in std_logic;
		signal right_audio_dout : out std_logic_vector(31 downto 0)
	);
	end component;

	
	begin
	radio_top_inst : component radio_top
	port map
	(
		clock => clock,
		reset => reset,
		x_full => x_full,
		x_wr_en => x_wr_en,
		x_din => x_din,
		left_audio_empty => left_empty,
		left_audio_rd_en => left_rd_en,
		left_audio_dout => left_dout,
		right_audio_empty => right_empty,
		right_audio_rd_en => right_rd_en,
		right_audio_dout => right_dout
	);
	
	clock_process : process
	begin
		clock <= '1';
		wait for (CLOCK_PERIOD / 2);
		clock <= '0';
		wait for (CLOCK_PERIOD / 2);
		if(hold_clock = '1') then
			wait;
		end if;
	end process clock_process;

	reset_process : process
	begin
		reset <= '0';
		wait until (clock = '0');
		wait until (clock = '1');
		reset <= '1';
		wait until (clock = '0');
		wait until (clock = '1');
		reset <= '0';
		wait;
	end process reset_process;

	x_write_process : process
	file x_file : raw_file;
	variable rdx : character;
	variable ln1, ln2 : line;
	variable x : integer := 0;
	begin
		wait until (reset = '1');
		wait until (reset = '0');
		write( ln1, string'("@ ") );
		write( ln1, NOW );
		write( ln1, string'(": Loading file ") );
		write( ln1, IN_NAME );
		write( ln1, string'("...") );
		writeline( output, ln1 );
		file_open(x_file, IN_NAME, read_mode);
		x_wr_en <= '0';
		while ( not ENDFILE( x_file) ) loop
			wait until (clock = '1');
			wait until (clock = '0');
			if ( x_full = '0' ) then
				read( x_file, rdx );

				x_din <= to_slv(rdx);
				x_wr_en <= '1';
			else
				x_wr_en <= '0';
			end if;
		end loop;
		wait until (clock = '1');
		wait until (clock = '0');
		x_wr_en <= '0';
		file_close( x_file );
		x_write_done <= '1';
		wait;
	end process x_write_process;	

	left_read_process : process
	file left_file : text;
	variable rdz : std_logic_vector(31 downto 0);
	variable ln1, ln2 : line;
	variable z : integer := 0;
	variable left_data_read : std_logic_vector (31 downto 0);
	variable left_data_cmp : std_logic_vector (31 downto 0);
	begin
	wait until (reset = '1');
	wait until (reset = '0');
	wait until (clock = '1');
	wait until (clock = '0');
	write( ln1, string'("@ ") );
	write( ln1, NOW );
	write( ln1, string'(": Comparing file ") );
	write( ln1, LEFT_NAME );
	write( ln1, string'("...") );
	writeline( output, ln1 );
	file_open( left_file, LEFT_NAME, read_mode );
	left_rd_en <= '0';
	while ( not ENDFILE(left_file) ) loop
	wait until ( clock = '1');
	wait until ( clock = '0');
	if ( left_empty = '0' ) then
	left_rd_en <= '1';
	readline( left_file, ln2 );
	hread( ln2, rdz );
	left_data_cmp := rdz(31 downto 0);
	left_data_read := left_dout;
	if ( to_01(unsigned(left_data_read)) /=
	to_01(unsigned(left_data_cmp)) ) then
	left_errors <= left_errors + 1;
	write( ln2, string'("@ ") );
	write( ln2, NOW );
	write( ln2, string'(": ") );
	write( ln2, LEFT_NAME );
	write( ln2, string'("(") );
	write( ln2, z + 1 );
	write( ln2, string'("): ERROR: ") );
	hwrite( ln2, left_data_read );
	write( ln2, string'(" != ") );
	hwrite( ln2, left_data_cmp );
	write( ln2, string'(" at address 0x") );
	hwrite( ln2, std_logic_vector(to_unsigned(z,32)) );
	write( ln2, string'(".") );
	writeline( output, ln2 );
	end if;
	z := z + 1;
	else
	left_rd_en <= '0';
	end if;
	end loop;
	wait until (clock = '1');
	wait until (clock = '0');
	left_rd_en <= '0';
	file_close( left_file );
	left_read_done <= '1';
	wait;
	end process left_read_process;

	right_read_process : process
	file right_file : text;
	variable rdz : std_logic_vector(31 downto 0);
	variable ln1, ln2 : line;
	variable z : integer := 0;
	variable right_data_read : std_logic_vector (31 downto 0);
	variable right_data_cmp : std_logic_vector (31 downto 0);
	begin
	wait until (reset = '1');
	wait until (reset = '0');
	wait until (clock = '1');
	wait until (clock = '0');
	write( ln1, string'("@ ") );
	write( ln1, NOW );
	write( ln1, string'(": Comparing file ") );
	write( ln1, RIGHT_NAME );
	write( ln1, string'("...") );
	writeline( output, ln1 );
	file_open( right_file, RIGHT_NAME, read_mode );
	right_rd_en <= '0';
	while ( not ENDFILE(right_file) ) loop
	wait until ( clock = '1');
	wait until ( clock = '0');
	if ( right_empty = '0' ) then
	right_rd_en <= '1';
	readline( right_file, ln2 );
	hread( ln2, rdz );
	right_data_cmp := rdz(31 downto 0);
	right_data_read := right_dout;
	if ( to_01(unsigned(right_data_read)) /=
	to_01(unsigned(right_data_cmp)) ) then
	right_errors <= right_errors + 1;
	write( ln2, string'("@ ") );
	write( ln2, NOW );
	write( ln2, string'(": ") );
	write( ln2, RIGHT_NAME );
	write( ln2, string'("(") );
	write( ln2, z + 1 );
	write( ln2, string'("): ERROR: ") );
	hwrite( ln2, right_data_read );
	write( ln2, string'(" != ") );
	hwrite( ln2, right_data_cmp );
	write( ln2, string'(" at address 0x") );
	hwrite( ln2, std_logic_vector(to_unsigned(z,32)) );
	write( ln2, string'(".") );
	writeline( output, ln2 );
	end if;
	z := z + 1;
	else
	right_rd_en <= '0';
	end if;
	end loop;
	wait until (clock = '1');
	wait until (clock = '0');
	right_rd_en <= '0';
	file_close( right_file );
	right_read_done <= '1';
	wait;
	end process right_read_process;

	tb_process: process
		variable errors : integer := 0;
		variable warnings : integer := 0;
		variable start_time : time;
		variable end_time: time;
		variable in1, in2, in3, in4 : line;
	begin
		wait until (reset = '1');
		wait until (reset = '0');
		wait until (clock = '0');
		wait until (clock = '1');
		start_time := NOW;
		write( in1, string'("@ ") );
		write( in1, start_time);
		write( in1, string'(": Beginning simulation...") );
		writeline( output, in1 );
		
		wait until (clock = '0');
		wait until (clock = '1');
		wait until (right_read_done = '1' and left_read_done = '1');
		--wait until ( left_read_done = '1');
		end_time := NOW;
		write( in2, string'("@ ") );
		write( in2, end_time);
		write( in2, string'(": Simulation completed.") );
		writeline( output, in2 );
		errors := left_errors + right_errors;
		
		write(in3, string'("Total simulation cycle count: "));
		write(in3, (end_time - start_time)/CLOCK_PERIOD);
		writeline(output, in3);
		write(in4, string'("Total error count: "));
		write(in4, errors);
		writeline(output, in4);

		hold_clock <= '1';
		wait;
	end process tb_process;
	
end architecture behavior;

	

