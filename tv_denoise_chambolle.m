function out = tv_denoise_chambolle(image, strength, step_size, tol, callback)
    if nargin < 3
        step_size = 0.25;
    end
    if nargin < 4
        tol = 3.2e-3;
    end
    if nargin < 5
        callback = [];
    end

    image = im2double(image);
    [h, w, c] = size(image);
    p = zeros(2, h, w, c);
    image_over_strength = image / strength;
    diff = Inf;
    i = 0;
    
    while diff > tol
        i = i + 1;
        grad_div_p_i = grad(div(p) - image_over_strength);
        mag_gdpi = magnitude(grad_div_p_i, [1, 4], true);
        new_p = (p + step_size * grad_div_p_i) ./ (1 + step_size * mag_gdpi);
        diff = max(magnitude(new_p - p, [], false), [], 'all');
        p = new_p;
        
        % Print debug information
        % fprintf('Iteration %d, diff: %f\r', i, diff);
        
        % Safety break condition to prevent infinite loops
        if i > 1000
            warning('Max iterations reached. Breaking loop to prevent infinite run.');
            break;
        end
    end
    
    out = image - strength * div(p);
end
function out = magnitude(arr, axis, keepdims)
    if nargin < 2
        axis = 1; 
    end
    if nargin < 3
        keepdims = false; 
    end

    out = sqrt(sum(arr.^2, axis));

end

function out = grad(arr)
    [h, w, c] = size(arr);
    out = zeros(2, h, w, c);
    
    % Compute gradient along the first dimension
    out(1, 1:end-1, :, :) = arr(2:end, :, :) - arr(1:end-1, :, :);
    
    % Compute gradient along the second dimension
    out(2, :, 1:end-1, :) = arr(:, 2:end, :) - arr(:, 1:end-1, :);
end

function out = div(arr)
    [dim, h, w, c] = size(arr);
    out = zeros(h, w, c);
    
    % First dimension calculations
    out(1, :, :) = arr(1, 1, :, :);
    out(h, :, :) = -arr(1, h-1, :, :);
    out(2:h-1, :, :) = arr(1, 2:h-1, :, :) - arr(1, 1:h-2, :, :);
    
    % Second dimension calculations
    out(:, 1, :) = out(:, 1, :) + reshape(arr(2, :, 1, :), [h, 1, c]);
    out(:, w, :) = out(:, w, :) -  reshape(arr(2, :, w-1, :), [h, 1, c]);
    out(:, 2:w-1, :) = out(:, 2:w-1, :) + reshape(arr(2, :, 2:w-1, :) - arr(2, :, 1:w-2, :), [h, w-2, c]);
    
end