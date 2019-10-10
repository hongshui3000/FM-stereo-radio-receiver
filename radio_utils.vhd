library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package radio_utils is 

type ARRAY_SLV32 is array ( natural range <> ) of std_logic_vector (31 downto 0);

constant BITS: integer := 10;
constant PI : std_logic_vector(31 downto 0) := X"0000c90f";
constant HALF_PI : std_logic_vector(31 downto 0) := X"00006487";
constant AUDIO_DECIM : integer := 8;
constant MAX_TAPS : integer := 32; 
constant FM_DEMOD_GAIN : std_logic_vector(31 downto 0) := X"000002f6";
constant VOLUME_LEVEL : std_logic_vector(31 downto 0) := X"00000400";

constant IIR_COEFF_TAPS : integer := 2;
constant IIR_X_COEFFS : ARRAY_SLV32(0 to 1) :=
( 
	X"000000b2", X"000000b2"
);

constant IIR_Y_COEFFS : ARRAY_SLV32(0 to 1) :=
( 
	X"00000000", X"fffffd66"
);

-- Channel low-pass complex filter coefficients @ 0kHz to 80kHz
constant CHANNEL_COEFF_TAPS : integer := 20;
constant CHANNEL_COEFFS_REAL : ARRAY_SLV32(0 to 19) :=
(       
        X"00000001", X"00000008", X"fffffff3", X"00000009", X"0000000b", X"ffffffd3", X"00000045", X"ffffffd3",
        X"ffffffb1", X"00000257", X"00000257", X"ffffffb1", X"ffffffd3", X"00000045", X"ffffffd3", X"0000000b",
        X"00000009", X"fffffff3", X"00000008", X"00000001"
);

constant CHANNEL_COEFFS_IMAG : ARRAY_SLV32(0 to 19) :=
(       
        X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000",
        X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000",
        X"00000000", X"00000000", X"00000000", X"00000000"
);

-- L+R low-pass filter coefficients @ 15kHz
constant AUDIO_LPR_COEFF_TAPS : integer := 32;
constant AUDIO_LPR_COEFFS : ARRAY_SLV32(0 to 31) :=
(
        X"fffffffd", X"fffffffa", X"fffffff4", X"ffffffed", X"ffffffe5", X"ffffffdf", X"ffffffe2", X"fffffff3",
        X"00000015", X"0000004e", X"0000009b", X"000000f9", X"0000015d", X"000001be", X"0000020e", X"00000243",
        X"00000243", X"0000020e", X"000001be", X"0000015d", X"000000f9", X"0000009b", X"0000004e", X"00000015",
        X"fffffff3", X"ffffffe2", X"ffffffdf", X"ffffffe5", X"ffffffed", X"fffffff4", X"fffffffa", X"fffffffd"
);

-- L-R low-pass filter coefficients @ 15kHz, gain = 60
constant AUDIO_LMR_COEFF_TAPS : integer := 32;
constant AUDIO_LMR_COEFFS : ARRAY_SLV32(0 to 31) :=
(
        X"fffffffd", X"fffffffa", X"fffffff4", X"ffffffed", X"ffffffe5", X"ffffffdf", X"ffffffe2", X"fffffff3",
        X"00000015", X"0000004e", X"0000009b", X"000000f9", X"0000015d", X"000001be", X"0000020e", X"00000243",
        X"00000243", X"0000020e", X"000001be", X"0000015d", X"000000f9", X"0000009b", X"0000004e", X"00000015",
      X"fffffff3", X"ffffffe2", X"ffffffdf", X"ffffffe5", X"ffffffed", X"fffffff4", X"fffffffa", X"fffffffd"
);

-- Pilot tone band-pass filter @ 19kHz
constant BP_PILOT_COEFF_TAPS : integer := 32;
constant BP_PILOT_COEFFS : ARRAY_SLV32(0 to 31) :=
(
        X"0000000e", X"0000001f", X"00000034", X"00000048", X"0000004e", X"00000036", X"fffffff8", X"ffffff98",
        X"ffffff2d", X"fffffeda", X"fffffec3", X"fffffefe", X"ffffff8a", X"0000004a", X"0000010f", X"000001a1",
        X"000001a1", X"0000010f", X"0000004a", X"ffffff8a", X"fffffefe", X"fffffec3", X"fffffeda", X"ffffff2d",
        X"ffffff98", X"fffffff8", X"00000036", X"0000004e", X"00000048", X"00000034", X"0000001f", X"0000000e"
);

-- L-R band-pass filter @ 23kHz to 53kHz
constant BP_LMR_COEFF_TAPS : integer := 32;
constant BP_LMR_COEFFS : ARRAY_SLV32(0 to 31) :=
(
        X"00000000", X"00000000", X"fffffffc", X"fffffff9", X"fffffffe", X"00000008", X"0000000c", X"00000002",
        X"00000003", X"0000001e", X"00000030", X"fffffffc", X"ffffff8c", X"ffffff58", X"ffffffc3", X"0000008a",
        X"0000008a", X"ffffffc3", X"ffffff58", X"ffffff8c", X"fffffffc", X"00000030", X"0000001e", X"00000003",
        X"00000002", X"0000000c", X"00000008", X"fffffffe", X"fffffff9", X"fffffffc", X"00000000", X"00000000"
);

-- High pass filter @ 0Hz removes noise after pilot tone is squared
constant HP_COEFF_TAPS : integer := 32;
constant HP_COEFFS : ARRAY_SLV32(0 to 31) :=
(
        X"ffffffff", X"00000000", X"00000000", X"00000002", X"00000004", X"00000008", X"0000000b", X"0000000c",
        X"00000008", X"ffffffff", X"ffffffee", X"ffffffd7", X"ffffffbb", X"ffffff9f", X"ffffff87", X"ffffff76",
        X"ffffff76", X"ffffff87", X"ffffff9f", X"ffffffbb", X"ffffffd7", X"ffffffee", X"ffffffff", X"00000008",
        X"0000000c", X"0000000b", X"00000008", X"00000004", X"00000002", X"00000000", X"00000000", X"ffffffff"
);

function DEQUANTIZE(input : integer)
    return integer;
function DEQUANTIZE(input : std_logic_vector)
    return std_logic_vector;
function QUANTIZE_I(input : integer)
    return integer;

component readIQ is
port (
	signal clock : in std_logic;
	signal reset : in std_logic;
	signal x_dout : in std_logic_vector (7 downto 0);
	signal x_empty : in std_logic;
	signal x_rd_en : out std_logic;
	signal r_real_din : out std_logic_vector (31 downto 0);
	signal r_real_full : in std_logic;
	signal r_real_wr_en : out std_logic;
	signal r_imag_din : out std_logic_vector (31 downto 0);
	signal r_imag_full : in std_logic;
	signal r_imag_wr_en : out std_logic
);
end component readIQ;

component fir_cmplx is
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
end component fir_cmplx;

component fir is
generic (
	constant SAMPLE : integer := 1024; 
	constant TAPS : integer := 20;
	constant COEF : ARRAY_SLV32;
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
end component fir;

component demodulate is
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
end component demodulate;

component iir is
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
end component iir;

component add is
port
(
	signal clock : in std_logic;
	signal reset : in std_logic;
	signal x_dout : in std_logic_vector (31 downto 0);
	signal x_empty : in std_logic;
	signal x_rd_en : out std_logic;
	signal y_dout : in std_logic_vector (31 downto 0);
	signal y_empty : in std_logic;
	signal y_rd_en : out std_logic;
	signal z_din : out std_logic_vector (31 downto 0);
	signal z_full : in std_logic;
	signal z_wr_en : out std_logic
);
end component add;

component sub_op is
port
(
	signal clock : in std_logic;
	signal reset : in std_logic;
	signal x_dout : in std_logic_vector (31 downto 0);
	signal x_empty : in std_logic;
	signal x_rd_en : out std_logic;
	signal y_dout : in std_logic_vector (31 downto 0);
	signal y_empty : in std_logic;
	signal y_rd_en : out std_logic;
	signal z_din : out std_logic_vector (31 downto 0);
	signal z_full : in std_logic;
	signal z_wr_en : out std_logic
);
end component sub_op;

component square is
port
(
	signal clock : in std_logic;
	signal reset : in std_logic;
	signal x_dout : in std_logic_vector (31 downto 0);
	signal x_empty : in std_logic;
	signal x_rd_en : out std_logic;
	signal z_din : out std_logic_vector (31 downto 0);
	signal z_full : in std_logic;
	signal z_wr_en : out std_logic
);
end component square;

component multiply is
port
(
	signal clock : in std_logic;
	signal reset : in std_logic;
	signal x_dout : in std_logic_vector (31 downto 0);
	signal x_empty : in std_logic;
	signal x_rd_en : out std_logic;
	signal y_dout : in std_logic_vector (31 downto 0);
	signal y_empty : in std_logic;
	signal y_rd_en : out std_logic;
	signal z_din : out std_logic_vector (31 downto 0);
	signal z_full : in std_logic;
	signal z_wr_en : out std_logic
);
end component multiply;

component gain is
generic
(
	constant GAIN : std_logic_vector(31 downto 0)
);
port
(
	signal clock : in std_logic;
	signal reset : in std_logic;
	signal x_dout : in std_logic_vector (31 downto 0);
	signal x_empty : in std_logic;
	signal x_rd_en : out std_logic;
	signal z_din : out std_logic_vector (31 downto 0);
	signal z_full : in std_logic;
	signal z_wr_en : out std_logic
);
end component gain;

component fifo_2out is
generic
(
	constant FIFO_DATA_WIDTH : integer := 32;
	constant FIFO_BUFFER_SIZE : integer := 256
);
port
(
	signal reset    : in std_logic;

	signal rd_clk   : in std_logic;
	signal rd_en1    : in std_logic;
	signal rd_en2    : in std_logic;
	signal rd_dout1  : out std_logic_vector ((FIFO_DATA_WIDTH - 1) downto 0);
	signal rd_dout2  : out std_logic_vector ((FIFO_DATA_WIDTH - 1) downto 0);
	signal rd_empty1 : out std_logic;
	signal rd_empty2 : out std_logic;

	signal wr_clk   : in std_logic;
	signal wr_en    : in std_logic;
	signal wr_din   : in std_logic_vector ((FIFO_DATA_WIDTH - 1) downto 0);
	signal wr_full  : out std_logic
);
end component fifo_2out;

component fifo_3out is
generic
(
	constant FIFO_DATA_WIDTH : integer := 32;
	constant FIFO_BUFFER_SIZE : integer := 256
);
port
(
	signal reset    : in std_logic;

	signal rd_clk   : in std_logic;
	signal rd_en1    : in std_logic;
	signal rd_en2    : in std_logic;
	signal rd_en3    : in std_logic;
	signal rd_dout1  : out std_logic_vector ((FIFO_DATA_WIDTH - 1) downto 0);
	signal rd_dout2  : out std_logic_vector ((FIFO_DATA_WIDTH - 1) downto 0);
	signal rd_dout3  : out std_logic_vector ((FIFO_DATA_WIDTH - 1) downto 0);
	signal rd_empty1 : out std_logic;
	signal rd_empty2 : out std_logic;
	signal rd_empty3 : out std_logic;

	signal wr_clk   : in std_logic;
	signal wr_en    : in std_logic;
	signal wr_din   : in std_logic_vector ((FIFO_DATA_WIDTH - 1) downto 0);
	signal wr_full  : out std_logic
);
end component fifo_3out;
	
component fifo is
generic (
	constant FIFO_DATA_WIDTH : integer := 32;
	constant FIFO_BUFFER_SIZE : integer := 32
);
port (
	signal rd_clk : in std_logic;
	signal wr_clk : in std_logic;
	signal reset : in std_logic;
	signal rd_en : in std_logic;
	signal wr_en : in std_logic;
	signal din : in std_logic_vector ((FIFO_DATA_WIDTH - 1) downto 0);
	signal dout : out std_logic_vector ((FIFO_DATA_WIDTH - 1) downto 0);
	signal full : out std_logic;
	signal empty : out std_logic
);
end component fifo;
	
end package radio_utils;

package body radio_utils is

    function DEQUANTIZE(input : integer)
    return integer is
    begin
        return to_integer(to_signed(input, 32) / (to_signed(1, 32) sll BITS));
    end DEQUANTIZE;

    function DEQUANTIZE(input : std_logic_vector)
    return std_logic_vector is
    begin
        return std_logic_vector( signed(input) / (to_signed(1, 32) sll BITS) );
    end DEQUANTIZE;

    function QUANTIZE_I(input : integer)
    return integer is
    begin
        return to_integer(shift_left(to_signed(input, 32), BITS));
    end QUANTIZE_I;
	
end package body radio_utils;
