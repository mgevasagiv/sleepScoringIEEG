function plotSpectrogram(data, samplingRate)

% parameters
params.ds_SR = 200;
scaling_factor_delta_log = 2*10^-4 ; % Additive Factor to be used when computing the Spectrogram on a log scale
flimits = [0 30];

data_ds = accurateResampling(data(1:end), samplingRate, params.ds_SR);
window = 30*params.ds_SR;
[S,F,T,P]  = spectrogram(data_ds,window,0,[0.5:0.2:flimits(2)],params.ds_SR,'yaxis');
P = P/max(max(P));
P1 = (10*log10(abs(P+scaling_factor_delta_log)))';
P1 = [P1(:,1) P1 P1(:,end)];
T = [0 T T(end)+1];
Pplot = imgaussfilt(P1',3);
imagesc(T,F,Pplot,[-40,-15]); % Thresholding high-delta band dominance 
axis xy; 

end