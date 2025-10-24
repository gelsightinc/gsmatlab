function [hm2,lf] = polydetrend(hm, ord, mask, vr, varargin)
%POLYDETREND Apply polynomial detrending to a surface.
%   HM2 = polydetrend(HM, ORD) performs polynomial detrending of order ORD on
%   the heightmap HM. The parameter ORD is an integer specifying the order of
%   the polynomial model from 1 to 10, 1 = linear, 2 = quadratic, etc. The
%   output HM2 is the heightmap after subtracting the polynomial model. 
%
%   HM2 = polydetrend(HM, ORD, MASK) performs polynomial detrending of order ORD
%   on the heightmap HM within the region specified by the binary mask MASK. 
%
%   HM2 = polydetrend(HM, ORD, MASK, VR) allows the user to select algorithm
%   version. VR = 1 uses random sampling, VR = 2 uses grid sampling
%
%   [HM2,PM] = polydetrend(HM, ORD, MASK) returns the polynomial model PM.
%
% See also shapemask

    settings.samplespercoeff = 25000;

    if ~isempty(varargin)
        settings = parseArgList(settings, varargin);
    end

    if ~exist('vr','var')
        vr = 1;
    end
    if ~exist('mask','var')
        mask = true(size(hm));
    end

    switch vr
        % No subsampling
        case 0
            [hm2,lf] = polydetrend_v0(hm, ord, mask, settings);

        % Random subsampling
        case 1
            [hm2,lf] = polydetrend_v1(hm, ord, mask, settings);

        % Regular grid sampling
        case 2
            [hm2,lf] = polydetrend_v2(hm, ord, mask, settings);

        otherwise
            error('unrecognized algorithm version');
    end


end

%
% Use all mask pixels
%
function [hm2,lf] = polydetrend_v0(hm, ord, mask, settings)

    [ydim,xdim] = size(hm);
    if ~exist('mask','var')
        mask = true(ydim,xdim);
    end

    dim = max(xdim,ydim);

    spdim = (ord+1)*(ord+2)/2;

    nmask = sum(mask(:));


    [xg,yg] = meshgrid((1:xdim)/dim,(1:ydim)/dim);

    % Coordinates of samples
    xv = xg(mask);
    yv = yg(mask);


    A = zeros(nmask,spdim);
    A(:,1) = 1;
    cx = 2;
    for x = 1 : ord
        for y = 0 : x
            A(:,cx) = xv.^(x-y) .* yv.^y;
            cx = cx + 1;
        end
    end

    qcf = A\hm(mask);

    
    lf = qcf(1)*ones(size(hm));
    cx = 2;
    for x = 1 : ord
        for y = 0 : x
            lf = lf + qcf(cx)*xg.^(x-y) .* yg.^y;
            cx = cx + 1;
        end
    end


    hm2 = hm - lf;

    % mask = false(size(hm));
    % mask(inds) = true;
    
end

%
% Subsample heightmap using random sampling
%
function [hm2,lf] = polydetrend_v1(hm, ord, mask, settings)

    % Number of samples per model coefficient
    samplespercoeff = settings.samplespercoeff;

    [ydim,xdim] = size(hm);

    dim = max(xdim,ydim);

    ncf = (ord+1)*(ord+2)/2;

    ntotal = sum(mask(:));
    nsamples = samplespercoeff * ncf;

    % Use all the samples if we're close to total
    if 1.5*nsamples > ntotal
        rx = mask;
        nsamples = ntotal;
    else
        rx = false(size(mask));
        inds = find(mask);
        ix = randperm(length(inds), nsamples);
        rx(inds(ix)) = true;
    end

    [yi,xi] = find(rx);
    xv = xi/dim;
    yv = yi/dim;


    A = zeros(nsamples,ncf);
    A(:,1) = 1;
    cx = 2;
    for x = 1 : ord
        for y = 0 : x
            A(:,cx) = xv.^(x-y) .* yv.^y;
            cx = cx + 1;
        end
    end

    hv = hm(rx);
    qcf = A\hv;

    [xv,yv] = meshgrid((1:size(hm,2))/dim, (1:size(hm,1))/dim);
    
    lf = qcf(1)*ones(size(hm));
    cx = 2;
    for x = 1 : ord
        for y = 0 : x
            lf = lf + qcf(cx)*xv.^(x-y) .* yv.^y;
            cx = cx + 1;
        end
    end


    hm2 = hm - lf;
    
end

%
% Subsample heightmap using regular grid
%
function [hm2,lf] = polydetrend_v2(hm, ord, mask, settings)

    % Number of samples per model coefficient
    samplespercoeff = settings.samplespercoeff;

    [ydim,xdim] = size(hm);
    if ~exist('mask','var')
        mask = true(ydim,xdim);
    end

    dim = max(xdim,ydim);

    spdim = (ord+1)*(ord+2)/2;

    nmask = sum(mask(:));
    Np = samplespercoeff * spdim;

    % Error case, insufficient number of pixels for detrending
    if nmask < spdim
        lf = zeros(ydim,xdim);
        hm2 = hm;
        return;
    end

    % Calculate the number of indices for the sample grid
    target_num_points = floor(min(Np, nmask));
    inds = sampleregulargridlinear(mask, size(hm), target_num_points);

    nsamples = length(inds);

    [xg,yg] = meshgrid((1:xdim)/dim,(1:ydim)/dim);

    % Coordinates of samples
    xv = xg(inds);
    yv = yg(inds);


    A = zeros(nsamples,spdim);
    A(:,1) = 1;
    cx = 2;
    for x = 1 : ord
        for y = 0 : x
            A(:,cx) = xv.^(x-y) .* yv.^y;
            cx = cx + 1;
        end
    end

    hv = hm(inds);
    qcf = A\hv;

    
    lf = qcf(1)*ones(size(hm));
    cx = 2;
    for x = 1 : ord
        for y = 0 : x
            lf = lf + qcf(cx)*xg.^(x-y) .* yg.^y;
            cx = cx + 1;
        end
    end


    hm2 = hm - lf;

    mask = false(size(hm));
    mask(inds) = true;
    
end

%
%
%
function settings = parseArgList(insettings, vargs)

    settings = insettings;
    if mod(numel(vargs),2) ~= 0
        error('variable argument list must be specified in key value pairs');
    end

    nargs = floor(numel(vargs)/2);
    for i = 1 : nargs
        fname = vargs{2*i-1};
        if ~isfield(settings,fname)
            warning('unrecognized field name %s',fname);
        end
        vl = vargs{2*i};
        settings.(fname) = vl;
    end

end

%
%
%
function inds = sampleregulargridlinear(mask, sz, max_count)
    ydim = sz(1);
    xdim = sz(2);

    maxpx = min(ydim*xdim, max_count);
    aspect_ratio = xdim/ydim;

    density = sum(mask(:))/(ydim*xdim);

    target_cols = floor( sqrt(maxpx*aspect_ratio/density) );
    ncols = max(1, target_cols);

    target_rows = floor( maxpx/ncols/density );
    nrows = max(1, target_rows);

    step_r = ydim / nrows;
    step_c = xdim / ncols;

    % inds = zeros(maxpx,1);
    % ix = 1;
    % for y = 1 : ydim
    %     row = min(max(round(y*step_r),1),ydim);
    %     for x = 1 : xdim
    %         col = min(max(round(x*step_c),1),xdim);
    %         if mask(y,x)
    %             inds(ix) = sub2ind(sz, row, col);
    %             ix = ix + 1;
    %         end
    %     end
    % end
    %
    % inds = inds(1:(ix-1));

    [xg,yg] = meshgrid(round(1:step_c:xdim), round(1:step_r:ydim));
    allinds = sub2ind(size(mask), yg(:), xg(:));
    valid = mask(allinds);
    inds = allinds(valid);


end
