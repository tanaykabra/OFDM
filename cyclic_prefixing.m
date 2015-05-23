clc;
clear all;
close all;

%%%%%%%%%%%%  Initialisation  %%%%%%%%%%%%%%%%%
data_length = 64;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%% digital modulation %%%%%%%%%%%%%%%
%%%%%%%%%%%% bpsk %%%%%%%%%%%
binary_data = randi([0 1], data_length, 1);  %% creating binary stream of length 64
hMod = comm.BPSKModulator; %% creating bpsk modulator system object
hMod.PhaseOffset = pi/16;  %% phase set to pi/16
modulated_data = step(hMod,binary_data); %% this is the bpsk modulated data
figure(1)
stem(binary_data);
title('Binary data sent');


dig_mod_data = reshape(modulated_data, 1, data_length);

%%%%%%%%%%%%%%%%%%%% IFFT %%%%%%%%%%%%%%%%%%%%%
demux_data = ifft(dig_mod_data);

%%%%%%%%%%%%% Cyclic Prefixing %%%%%%%%%%%%%%%%
%%%%%%%%%%%% taking cp length = 3 %%%%%%%%%%%%%
cp_length = 3;
new_symbol_length = cp_length+data_length;
cp_transmit_data(1,[1:cp_length]) = demux_data(1,[(data_length-cp_length+1):data_length]);  %%prefixing the last 8 elements
cp_transmit_data(1,[(cp_length+1):(new_symbol_length)]) = demux_data;  %% cp-transmit_data is sent by transmitter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%% CHANNEL %%%%%%%%%%%%%%%%%%%%%
impulse_response = randn(1,4) + 1i*randn(1,4);
received_sig = conv(cp_transmit_data, impulse_response);
recd_sig_length= length(received_sig);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%% removing CP %%%%%%%%%%%%%%%%%%%
r_signal(1,:) = received_sig(1,[(cp_length+1):(recd_sig_length-cp_length)]);  %% removing first and last 3 samples
%%% r_signal is the received signal which is basically the cyclic conv of transmit_signal and impulse_response of the channel with zero padding

%%%%%%%%%%%%%%%%%% FFT %%%%%%%%%%%%%%%%%%%%%%%%
fft_sig = fft(r_signal);

%%%%%%%%%%%%%%% zero forcing %%%%%%%%%%%%%%%%%%
length_h = length(impulse_response);
h_zero_padded = impulse_response;  % h_zero_padded is the impulse response with zero padding
h_zero_padded(1,[length_h+1:data_length]) = zeros(1,data_length-length_h);
freq_response = fft(h_zero_padded);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%% Zero forcing %%%%%%%%%%%%%%%%%
recd_data = fft_sig./freq_response;
received_data = reshape(recd_data,data_length,1);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%% BPSK Demodulation %%%%%%%%%%%%%%%%
hDemod = comm.BPSKDemodulator;
hDemod.PhaseOffset = pi/16;
received_binaryData = step(hDemod,received_data);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure(2)
stem(received_binaryData);
title('Binary Data Received');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Symbol_Errors = symerr(binary_data,received_binaryData)
