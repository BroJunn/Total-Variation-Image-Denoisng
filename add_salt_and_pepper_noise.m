function noisy_image = add_salt_and_pepper_noise(image, salt_prob, pepper_prob)
    noisy_image = imnoise(image, 'salt & pepper', salt_prob);
end