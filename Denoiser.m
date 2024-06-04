classdef Denoiser
    properties
        img_folder
        save_folder
        method
        noise_method
        gaus_var
        ps_prob
        strength
        strength_chroma
        psnr
        ssim
        count
    end
    
    methods
        function obj = Denoiser(img_folder, save_folder, method, noise_method, gaus_var, ps_prob, strength, strength_chroma)
            obj.img_folder = img_folder;
            if ~exist(save_folder, 'dir')
                mkdir(save_folder);
            end
            obj.save_folder = save_folder;
            obj.method = method;
            obj.noise_method = noise_method;
            obj.gaus_var = gaus_var;
            obj.ps_prob = ps_prob;
            obj.strength = strength;
            obj.strength_chroma = strength_chroma;
            obj.psnr = 0;
            obj.ssim = 0;
            obj.count = 0;
        end
        
        function start_simu(obj)
            imgNames = obj.get_all_image_files(obj.img_folder);
            num_images = length(imgNames);
            h = waitbar(0, 'progressing image starts ...');
            for i = 1:length(imgNames)
                imgName = imgNames{i};
                img_path = fullfile(obj.img_folder, imgName);
                save_de_img_name = [imgName(1:end-4), '_denoise.png'];
                save_de_img_path = fullfile(obj.save_folder, save_de_img_name);
                save_no_img_name = [imgName(1:end-4), '_noise.png'];
                save_no_img_path = fullfile(obj.save_folder, save_no_img_name);
                save_ori_img_path = [imgName(1:end-4), '_.png'];
                save_ori_img_path = fullfile(obj.save_folder, save_ori_img_path);
                obj.compute_single_image(img_path, save_ori_img_path, save_no_img_path, save_de_img_path, obj.strength, obj.strength_chroma, obj.method);
                waitbar(i / num_images, h)
            end
            close(h);
            fprintf('saved folder is %s\n', obj.save_folder);
            fprintf('dataset used is %s\n', obj.img_folder);
            fprintf('method is %s\n', obj.method);
            fprintf('noise method is %s\n', obj.noise_method);
            fprintf('gauss noise variance is %f\n', obj.gaus_var);
            fprintf('p&s noise probability is %f\n', obj.ps_prob);
            fprintf('averaged psnr is %f\n', obj.psnr / obj.count);
            fprintf('averaged ssim is %f\n', obj.ssim / obj.count);
        end
        
        function compute_single_image(obj, input, save_ori_img_path, save_no_img_path, save_de_img_path, strength, strength_chroma, method)
            if isempty(strength_chroma)
                strength_chroma = strength * 2;
            end

            try
                image = im2double(imread(input));
                % Process the image (add noise, denoise, etc.)
                % Save the original, noisy, and denoised images
            catch
                fprintf('Skipping file %s, as it is not a valid image.\n', input);
                return;
            end

            image = resize_image(image, 960);
            imwrite(image, save_ori_img_path);

            if strcmp(obj.noise_method, 'gauss')
                image_noise = add_gaussian_noise(image, obj.gaus_var);
            elseif strcmp(obj.noise_method, 'p&s')
                image_noise = add_salt_and_pepper_noise(image, obj.ps_prob, obj.ps_prob);
            else
                error('NotImplementedError');
            end
            imwrite(image_noise, save_no_img_path);

            if strcmp(method, 'gradient')
                out_arr = tv_denoise_gradient_descent(image, strength, strength_chroma);
            elseif strcmp(method, 'chambolle')
                out_arr = tv_denoise_chambolle(image, strength);
            else
                error('Invalid method');
            end

            obj.psnr = obj.psnr + calculate_psnr(image, out_arr);
            obj.ssim = obj.ssim + calculate_ssim(image, out_arr);
            obj.count = obj.count + 1;

            imwrite(out_arr, save_de_img_path);
        end
        
        function imgNames = get_all_image_files(~, folder)
            extensions = {'*.png', '*.jpg', '*.jpeg', '*.bmp', '*.tiff'};
            imgNames = {};
            for i = 1:length(extensions)
                imgFiles = dir(fullfile(folder, extensions{i}));
                imgNames = [imgNames; {imgFiles.name}];
            end
        end
    end
end
