clear;
clc;

img_folder = 'images';     % images
save_folder = 'exp01';
method = 'gradient';    % chambolle or gradient
noise_method = 'gauss';    %  gauss or p&s
gaus_var = 0.01;
ps_prob = 0.05;
strength = 0.1;
strength_chroma = 0.2;

denoiser = Denoiser(img_folder, save_folder, method, noise_method, gaus_var, ps_prob, strength, strength_chroma);
denoiser.start_simu();