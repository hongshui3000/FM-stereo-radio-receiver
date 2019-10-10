library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.radio_utils.all;

entity fir_cmplx is
generic (
	constant SAMPLE : integer := 1024; 
	constant TAPS : integer := 20;
	constant COEF_REAL : ARRAY_SLV32;
	constant COEF_IMAG : ARRAY_SLV32;
	constant DECIM : integer := 1
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
	signal r_real_din : out std_logic_vector (31 downto 0);
	signal r_real_full : in std_logic;
	signal r_real_wr_en : out std_logic;
	signal r_imag_din : out std_logic_vector (31 downto 0);
	signal r_imag_full : in std_logic;
	signal r_imag_wr_en : out std_logic
);
end entity fir_cmplx;

architecture behavior of fir_cmplx is 
--varibale declarations
signal real_reg, real_reg_c : ARRAY_SLV32 (0 to MAX_TAPS-1);
signal imag_reg, imag_reg_c : ARRAY_SLV32 (0 to MAX_TAPS-1);
signal decim_cnt, decim_cnt_c : integer;
signal tap_cnt, tap_cnt_c : integer;
signal y_real, y_real_c : signed(31 downto 0);
signal y_imag, y_imag_c : signed(31 downto 0);

TYPE state_type is (s0,s1,s2,s3);
signal state : state_type;
signal next_state : state_type;

begin
fir_cmplx_fsm_process : process(y_real, y_imag, decim_cnt, tap_cnt, x_real_empty, x_real_dout, 
							x_imag_empty, x_imag_dout, r_real_full, r_imag_full,
							real_reg, imag_reg, state)
variable tmp_r_1, tmp_r_2 : signed(63 downto 0) := (others => '0');
variable tmp_i_1, tmp_i_2 : signed(63 downto 0) := (others => '0');

begin
x_real_rd_en <= '0';
x_imag_rd_en <= '0';
r_real_din <= (others => '0');
r_real_wr_en <= '0';
r_imag_din <= (others => '0');
r_imag_wr_en <= '0';
decim_cnt_c <= decim_cnt;
tap_cnt_c <= tap_cnt;
next_state <= state;
real_reg_c <= real_reg;
imag_reg_c <= imag_reg;
y_real_c <= y_real;
y_imag_c <= y_imag;

case ( state ) is
when s0 =>
	real_reg_c <= (others => (others => '0'));
	imag_reg_c <= (others => (others => '0'));
	next_state <= s1;
	decim_cnt_c <= 0;
	tap_cnt_c <= 0;

when s1 =>
	if(x_real_empty = '0' and x_imag_empty = '0') then
		x_real_rd_en <= '1';
		x_imag_rd_en <= '1';
		for i in (TAPS-1) downto 1 loop
			real_reg_c(i) <= real_reg(i - 1);
			imag_reg_c(i) <= imag_reg(i - 1);
		end loop;

		real_reg_c(0) <= x_real_dout;
		imag_reg_c(0) <= x_imag_dout;
		if(decim_cnt = (DECIM - 1)) then
			next_state <= s2;
		else
			next_state <= s1;
		end if;
		decim_cnt_c <= (decim_cnt + 1) mod DECIM;
	end if;

when s2 =>
	tmp_r_1 := signed(COEF_REAL(tap_cnt)) * signed(real_reg(tap_cnt));
	tmp_r_2 := signed(COEF_IMAG(tap_cnt)) * signed(imag_reg(tap_cnt));
	y_real_c <= signed(y_real) + signed(DEQUANTIZE(std_logic_vector( tmp_r_1(31 downto 0) - tmp_r_2(31 downto 0))));
	tmp_i_1 := signed(COEF_REAL(tap_cnt)) * signed(imag_reg(tap_cnt));
	tmp_i_2 := signed(COEF_IMAG(tap_cnt)) * signed(real_reg(tap_cnt));
	y_imag_c <= signed(y_imag) + signed(DEQUANTIZE(std_logic_vector( tmp_i_1(31 downto 0) - tmp_i_2(31 downto 0))));
	if(tap_cnt = (TAPS - 1)) then
		next_state <= s3;
	else
		next_state <= s2;
	end if;
	tap_cnt_c <= (tap_cnt + 1) mod TAPS;

when s3 =>
	if ( r_real_full = '0' and r_imag_full = '0') then
		r_real_din <= std_logic_vector(y_real);
		r_imag_din <= std_logic_vector(y_imag);
		r_real_wr_en <= '1';
		r_imag_wr_en <= '1';
		next_state <= s1;
		y_real_c <= (others => '0');
		y_imag_c <= (others => '0');
	end if;

when OTHERS =>
	r_real_din <= (others => 'X');
	r_real_wr_en <= 'X';
	r_imag_din <= (others => 'X');
	r_imag_wr_en <= 'X';
	real_reg_c <= (others => (others => 'X'));
	imag_reg_c <= (others => (others => 'X'));
	next_state <= s0;
end case;
end process fir_cmplx_fsm_process;

reg_process : process(reset, clock)
begin
if ( reset = '1' ) then
	state <= s0;
	real_reg <= (others => (others => '0'));
	imag_reg <= (others => (others => '0'));
	decim_cnt <= 0;
	tap_cnt <= 0;
	y_real <= (others => '0');
	y_imag <= (others => '0');
elsif ( rising_edge(clock) ) then
	state <= next_state;
	real_reg <= real_reg_c;
	imag_reg <= imag_reg_c;
	decim_cnt <= decim_cnt_c;
	tap_cnt <= tap_cnt_c;
	y_real <= y_real_c;
	y_imag <= y_imag_c;
	
end if;

end process reg_process;

end architecture behavior;
