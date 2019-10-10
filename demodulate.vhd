library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.radio_utils.all;

entity demodulate is
generic (
	constant GAIN : std_logic_vector(31 downto 0)
);
port (
	signal clock : in std_logic;
	signal reset : in std_logic;
	signal x_real_dout : in std_logic_vector (31 downto 0);
	signal x_real_empty : in std_logic;
	signal x_real_rd_en : out std_logic;
	signal x_imag_dout : in std_logic_vector (31 downto 0);
	signal x_imag_empty : in std_logic;
	signal x_imag_rd_en : out std_logic;
	signal r_din : out std_logic_vector (31 downto 0);
	signal r_full : in std_logic;
	signal r_wr_en : out std_logic
);
end entity demodulate;

architecture behavior of demodulate is 

component divider is
generic(
    constant DWIDTH     : integer := 32
);
port(
    --Inputs
    signal clk          : in std_logic;
    signal reset        : in std_logic;
    signal start        : in std_logic;
    signal dividend     : in std_logic_vector(DWIDTH-1 downto 0);
    signal divisor      : in std_logic_vector(DWIDTH-1 downto 0);
    
    --Outputs
    signal quotient     : out std_logic_vector(DWIDTH-1 downto 0);
    signal remainder    : out std_logic_vector(DWIDTH-1 downto 0);
    signal overflow     : out std_logic;
    signal done         : out std_logic
);
end component divider;

signal real_prev, real_prev_c : std_logic_vector(31 downto 0);
signal imag_prev, imag_prev_c : std_logic_vector(31 downto 0);
signal r, r_c : integer;
signal i, i_c : integer;
signal y, y_c : integer;

TYPE state_type is (s0, s1, s2, s3, s4);
signal state : state_type;
signal next_state : state_type;

--divider
signal dividend, divisor : std_logic_vector(31 downto 0);
signal quotient, remainder : std_logic_vector(31 downto 0);
signal divider_start, divider_done, overflow : std_logic;

constant QUAD1 : integer := 804;
constant QUAD3 : integer := 2412;

begin

divider_inst : component divider
generic map (
	DWIDTH => 32
)
port map (
	clk => clock,
	reset => reset,
	start => divider_start,
	dividend => dividend,
	divisor => divisor,
	quotient => quotient,
	remainder => remainder,
	overflow => overflow,
	done => divider_done
);

demodulate_fsm_process : process(y, x_real_empty, x_real_dout, 
							x_imag_empty, x_imag_dout, r_full,
							real_prev, imag_prev, r, i, state, divider_done)
variable abs_i : integer := 0;
variable angle : integer := 0;
variable qarctan_r :integer := 0;
variable nomi : integer := 0;
variable denomi : integer := 0;
variable quad : integer := 0;
variable tmp_r_1, tmp_r_2 : signed(63 downto 0) := (others => '0');
variable tmp_i_1, tmp_i_2 : signed(63 downto 0) := (others => '0');

begin
x_real_rd_en <= '0';
x_imag_rd_en <= '0';
r_din <= (others => '0');
r_wr_en <= '0';
next_state <= state;
real_prev_c <= real_prev;
imag_prev_c <= imag_prev;
r_c <= r;
i_c <= i;
y_c <= y;
divider_start <= '0';

case ( state ) is
when s0 =>
	real_prev_c <= (others => '0');
	imag_prev_c <= (others => '0');
	next_state <= s1;

when s1 =>
	if(x_real_empty = '0' and x_imag_empty = '0') then
		x_real_rd_en <= '1';
		x_imag_rd_en <= '1';
		tmp_r_1 := signed(real_prev) * signed(x_real_dout);
		tmp_r_2 := -signed(imag_prev) * signed(x_imag_dout);
		r_c <= to_integer(signed(DEQUANTIZE(std_logic_vector(tmp_r_1(31 downto 0))))
				- signed(DEQUANTIZE(std_logic_vector(tmp_r_2(31 downto 0)))));
		
		tmp_i_1 := signed(real_prev) * signed(x_imag_dout);
		tmp_i_2 := -signed(imag_prev) * signed(x_real_dout);
		i_c <= to_integer(signed(DEQUANTIZE(std_logic_vector(tmp_i_1(31 downto 0))))
				+ signed(DEQUANTIZE(std_logic_vector(tmp_i_2(31 downto 0)))));
				
		real_prev_c <=  x_real_dout;
		imag_prev_c <=  x_imag_dout;
		next_state <= s2;
	end if;

when s2 =>
	-- demod_out
	abs_i := to_integer(abs(to_signed(i, 32)) + to_signed(1, 32));
	if(r >= 0) then
		nomi := QUANTIZE_I(r - abs_i);
		denomi := r + abs_i;
		quad := QUAD1;
	else
		nomi := QUANTIZE_I(r + abs_i);
		denomi := abs_i - r;
		quad := QUAD3;
	end if;
	divider_start <= '1';
	dividend <= std_logic_vector(to_signed(nomi, 32));
	divisor <= std_logic_vector(to_signed(denomi, 32));
	next_state <= s3;

when s3 =>
	if (divider_done = '1' and divider_start = '0') then	
		qarctan_r := to_integer(signed(quotient));
		angle := quad - DEQUANTIZE(QUAD1 * qarctan_r);
		if (i < 0) then
			y_c <= -angle;
		else
			y_c <= angle;
		end if;
		next_state <= s4;
	end if;
	
when s4 =>
	if ( r_full = '0') then
		r_din <= std_logic_vector(to_signed(DEQUANTIZE(y * to_integer(unsigned(GAIN))), 32));
		r_wr_en <= '1';
		next_state <= s1;
	end if;

when OTHERS =>
	r_din <= (others => 'X');
	r_wr_en <= 'X';
	next_state <= s0;
end case;
end process demodulate_fsm_process;

reg_process : process(reset, clock)
begin
if ( reset = '1' ) then
	state <= s0;
	real_prev <= (others => '0');
	imag_prev <= (others => '0');
	r <= 0;
	i <= 0;
	y <= 0;
elsif ( rising_edge(clock) ) then
	state <= next_state;
	real_prev <= real_prev_c;
	imag_prev <= imag_prev_c;
	r <= r_c;
	i <= i_c;
	y <= y_c;
end if;

end process reg_process;

end architecture behavior;