function [hm2,lf] = polydetrend(hm, ord, mask)
%POLYDETREND Apply polynomial detrending to a surface.
%   HM2 = polydetrend(HM, ORD) performs polynomial detrending of order ORD on
%   the heightmap HM. The parameter ORD is an integer specifying the order of
%   the polynomial model from 1 to 10, 1 = linear, 2 = quadratic, etc. The
%   output HM2 is the heightmap after subtracting the polynomial model. 
%
%   HM2 = polydetrend(HM, ORD, MASK) performs polynomial detrending of order ORD
%   on the heightmap HM within the region specified by the binary mask MASK. 
%
%   [HM2,PM] = polydetrend(HM, ORD, MASK) returns the polynomial model PM.
%
% See also shapemask

    % Number of samples per model coefficient
    samplespercoeff = 15000;

    [ydim,xdim] = size(hm);
    if ~exist('mask','var')
        mask = true(ydim,xdim);
    end

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

