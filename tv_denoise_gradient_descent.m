function out = tv_denoise_gradient_descent(image, strength_luma, strength_chroma, callback, step_size, tol)
    if nargin < 4
        callback = [];
    end
    if nargin < 5
        step_size = 1e-2;
    end
    if nargin < 6
        tol = 3.2e-3;
    end

    RGB_TO_YUV = [
        0.2126, 0.7152, 0.0722;
        -0.09991, -0.33609, 0.436;
        0.615, -0.55861, -0.05639;
    ];

    YUV_TO_RGB = inv(RGB_TO_YUV);
    
    [h, w, c] = size(image);
    image = reshape(image, [], c) * RGB_TO_YUV';
    image = reshape(image, h, w, c);
    
    orig_image = image;
    momentum = zeros(size(image));
    momentum_beta = 0.9;
    loss_smoothed = 0;
    loss_smoothing_beta = 0.9;
    i = 0;

    while true
        i = i + 1;

        [loss, grad] = eval_loss_and_grad(image, orig_image, strength_luma, strength_chroma);

        if ~isempty(callback)
            callback(GradientDescentDenoiseStatus(i, loss));
        end

        % Stop iterating if the loss has not been decreasing recently
        loss_smoothed = loss_smoothed * loss_smoothing_beta + loss * (1 - loss_smoothing_beta);
        loss_smoothed_debiased = loss_smoothed / (1 - loss_smoothing_beta^i);
        if i > 1 && loss_smoothed_debiased / loss < tol + 1
            break;
        end

        % Calculate the step size per channel
        step_size_luma = step_size / (strength_luma + 1);
        step_size_chroma = step_size / (strength_chroma + 1);
        step_size_arr = reshape([step_size_luma, step_size_chroma, step_size_chroma], 1, 1, []);

        % Gradient descent step
        momentum = momentum * momentum_beta + grad * (1 - momentum_beta);
        image = image - step_size_arr ./ (1 - momentum_beta^i) .* momentum;
    end
    image = reshape(image, [], c) * YUV_TO_RGB';
    out = reshape(image, h, w, c);
end

function [loss, grad] = eval_loss_and_grad(image, orig_image, strength_luma, strength_chroma)
    % Computes the loss function for TV denoising and its gradient.
    [tv_loss_y, tv_grad_y] = tv_norm(image(:, :, 1));
    [tv_loss_uv, tv_grad_uv] = tv_norm(image(:, :, 2:3));
    tv_grad = zeros(size(image));
    tv_grad(:, :, 1) = tv_grad_y * strength_luma;
    tv_grad(:, :, 2:3) = tv_grad_uv * strength_chroma;
    [l2_loss, l2_grad] = l2_norm(image, orig_image);
    loss = tv_loss_y * strength_luma + tv_loss_uv * strength_chroma + l2_loss;
    grad = tv_grad + l2_grad;
end

function [loss, grad] = tv_norm(image, eps)
    if nargin < 2
        eps = 1e-8;
    end

    % Compute the isotropic total variation norm and its gradient
    x_diff = image(1:end-1, 1:end-1, :) - image(1:end-1, 2:end, :);
    y_diff = image(1:end-1, 1:end-1, :) - image(2:end, 1:end-1, :);
    grad_mag = sqrt(x_diff.^2 + y_diff.^2 + eps);
    loss = sum(grad_mag(:));
    dx_diff = x_diff ./ grad_mag;
    dy_diff = y_diff ./ grad_mag;
    grad = zeros(size(image));
    grad(1:end-1, 1:end-1, :) = dx_diff + dy_diff;
    grad(1:end-1, 2:end, :) = grad(1:end-1, 2:end, :) - dx_diff;
    grad(2:end, 1:end-1, :) = grad(2:end, 1:end-1, :) - dy_diff;
end


function [loss, grad] = l2_norm(image, orig_image)
    % Computes 1/2 the square of the L2-norm of the difference between the image and
    % the original image and its gradient.
    grad = image - orig_image;
    loss = sum(grad(:).^2) / 2;
end

function status = GradientDescentDenoiseStatus(i, loss)
    % A status object supplied to the callback specified in tv_denoise_gradient_descent().
    status.i = i;
    status.loss = loss;
end
