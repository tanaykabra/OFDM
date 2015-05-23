%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%% THIS IS BASIC OFDM IMPLEMENTATION USING %%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%% MULTIPLE SYMBOLS FOR TRANMISSION %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% SINGLE USER TRANSMISSION %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% NOISE IS NOT CONSIDERED %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% HENCE NO SYMBOL ERRORS %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc;
clear all;
close all;

%%%%%%%%%%%%  Initialisation  %%%%%%%%%%%%%%%%%
data_length = 64;
number_subcarriers = 8;
symbol_length = data_length/number_subcarriers;
h_length = 4; % length of impulse response
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%% digital modulation %%%%%%%%%%%%%%%
%%%%%%%%%%%% bpsk %%%%%%%%%%%
binary_data = randi([0 1], data_length, 1);  %% creating random binary stream 
hMod = comm.BPSKModulator;                   %% creating bpsk modulator system object
hMod.PhaseOffset = pi/16;                    %% phase set to pi/16
modulated_data = step(hMod,binary_data);                                  %% this is the bpsk modulated data
dig_mod_data = reshape(modulated_data,number_subcarriers,symbol_length);  %% creating matrix where each column represents a symbol

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
impulse_response = randn(1,h_length) + 1i*randn(1,h_length);
h_zero_padded = impulse_response;            % h_zero_padded is the impulse response with zero padding
h_zero_padded(1,[h_length+1:number_subcarriers]) = zeros(1,number_subcarriers-h_length); %% making length of h[n] equal to symbol_length
freq_response = fft(h_zero_padded);          % this is H(k)- for different subcarriers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure(1)
stem(binary_data);
title('Binary data sent');

for i = 1:symbol_length
    %%%%%%%%%%%%%% Demultiplexing %%%%%%%%%%%%%%%%%
    %%%%%%%%%% Serial to Parallel %%%%%%%%%%%%%%%%%
    demux_modulated_data = dig_mod_data(:,i);     % this is the binary symbol to be transmitted
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%%%%%%% IFFT %%%%%%%%%%%%%%%%%%%%%
    demux_data = ifft(demux_modulated_data);
    ifft_data = demux_data.';                 % ifft_data has 8 ifft samples making a symbol
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%% Cyclic Prefixing %%%%%%%%%%%%%%%%
    cp_length = h_length-1;                       % cp_length enough to prevent ISI
    new_symbol_length = cp_length+number_subcarriers;   % total symbol length
    transmit_data(1,[1:cp_length]) = ifft_data(1,[(number_subcarriers-cp_length+1):number_subcarriers]);  %%prefixing the last 3 elements
    transmit_data(1,[(cp_length+1):(new_symbol_length)]) = ifft_data;  %% cp-transmit_data is sent by transmitter
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%%%% CHANNEL %%%%%%%%%%%%%%%%%%%%%
    received_sig = conv(transmit_data, impulse_response);  % regular conv after CP results in a symbol's circular conv
    recd_sig_length= length(received_sig);           
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%% removing CP %%%%%%%%%%%%%%%%%%%
    r_signal(1,:) = received_sig(1,[(cp_length+1):(recd_sig_length-cp_length)]);  %% removing first and last 3 samples
    %%% r_signal is the received signal which is basically the cyclic conv of transmit_signal and impulse_response of the channel with zero padding

    %%%%%%%%%%%%%%%%%% FFT %%%%%%%%%%%%%%%%%%%%%%%%
    fft_signal = fft(r_signal);  
    %%% due to cyclic conv in time domain 
    %%%we have dft(convolved signal) = dft(transmittedsignal)*freq_response
    %%% i.e pointwise multiplication 

    %%%%%%%%%%%%%%%% Zero forcing %%%%%%%%%%%%%%%%%
    recd_data = fft_signal./freq_response;        %% this is the detection scheme to get fft(transmitted data)
    received_data = reshape(recd_data,number_subcarriers,1);  %% this should be the dig mod txd symbol (noise eliminated)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%% BPSK Demodulation %%%%%%%%%%%%%%%%
    hDemod = comm.BPSKDemodulator;
    hDemod.PhaseOffset = pi/16;
    recd_Data = step(hDemod,received_data);       %% this is the received binary symbol
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    recd_parallel_binData(:,i) = recd_Data;       %% this matrix contains each received symbol as different columns
end

received_binaryData = reshape(recd_parallel_binData, data_length, 1);
figure(2)
stem(received_binaryData);
title('Binary Data Received');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Symbol_Errors = symerr(binary_data,received_binaryData)  
