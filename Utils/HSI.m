classdef HSI < handle
    %HIS is a Hyperspectral Image object, which can help you a lot.
    %
    %   HSI - Initialization Function
    %
    %   F - Flatten the 3D data to 2D data.
    %
    %   loacte - Return the spectra loacte at the given location.
    %
    %   result_reshape - If you use a target detection algorithm and the
    %       result is 1D, you can this function to reshape the result to
    %       2D image.
    %
    %---------------------------------------------------------------------%
    %   Usage:
    %   Assume the you have a 3D hyperspectral image array: hsi_array.
    %   You can use the following commands to create a HSI object
    %   and use it.
    %   h = HSI(hsi_array);
    %   
    %   X = h.F();
    %   loc = [x, y];
    %   d = h.locate(loc);
    %
    %   Assume that y is the target detection result.
    %   im = h.result_reshape(y);
    
    properties
        him
        shape
    end
    
    methods
        function obj = HSI(him)
            % The array him should be a 3D array: [m, n, l].
            % l should be the number of the bands.
            obj.him = him;
            obj.shape = size(him);
        end
        
        function X = F(obj)
            % Return a 2D array: [m*n, l].
            X = reshape(obj.him, [], obj.shape(end));
        end
        
        function D = locate(obj, loc, mode)
            % The default mode is '2D':
            % loc should be a 2D array: [num, 2].
            % The shape of D is : [num, l].
            %
            % In '1D' mode, the 3D array is reshaped to 2D.
            % So loc should be an index list: [num , 1].
            % The shape of D is also : [num, l].
            
            if ~exist('mode', 'var')
                mode = '2D';
            end
            
            if strcmp(mode, '1D')
                X = obj.F(obj.him);
                D = X(loc, :);
            elseif strcmp(mode, '2D')
                [num, dim] = size(loc);
                
                if dim ~= 2
                    error('Location list should be a n*2 array.')
                end
                
                D = zeros([num, obj.shape(end)]);
                for i = 1:num
                    D(i, :) = obj.him(loc(i, 2), loc(i, 1), :);
                end
            else
                error("Pararmeter 'mode' should be '1D' or '2D'.")
            end
        end
        
        function im = result_reshape(obj, y)
            % The detection result y is a 1D array: [m*n, 1].
            % This function will return a image: [m, n].
            im = reshape(y, obj.shape(1:2));
        end
        
        function remove_bands(obj, rm_list)
            all_list = 1:obj.shape(end);
            left_list = setdiff(all_list, rm_list);
            obj.him = obj.him(:, :, left_list);
        end
        
        function preprocess(obj, mode)
            if ~exist('mode', 'var')
                mode = 'norm';
            end
            
            if strcmp(mode, 'norm')
                m1 = max(obj.him, [], [1, 2]);
                m2 = min(obj.him, [], [1, 2]);
                obj.him = (obj.him - m2) ./ (m1 - m2);
            elseif strcmp(mode, 'std')
                mu = mean(obj.him, [1, 2]);
                sigma = std(obj.him, [], [1, 2]);
                obj.him = (obj.him - mu) ./ sigma;
            else
                error("Pararmeter 'mode' should be 'norm' or 'std'.")
            end
        end
        
        function Y = select_bands(obj, bands, mode)
            Y = obj.him(:, :, bands);
            if ~exist('mode', 'var')
                mode = '2D';
            end
            
            if strcmp(mode, '1D')
                Y = reshape(Y, [], length(bands));
            elseif strcmp(mode, '2D')
                return;
            else
                error("Pararmeter 'mode' should be '1D' or '2D'.")
            end
        end
        
        function rgb = rgb(obj, degree)
            if ~exist('degree', 'var')
                degree = 0.5;
            end
            
            [m, n, l] = size(obj.him);
            
            if degree <= 1/l || degree > 1
                error('Parameter degree should between 1/bands_num and 1!');
            end
            
            num = round(l * degree);

            X = reshape(obj.him, [], l);
            [Rn, Rs] = noise_signal_estim(obj.him);
            Rn_ = pinv(sqrtm(Rn));
            [V, ~] = eig(Rn_ * Rs * Rn_);
            Y = X * V;

            Y_ = Y(:, 1: num);
            V_ = V(:, 1: num);
            X_ = Y_ * V_'; 

            idx = FVGBS(reshape(X_, [m, n, l]), [], 3);
            rgb = obj.him(:, :, idx);
            m1 = max(rgb, [], [1, 2]);
            m2 = min(rgb, [], [1, 2]);
            rgb = (rgb - m2) ./ (m1 - m2);
        end
    end
end

