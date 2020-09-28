function p = getprofile(hm, ln, mmpp)
%GETPROFILE Extract a profile along a line from a height map or normal map.
%   P = getprofile(HM, LN, MMPP) returns a height profile P by interpolating 
%   the heightmap HM along the line specified by LN. The line LN is either a
%   1-by-4 vector [X1 Y1 X2 Y2] or a 2-by-2 array [X1 X2; Y1 Y2] specifying 
%   the end points of the line in in pixel coordinates. 
%
%   P = getprofile(NRM, LN, MMPP) returns a height profile P by integrating 
%   the normal map NRM along the line specified by LN. The line LN is either a
%   1-by-4 vector [X1 Y1 X2 Y2] or a 2-by-2 array [X1 X2; Y1 Y2] specifying 
%   the end points of the line in in pixel coordinates. 
%
%   The parameter MMPP specifies the spatial resolution of the heightmap or in
%   normal map in millimeters-per-pixel. The output array P is a 2-by-N array 
%   specifying the position and height (Z) of the profile in millimeters. 
%   The length of the profile N is determined by the length of the input line 
%   in pixels. 
%

    if all(size(ln) == [1 4]) || all(size(ln) == [4 1])
        p1 = [ln(1) ln(2)]';
        p2 = [ln(3) ln(4)]';
    elseif all(size(ln) == [2 2])
        p1 = ln(:,1);
        p2 = ln(:,2);
    else
        error('Line has incorrect number of elements');
    end

    if ~exist('mmpp','var')
        error('The resolution parameter mmpp must be specified to calculate the profile');
    end

    [ydim,xdim,zdim] = size(hm);
    mxdst = sqrt(xdim^2 + ydim^2);
    np = ceil(norm(p2 - p1));
    if np > mxdst
        error('line is too large for image');
    end

    xv = linspace(p1(1),p2(1),np);
    yv = linspace(p1(2),p2(2),np);
    t = sqrt( (xv-xv(1)).^2 + (yv-yv(1)).^2 )*mmpp;

    if zdim == 1
        z = interp2(hm, xv, yv, 'bicubic');

    elseif zdim == 3
		z = lineintegralmid(hm, [xv; yv],0);
        z = z*mmpp;

    else
        error('first input must have zdim == 1 or 3');
    end

    p = [t(:) z(:)]';

end
 

%
% mid point method
%
function z = lineintegralmid(nrm,pts,z0)
    np = size(pts,2);

    % Interpolate at points and mid points
    N = np + np-1;
    fullpts = zeros(2,N);
    fullpts(:,1:2:N) = pts;
    fullpts(:,2:2:N) = (pts(:,1:np-1) + pts(:,2:np))/2;

    % Avoid division by small Nz
    nrm(:,:,3) = max(nrm(:,:,3),1e-2);
	nm = sqrt(sum(nrm.^2,3));
	nrm = nrm ./ repmat(nm,[1 1 3]);

	nx = interp2(nrm(:,:,1), fullpts(1,:), fullpts(2,:), 'cubic');
	ny = interp2(nrm(:,:,2), fullpts(1,:), fullpts(2,:), 'cubic');
	nz = interp2(nrm(:,:,3), fullpts(1,:), fullpts(2,:), 'cubic');
    sx = -nx ./ nz;
    sy = -ny ./ nz;

	z = zeros(np,1);
    for i = 2 : np
		dx = pts(1,i) - pts(1,i-1);
		dy = pts(2,i) - pts(2,i-1);

		h = sqrt(max(dx^2 + dy^2, 1e-8));
        ux = dx/h;
        uy = dy/h;

        cix = 2*(i-1)+1;
        mix = cix-1;
        pix = cix-2;

        k1 = ux*sx(pix) + uy*sy(pix);
        k2 = ux*sx(mix) + uy*sy(mix);
        k3 = ux*sx(cix) + uy*sy(cix);
        zv = z(i-1) + h*(k1 + 4*k2 + k3)/6;

		z(i) = zv;
	end

    
end

%
%
%
function npts = interpolatenrm(nrm, pts)

    np = size(pts,2);
    npts = ones(3,np);
    
	for i = 1 : 2
		npts(i,:) = interp2(nrm(:,:,i)./nrm(:,:,3), pts(1,:)', pts(2,:)', 'bicubic');
	end
    
    nm = max(sqrt(sum(npts.^2,1)), 1e-3);
    npts = npts ./ repmat(nm,[3 1]);
end




