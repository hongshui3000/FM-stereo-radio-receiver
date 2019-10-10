library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library work;
use work.radio_utils.all;

entity radio_top is
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
end entity radio_top;

architecture behavior of radio_top is

	signal x_dout : std_logic_vector(7 downto 0);
	signal x_empty : std_logic;
	signal x_rd_en : std_logic;
	
	signal fircmp_real_din, fircmp_real_dout : std_logic_vector(31 downto 0);
	signal fircmp_real_full, fircmp_real_empty : std_logic;
	signal fircmp_real_wr_en, fircmp_real_rd_en : std_logic;
	signal fircmp_imag_din, fircmp_imag_dout : std_logic_vector(31 downto 0);
	signal fircmp_imag_full, fircmp_imag_empty : std_logic;
	signal fircmp_imag_wr_en, fircmp_imag_rd_en : std_logic;
	
	signal demod_real_din, demod_real_dout : std_logic_vector(31 downto 0);
	signal demod_real_full, demod_real_empty : std_logic;
	signal demod_real_wr_en, demod_real_rd_en : std_logic;
	signal demod_imag_din, demod_imag_dout : std_logic_vector(31 downto 0);
	signal demod_imag_full, demod_imag_empty : std_logic;
	signal demod_imag_wr_en, demod_imag_rd_en : std_logic;
	
	signal fir_1to3_din : std_logic_vector(31 downto 0);
	signal fir_1to3_full : std_logic;
	signal fir_1to3_wr_en : std_logic;
	signal fir_1to3_rd_en1, fir_1to3_rd_en2, fir_1to3_rd_en3 : std_logic;
	signal fir_1to3_dout1, fir_1to3_dout2, fir_1to3_dout3 : std_logic_vector(31 downto 0);
	signal fir_1to3_empty1, fir_1to3_empty2, fir_1to3_empty3 : std_logic;
	
	signal bp_lmr_din, bp_lmr_dout : std_logic_vector(31 downto 0);
	signal bp_lmr_full, bp_lmr_empty : std_logic;
	signal bp_lmr_wr_en, bp_lmr_rd_en : std_logic;
	
	signal bp_pilot_din, bp_pilot_dout : std_logic_vector(31 downto 0);
	signal bp_pilot_full, bp_pilot_empty : std_logic;
	signal bp_pilot_wr_en, bp_pilot_rd_en : std_logic;
	
	signal audio_lpr_din, audio_lpr_dout1, audio_lpr_dout2 : std_logic_vector(31 downto 0);
	signal audio_lpr_full, audio_lpr_empty1, audio_lpr_empty2 : std_logic;
	signal audio_lpr_wr_en, audio_lpr_rd_en1, audio_lpr_rd_en2 : std_logic;
	
	signal sqr_din, sqr_dout : std_logic_vector(31 downto 0);
	signal sqr_full, sqr_empty : std_logic;
	signal sqr_wr_en, sqr_rd_en : std_logic;
	
	signal hp_pilot_din, hp_pilot_dout : std_logic_vector(31 downto 0);
	signal hp_pilot_full, hp_pilot_empty : std_logic;
	signal hp_pilot_wr_en, hp_pilot_rd_en : std_logic;
	
	signal multiply_din, multiply_dout : std_logic_vector(31 downto 0);
	signal multiply_full, multiply_empty : std_logic;
	signal multiply_wr_en, multiply_rd_en : std_logic;
	
	signal audio_lmr_din, audio_lmr_dout1, audio_lmr_dout2 : std_logic_vector(31 downto 0);
	signal audio_lmr_full, audio_lmr_empty1, audio_lmr_empty2 : std_logic;
	signal audio_lmr_wr_en, audio_lmr_rd_en1, audio_lmr_rd_en2 : std_logic;
	
	signal left_din, left_dout : std_logic_vector(31 downto 0);
	signal left_full, left_empty : std_logic;
	signal left_wr_en, left_rd_en : std_logic;

	signal right_din, right_dout : std_logic_vector(31 downto 0);
	signal right_full, right_empty : std_logic;
	signal right_wr_en, right_rd_en : std_logic;
	
	signal left_deemph_din, left_deemph_dout : std_logic_vector(31 downto 0);
	signal left_deemph_full, left_deemph_empty : std_logic;
	signal left_deemph_wr_en, left_deemph_rd_en : std_logic;

	signal right_deemph_din, right_deemph_dout : std_logic_vector(31 downto 0);
	signal right_deemph_full, right_deemph_empty : std_logic;
	signal right_deemph_wr_en, right_deemph_rd_en : std_logic;
	
	signal left_audio_din : std_logic_vector(31 downto 0);
	signal left_audio_full : std_logic;
	signal left_audio_wr_en : std_logic;

	signal right_audio_din : std_logic_vector(31 downto 0);
	signal right_audio_full : std_logic;
	signal right_audio_wr_en : std_logic;
	
	begin
	-- input fifo
	x_inst: component fifo
	generic map (
		FIFO_BUFFER_SIZE => 1024,
		FIFO_DATA_WIDTH => 8
	)
	port map (
		rd_clk => clock,
		wr_clk => clock,
		reset => reset,
		rd_en => x_rd_en,
		wr_en => x_wr_en,
		din => x_din,
		dout => x_dout,
		full => x_full,
		empty => x_empty
	);

	readIQ_inst : component readIQ
	port map (
		clock => clock,
		reset => reset,
		x_dout => x_dout,
		x_empty => x_empty,
		x_rd_en => x_rd_en,
		r_real_din => fircmp_real_din,
		r_real_full => fircmp_real_full,
		r_real_wr_en => fircmp_real_wr_en,
		r_imag_din => fircmp_imag_din,
		r_imag_full => fircmp_imag_full,
		r_imag_wr_en => fircmp_imag_wr_en
	);

	-- for fir complx readIQ
	fir_complx_fifo_real_inst: component fifo
	generic map (
		FIFO_BUFFER_SIZE => 4096,
		FIFO_DATA_WIDTH => 32
	)
	port map (
		rd_clk => clock,
		wr_clk => clock,
		reset => reset,
		rd_en => fircmp_real_rd_en,
		wr_en => fircmp_real_wr_en,
		din => fircmp_real_din,
		dout => fircmp_real_dout,
		full => fircmp_real_full,
		empty => fircmp_real_empty
	);
	
	fir_complx_fifo_imag_inst: component fifo
	generic map (
		FIFO_BUFFER_SIZE => 4096,
		FIFO_DATA_WIDTH => 32
	)
	port map (
		rd_clk => clock,
		wr_clk => clock,
		reset => reset,
		rd_en => fircmp_imag_rd_en,
		wr_en => fircmp_imag_wr_en,
		din => fircmp_imag_din,
		dout => fircmp_imag_dout,
		full => fircmp_imag_full,
		empty => fircmp_imag_empty
	);
	
	fir_complx_inst: component fir_cmplx
	generic map(
		SAMPLE => 1024,
		TAPS => CHANNEL_COEFF_TAPS,
		COEF_REAL => CHANNEL_COEFFS_REAL,
		COEF_IMAG => CHANNEL_COEFFS_IMAG,
		DECIM => 1
	)
	port map(
		clock => clock,
		reset => reset,
		x_real_dout => fircmp_real_dout,
		x_real_empty => fircmp_real_empty,
		x_real_rd_en => fircmp_real_rd_en,
		x_imag_dout => fircmp_imag_dout,
		x_imag_empty => fircmp_imag_empty,
		x_imag_rd_en => fircmp_imag_rd_en,
		r_real_din => demod_real_din,
		r_real_full => demod_real_full,
		r_real_wr_en => demod_real_wr_en,
		r_imag_din => demod_imag_din,
		r_imag_full => demod_imag_full,
		r_imag_wr_en => demod_imag_wr_en
	);

	demod_fifo_real_inst: component fifo
	generic map (
		FIFO_BUFFER_SIZE => 4096,
		FIFO_DATA_WIDTH => 32
	)
	port map (
		rd_clk => clock,
		wr_clk => clock,
		reset => reset,
		rd_en => demod_real_rd_en,
		wr_en => demod_real_wr_en,
		din => demod_real_din,
		dout => demod_real_dout,
		full => demod_real_full,
		empty => demod_real_empty
	);
	
	demod_fifo_imag_inst: component fifo
	generic map (
		FIFO_BUFFER_SIZE => 4096,
		FIFO_DATA_WIDTH => 32
	)
	port map (
		rd_clk => clock,
		wr_clk => clock,
		reset => reset,
		rd_en => demod_imag_rd_en,
		wr_en => demod_imag_wr_en,
		din => demod_imag_din,
		dout => demod_imag_dout,
		full => demod_imag_full,
		empty => demod_imag_empty
	);
	
	demod_inst: component demodulate
	generic map(
		GAIN => FM_DEMOD_GAIN
	)
	port map(
		clock => clock,
		reset => reset,
		x_real_dout => demod_real_dout,
		x_real_empty => demod_real_empty,
		x_real_rd_en => demod_real_rd_en,
		x_imag_dout => demod_imag_dout,
		x_imag_empty => demod_imag_empty,
		x_imag_rd_en => demod_imag_rd_en,
		r_din => fir_1to3_din,
		r_full => fir_1to3_full,
		r_wr_en => fir_1to3_wr_en
	);
	
	fir_fifo_3out_inst: component fifo_3out
	generic map (
		FIFO_BUFFER_SIZE => 4096,
		FIFO_DATA_WIDTH => 32
	)
	port map (
		rd_clk => clock,
		wr_clk => clock,
		reset => reset,
		wr_en => fir_1to3_wr_en,
		wr_din => fir_1to3_din,
		wr_full => fir_1to3_full,
		rd_en1 => fir_1to3_rd_en1,
		rd_dout1 => fir_1to3_dout1,
		rd_empty1 => fir_1to3_empty1,
		rd_en2 => fir_1to3_rd_en2,
		rd_dout2 => fir_1to3_dout2,
		rd_empty2 => fir_1to3_empty2,
		rd_en3 => fir_1to3_rd_en3,
		rd_dout3 => fir_1to3_dout3,
		rd_empty3 => fir_1to3_empty3
	);
	
	fir_for_mul_inst: component fir
	generic map(
		SAMPLE => 1024,
		TAPS => BP_LMR_COEFF_TAPS,
		COEF => BP_LMR_COEFFS,
		DECIM => 1
	)
	port map(
		clock => clock,
		reset => reset,
		x_dout => fir_1to3_dout1,
		x_empty => fir_1to3_empty1,
		x_rd_en => fir_1to3_rd_en1,
		r_din => bp_lmr_din,
		r_full => bp_lmr_full,
		r_wr_en => bp_lmr_wr_en
	);
	
	bp_lmr_fifo: component fifo
	generic map (
		FIFO_BUFFER_SIZE => 4096,
		FIFO_DATA_WIDTH => 32
	)
	port map (
		rd_clk => clock,
		wr_clk => clock,
		reset => reset,
		rd_en => bp_lmr_rd_en,
		wr_en => bp_lmr_wr_en,
		din => bp_lmr_din,
		dout => bp_lmr_dout,
		full => bp_lmr_full,
		empty => bp_lmr_empty
	);
	
	fir_for_sqr_inst: component fir
	generic map(
		SAMPLE => 1024,
		TAPS => BP_PILOT_COEFF_TAPS,
		COEF => BP_PILOT_COEFFS,
		DECIM => 1
	)
	port map(
		clock => clock,
		reset => reset,
		x_dout => fir_1to3_dout2,
		x_empty => fir_1to3_empty2,
		x_rd_en => fir_1to3_rd_en2,
		r_din => bp_pilot_din,
		r_full => bp_pilot_full,
		r_wr_en => bp_pilot_wr_en
	);
	
	bp_pilot_fifo: component fifo
	generic map (
		FIFO_BUFFER_SIZE => 4096,
		FIFO_DATA_WIDTH => 32
	)
	port map (
		rd_clk => clock,
		wr_clk => clock,
		reset => reset,
		rd_en => bp_pilot_rd_en,
		wr_en => bp_pilot_wr_en,
		din => bp_pilot_din,
		dout =>bp_pilot_dout,
		full => bp_pilot_full,
		empty => bp_pilot_empty
	);
	
	fir_for_subadd_inst: component fir
	generic map(
		SAMPLE => 1024,
		TAPS => AUDIO_LPR_COEFF_TAPS,
		COEF => AUDIO_LPR_COEFFS,
		DECIM => AUDIO_DECIM
	)
	port map(
		clock => clock,
		reset => reset,
		x_dout => fir_1to3_dout3,
		x_empty => fir_1to3_empty3,
		x_rd_en => fir_1to3_rd_en3,
		r_din => audio_lpr_din,
		r_full => audio_lpr_full,
		r_wr_en => audio_lpr_wr_en
	);
	
	sqr_inst: component square
	port map(
		clock => clock,
		reset => reset,
		x_dout => bp_pilot_dout,
		x_empty => bp_pilot_empty,
		x_rd_en => bp_pilot_rd_en,
		z_din => sqr_din,
		z_full => sqr_full,
		z_wr_en => sqr_wr_en
	);
	
	sqr_fifo: component fifo
	generic map (
		FIFO_BUFFER_SIZE => 4096,
		FIFO_DATA_WIDTH => 32
	)
	port map (
		rd_clk => clock,
		wr_clk => clock,
		reset => reset,
		rd_en => sqr_rd_en,
		wr_en => sqr_wr_en,
		din => sqr_din,
		dout => sqr_dout,
		full => sqr_full,
		empty => sqr_empty
	);
	
	fir_hp_pilot_inst: component fir
	generic map(
		SAMPLE => 1024,
		TAPS => HP_COEFF_TAPS,
		COEF => HP_COEFFS,
		DECIM => 1
	)
	port map(
		clock => clock,
		reset => reset,
		x_dout => sqr_dout,
		x_empty => sqr_empty,
		x_rd_en => sqr_rd_en,
		r_din => hp_pilot_din,
		r_full => hp_pilot_full,
		r_wr_en => hp_pilot_wr_en
	);
	
	hp_pilot_fifo: component fifo
	generic map (
		FIFO_BUFFER_SIZE => 4096,
		FIFO_DATA_WIDTH => 32
	)
	port map (
		rd_clk => clock,
		wr_clk => clock,
		reset => reset,
		rd_en => hp_pilot_rd_en,
		wr_en => hp_pilot_wr_en,
		din => hp_pilot_din,
		dout => hp_pilot_dout,
		full => hp_pilot_full,
		empty => hp_pilot_empty
	);
	
	multiply_inst: component multiply
	port map(
		clock => clock,
		reset => reset,
		x_dout => bp_lmr_dout,
		x_empty => bp_lmr_empty,
		x_rd_en => bp_lmr_rd_en,
		y_dout => hp_pilot_dout,
		y_empty => hp_pilot_empty,
		y_rd_en => hp_pilot_rd_en,
		z_din => multiply_din,
		z_full => multiply_full,
		z_wr_en => multiply_wr_en
	);
	
	multiply_fifo: component fifo
	generic map (
		FIFO_BUFFER_SIZE => 4096,
		FIFO_DATA_WIDTH => 32
	)
	port map (
		rd_clk => clock,
		wr_clk => clock,
		reset => reset,
		rd_en => multiply_rd_en,
		wr_en => multiply_wr_en,
		din => multiply_din,
		dout => multiply_dout,
		full => multiply_full,
		empty => multiply_empty
	);
	
	fir_audio_lmr: component fir
	generic map(
		SAMPLE => 1024,
		TAPS => AUDIO_LMR_COEFF_TAPS,
		COEF => AUDIO_LMR_COEFFS,
		DECIM => AUDIO_DECIM
	)
	port map(
		clock => clock,
		reset => reset,
		x_dout => multiply_dout,
		x_empty => multiply_empty,
		x_rd_en => multiply_rd_en,
		r_din => audio_lmr_din,
		r_full => audio_lmr_full,
		r_wr_en => audio_lmr_wr_en
	);
	
	audio_lmr_fifo: component fifo_2out
	generic map (
		FIFO_BUFFER_SIZE => 4096,
		FIFO_DATA_WIDTH => 32
	)
	port map (
		rd_clk => clock,
		wr_clk => clock,
		reset => reset,
		wr_en => audio_lmr_wr_en,
		wr_din => audio_lmr_din,
		wr_full => audio_lmr_full,
		rd_en1 => audio_lmr_rd_en1,
		rd_dout1 => audio_lmr_dout1,
		rd_empty1 => audio_lmr_empty1,
		rd_en2 => audio_lmr_rd_en2,
		rd_dout2 => audio_lmr_dout2,
		rd_empty2 => audio_lmr_empty2
	);
	
	audio_lpr_fifo: component fifo_2out
	generic map (
		FIFO_BUFFER_SIZE => 4096,
		FIFO_DATA_WIDTH => 32
	)
	port map (
		rd_clk => clock,
		wr_clk => clock,
		reset => reset,
		wr_en => audio_lpr_wr_en,
		wr_din => audio_lpr_din,
		wr_full => audio_lpr_full,
		rd_en1 => audio_lpr_rd_en1,
		rd_dout1 => audio_lpr_dout1,
		rd_empty1 => audio_lpr_empty1,
		rd_en2 => audio_lpr_rd_en2,
		rd_dout2 => audio_lpr_dout2,
		rd_empty2 => audio_lpr_empty2
	);
	
	add_inst: component add
	port map(
		clock => clock,
		reset => reset,
		x_dout => audio_lpr_dout1,
		x_empty => audio_lpr_empty1,
		x_rd_en => audio_lpr_rd_en1,
		y_dout => audio_lmr_dout1,
		y_empty => audio_lmr_empty1,
		y_rd_en => audio_lmr_rd_en1,
		z_din => left_din,
		z_full => left_full,
		z_wr_en => left_wr_en
	);
	
	sub_inst: component sub_op
	port map(
		clock => clock,
		reset => reset,
		x_dout => audio_lpr_dout2,
		x_empty => audio_lpr_empty2,
		x_rd_en => audio_lpr_rd_en2,
		y_dout => audio_lmr_dout2,
		y_empty => audio_lmr_empty2,
		y_rd_en => audio_lmr_rd_en2,
		z_din => right_din,
		z_full => right_full,
		z_wr_en => right_wr_en
	);
	
	left_fifo: component fifo
	generic map (
		FIFO_BUFFER_SIZE => 4096,
		FIFO_DATA_WIDTH => 32
	)
	port map (
		rd_clk => clock,
		wr_clk => clock,
		reset => reset,
		rd_en => left_rd_en,
		wr_en => left_wr_en,
		din => left_din,
		dout => left_dout,
		full => left_full,
		empty => left_empty
	);
	
	right_fifo: component fifo
	generic map (
		FIFO_BUFFER_SIZE => 4096,
		FIFO_DATA_WIDTH => 32
	)
	port map (
		rd_clk => clock,
		wr_clk => clock,
		reset => reset,
		rd_en => right_rd_en,
		wr_en => right_wr_en,
		din => right_din,
		dout => right_dout,
		full => right_full,
		empty => right_empty
	);
	
	iir_left_inst: component iir
	generic map(
		SAMPLE => 1024,
		TAPS => IIR_COEFF_TAPS,
		X_COEF => IIR_X_COEFFS,
		Y_COEF => IIR_Y_COEFFS,
		DECIM => 1
	)
	port map(
		clock => clock,
		reset => reset,
		x_dout => left_dout,
		x_empty => left_empty,
		x_rd_en => left_rd_en,
		r_din => left_deemph_din,
		r_full => left_deemph_full,
		r_wr_en => left_deemph_wr_en
	);
	
	iir_right_inst: component iir
	generic map(
		SAMPLE => 1024,
		TAPS => IIR_COEFF_TAPS,
		X_COEF => IIR_X_COEFFS,
		Y_COEF => IIR_Y_COEFFS,
		DECIM => 1
	)
	port map(
		clock => clock,
		reset => reset,
		x_dout => right_dout,
		x_empty => right_empty,
		x_rd_en => right_rd_en,
		r_din => right_deemph_din,
		r_full => right_deemph_full,
		r_wr_en => right_deemph_wr_en
	);
	
	left_deemph_fifo: component fifo
	generic map (
		FIFO_BUFFER_SIZE => 4096,
		FIFO_DATA_WIDTH => 32
	)
	port map (
		rd_clk => clock,
		wr_clk => clock,
		reset => reset,
		rd_en => left_deemph_rd_en,
		wr_en => left_deemph_wr_en,
		din => left_deemph_din,
		dout => left_deemph_dout,
		full => left_deemph_full,
		empty => left_deemph_empty
	);
	
	right_deemph_fifo: component fifo
	generic map (
		FIFO_BUFFER_SIZE => 4096,
		FIFO_DATA_WIDTH => 32
	)
	port map (
		rd_clk => clock,
		wr_clk => clock,
		reset => reset,
		rd_en => right_deemph_rd_en,
		wr_en => right_deemph_wr_en,
		din => right_deemph_din,
		dout => right_deemph_dout,
		full => right_deemph_full,
		empty => right_deemph_empty
	);
	
	gain_left_inst: component gain
	generic map(
		GAIN => VOLUME_LEVEL
	)
	port map(
		clock => clock,
		reset => reset,
		x_dout => left_deemph_dout,
		x_empty => left_deemph_empty,
		x_rd_en => left_deemph_rd_en,
		z_din => left_audio_din,
		z_full => left_audio_full,
		z_wr_en => left_audio_wr_en
	);
	
	gain_right_inst: component gain
	generic map(
		GAIN => VOLUME_LEVEL
	)
	port map(
		clock => clock,
		reset => reset,
		x_dout => right_deemph_dout,
		x_empty => right_deemph_empty,
		x_rd_en => right_deemph_rd_en,
		z_din => right_audio_din,
		z_full => right_audio_full,
		z_wr_en => right_audio_wr_en
	);
	
	left_audio_fifo: component fifo
	generic map (
		FIFO_BUFFER_SIZE => 4096,
		FIFO_DATA_WIDTH => 32
	)
	port map (
		rd_clk => clock,
		wr_clk => clock,
		reset => reset,
		rd_en => left_audio_rd_en,
		wr_en => left_audio_wr_en,
		din => left_audio_din,
		dout => left_audio_dout,
		full => left_audio_full,
		empty => left_audio_empty
	);
	
	right_audio_fifo: component fifo
	generic map (
		FIFO_BUFFER_SIZE => 4096,
		FIFO_DATA_WIDTH => 32
	)
	port map (
		rd_clk => clock,
		wr_clk => clock,
		reset => reset,
		rd_en => right_audio_rd_en,
		wr_en => right_audio_wr_en,
		din => right_audio_din,
		dout => right_audio_dout,
		full => right_audio_full,
		empty => right_audio_empty
	);
	
	
end architecture behavior;
