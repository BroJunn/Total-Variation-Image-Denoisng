function noisy_image = add_gaussian_noise(image, var)
    mean = 0;
    noisy_image = imnoise(image, 'gaussian', mean, var);
end