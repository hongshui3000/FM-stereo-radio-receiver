library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.radio_utils.all;

entity iir is
generic (
	constant SAMPLE : integer := 1024; 
	constant TAPS : integer := 20;
	constant X_COEF : ARRAY_SLV32;
	constant Y_COEF : ARRAY_SLV32;
	constant DECIM : integer := 8
);
port (
	signal clock : in std_logic;
	signal reset : in std_logic;
	signal x_dout : in std_logic_vector (31 downto 0);
	signal x_empty : in std_logic;
	signal x_rd_en : out std_logic;
	signal r_din : out std_logic_vector (31 downto 0);
	signal r_full : in std_logic;
	signal r_wr_en : out std_logic
);
end entity iir;

architecture behavior of iir is 
--varibale declarations
signal x_reg, x_reg_c : ARRAY_SLV32 (0 to MAX_TAPS-1);
signal y_reg, y_reg_c : ARRAY_SLV32 (0 to MAX_TAPS-1);
signal decim_cnt, decim_cnt_c : integer;
signal tap_cnt, tap_cnt_c : integer;
signal y1, y1_c : signed(31 downto 0);
signal y2, y2_c : signed(31 downto 0);

TYPE state_type is (s0,s1,s2,s3);
signal state : state_type;
signal next_state : state_type;

begin
iir_fsm_process : process(y1, y2, decim_cnt, tap_cnt, x_empty, x_dout, r_full, x_reg, y_reg, state)
variable tmp_y1 : signed(63 downto 0) := (others => '0');
variable tmp_y2 : signed(63 downto 0) := (others => '0');
begin
x_rd_en <= '0';
r_din <= (others => '0');
r_wr_en <= '0';
decim_cnt_c <= decim_cnt;
tap_cnt_c <= tap_cnt;
next_state <= state;
x_reg_c <= x_reg;
y_reg_c <= y_reg;
y1_c <= y1;
y2_c <= y2;

case ( state ) is
when s0 =>
	x_reg_c <= (others => (others => '0'));
	y_reg_c <= (others => (others => '0'));
	next_state <= s1;
	decim_cnt_c <= 0;

when s1 =>
	if(x_empty = '0') then
		x_rd_en <= '1';
		-- shift x
		for i in (TAPS-1) downto 1 loop
			x_reg_c(i) <= x_reg(i - 1);
		end loop;
		x_reg_c(0) <= x_dout;
		
		if(decim_cnt = (DECIM - 1)) then
			-- shift y
			for i in (TAPS - 1) downto 1 loop
				y_reg_c(i) <= y_reg(i - 1);
			end loop;
			next_state <= s2;
		else
			next_state <= s1;
		end if;
		decim_cnt_c <= (decim_cnt + 1) mod DECIM;
	end if;

when s2 =>
	tmp_y1 := signed(X_COEF(tap_cnt)) * signed(x_reg(tap_cnt));
	tmp_y2 := signed(Y_COEF(tap_cnt)) * signed(y_reg(tap_cnt));
	y1_c <= y1 + signed(DEQUANTIZE(std_logic_vector(tmp_y1(31 downto 0))));
	y2_c <= y2 + signed(DEQUANTIZE(std_logic_vector(tmp_y2(31 downto 0))));
	if(tap_cnt = (TAPS - 1)) then
			next_state <= s3;
		else
			next_state <= s2;
		end if;
	tap_cnt_c <= (tap_cnt + 1) mod TAPS;

when s3 =>
	y_reg_c(0) <= std_logic_vector(y1 + y2);
	if ( r_full = '0' ) then
		r_din <= y_reg(TAPS - 1);
		r_wr_en <= '1';
		next_state <= s1;
		y1_c <= (others => '0');
		y2_c <= (others => '0');
	end if;

when OTHERS =>
	r_din <= (others => 'X');
	r_wr_en <= 'X';
	x_reg_c <= (others => (others => 'X'));
	y_reg_c <= (others => (others => 'X'));
	next_state <= s0;
end case;
end process iir_fsm_process;

reg_process : process(reset, clock)
begin
if ( reset = '1' ) then
	state <= s0;
	x_reg <= (others => (others => '0'));
	y_reg <= (others => (others => '0'));
	decim_cnt <= 0;
	tap_cnt <= 0;
	y1 <= (others => '0');
	y2 <= (others => '0');
elsif ( rising_edge(clock) ) then
	state <= next_state;
	x_reg <= x_reg_c;
	y_reg <= y_reg_c;
	decim_cnt <= decim_cnt_c;
	tap_cnt <= tap_cnt_c;
	y1 <= y1_c;
	y2 <= y2_c;
end if;

end process reg_process;

end architecture behavior;
