function resized = resize_image(image, width)
    [h, w, ~] = size(image);

    if isempty(width)
        resized = image;
        return;
    end
    
    ratio = width / w;
    dim = [round(h * ratio), width];

    resized = imresize(image, dim);
end