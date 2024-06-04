function psnr_value = calculate_psnr(original, denoised)
    mse = mean((original(:) - denoised(:)).^2);
    if mse == 0
        psnr_value = Inf;
        return;
    end
    max_pixel = 1.0;  % since the image is in double format with range [0, 1]
    psnr_value = 20 * log10(max_pixel / sqrt(mse));
end