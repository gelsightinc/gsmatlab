function p = getprofile(hm, ln, mmpp)
%GETPROFILE Extract a profile along a line from a height map
%   P = getprofile(HM, LN, MMPP) returns a height profile P by interpolating 
%   the heightmap HM along the line specified by LN. The line LN is either a
%   1-by-4 vector [X1 Y1 X2 Y2] or a 2-by-2 array [X1 X2; Y1 Y2] specifying 
%   the end points of the line in in pixel coordinates. 
%
%   The parameter MMPP specifies the spatial resolution of the heightmap HM in
%   millimeters-per-pixel. The output array P is a 2-by-N array specifying the
%   position and height (Z) of the profile in millimeters. The length of the
%   profile N is determined by the length of the input line in pixels. 
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

    [ydim,xdim] = size(hm);
    mxdst = sqrt(xdim^2 + ydim^2);
    np = ceil(norm(p2 - p1));
    if np > mxdst
        error('line is too large for image');
    end

    xv = linspace(p1(1),p2(1),np);
    yv = linspace(p1(2),p2(2),np);
    z = interp2(hm, xv, yv, 'bicubic');
    
    t = sqrt( (xv-xv(1)).^2 + (yv-yv(1)).^2 )*mmpp;
   
    p = [t(:) z(:)]';

end
