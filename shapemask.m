function bw = shapemask(fulltype,pts,sz)
%SHAPEMASK Make a mask from the specified shape.
%   BW = shapemask(SHAPE, S) creates a binary mask BW for shape specified by the
%   string SHAPE with parameters in the array S. The form of the array S depends
%   on the shape type:
%
%   Circle   S is a 1-by-3 array [X Y R] specifying the (X,Y) center and radius R
%            of the circle
%
%   Polygon  S is a 2-by-N array of points specifying a polygon. The algorithm
%            will repeat the first point if the polygon is not closed
%
%   ROI      S is a 1-by-4 array [XMIN XMAX YMIN YMAX] specifying the coordinates
%            of a rectangular region of interest
%
%   BW = shapemask(SHAPE, S, SZ) sets the size of the binary mask BW to be SZ.
%   The coordinates used for the shape are [X,Y] = meshgrid(1:SZ(2),1:SZ(1)).
%
%   See also getshape

% Last Modified: 6/19/2019

    typ = lower(fulltype(1:3));


    % Transpose points if necessary
    if size(pts,1) > 3
        pts = pts';
    end

    % Box is now called Polygon
    if strcmp(typ,'box')
        fulltype = 'polygon';
        typ      = 'pol';
    end

    if ~exist('sz','var')
        [sz,xl,yl] = sizefromshape(typ, pts);
    else
        xl = [1 sz(2)];
        yl = [1 sz(1)];
    end

    [xv,yv] = meshgrid(1:sz(2),1:sz(1));
    bw = false(sz);

    % Circle
    if strcmp(typ,'cir')
        bw = sqrt( (xv-pts(1)).^2 + (yv-pts(2)).^2 ) < pts(3);

    % Rectangular ROI
    elseif strcmp(typ,'roi')
        r = pts;
        ix = xv >= r(1) & xv <= r(2) & yv >= r(3) & yv <= r(4);
        bw(ix) = true;

    % Rectangle 
    elseif strcmp(typ,'rec')
        stx = pts(1);
        edx = pts(1) + pts(3);
        sty = pts(2);
        edy = pts(2) + pts(4);
        bw =  xv >= stx & xv <= edx & yv >= sty & yv <= edy;

    % Polygon
    elseif strcmp(typ,'pol')
        dst = norm(pts(:,1) - pts(:,end));
        if dst > 1
            p = [pts pts(:,1)];
        else
            p = pts;
        end
        bw = polymask(pts, xl, yl);

    else
        error(sprintf('unrecognized type: %s',fulltype));
    end


end

    
%
% Get mask size (nrows,ncols) from shape
%
function [sz,xl,yl] = sizefromshape(typ, pts)

    stx = 1; edx = 0; sty = 1; edy = 0;
    if strcmp(typ,'cir')
        stx = floor(pts(1)-pts(3));
        edx = ceil(pts(1)+pts(3));
        sty = floor(pts(2)-pts(3));
        edy = ceil(pts(2)+pts(3));

    elseif strcmp(typ,'roi')
        stx = floor(pts(1));
        edx = ceil(pts(2));
        sty = floor(pts(3));
        edy = ceil(pts(4));

    elseif strcmp(typ,'pol')
        stx = floor(min(pts(1,:)));
        edx = ceil(max(pts(1,:)));
        sty = floor(min(pts(2,:)));
        edy = ceil(max(pts(2,:)));

    elseif strcmp(typ,'rec')
        stx = floor(pts(1));
        edx = ceil(pts(1)+pts(3));
        sty = floor(pts(2));
        edy = ceil(pts(2)+pts(4));

    else
        error('unsupported shape type');
    end
    sz = [edy-sty+1 edx-stx+1];
    xl = [stx edx];
    yl = [sty edy];

end

%
%
%
function bw = polymask(pts, xl, yl)

    scale = 5;

    % Calculate approx number of points
    totalperim = scale*sum( sqrt(  sum((pts(:,2:end)-pts(:,1:end-1)).^2, 1) ) );

    % Allocate upscaled perimeter
    spts = zeros(2,round(1.25*totalperim));
    sx = 0;

    % Upscale the perimeter
    for i = 2 : size(pts,2)
        p1 = pts(:,i-1);
        p2 = pts(:,i);
        x1 = round(scale*(p1(1)-0.5) + 1);
        y1 = round(scale*(p1(2)-0.5) + 1);
        x2 = round(scale*(p2(1)-0.5) + 1);
        y2 = round(scale*(p2(2)-0.5) + 1);

        sg = lineptsi([x1 y1], [x2 y2]);
        spts(:,sx+(1:size(sg,2))) = sg;
        sx = sx + size(sg,2);

    end
    spts = spts(:,1:sx);

    % Find edge points
    epts = zeros(size(spts));
    sx = 0;
    for i = 1 : size(spts,2)-1
        dx = spts(1,i+1) - spts(1,i);
        my = min(spts(2,i), spts(2,i+1));
        if dx > 0
            epts(:,sx+1) = [spts(1,i); my];
            sx = sx+1;
        elseif dx < 0
            % If the change in x is negative, we store x-1
            epts(:,sx+1) = [spts(1,i)-1; my];
            sx = sx+1;
        end
    end
    epts = epts(:,1:sx);

    % Downscale
    s = (scale - 1)/2;

    mask = zeros(yl(2)-yl(1)+1, xl(2)-xl(1)+1);
    [ydim,xdim] = size(mask);
    epts(1,:) = epts(1,:) - xl(1) + 1;
    epts(2,:) = epts(2,:) - yl(1) + 1;

    for i = 1 : size(epts,2)
        p = epts(:,i);
        sx = (p(1)+s)/scale;
        tx = floor(sx);
        sy = ceil((p(2)+s)/scale);
        if abs(sx-tx) < 0.5/scale && sx >= 1 && sx <= xdim && sy <= ydim
            iy = max(sy,1);
            v = mask(iy,tx);
            mask(iy,tx) = v+1;
        end
    end

    % Bounding box
    [yy,xx] = find(mask > 0);
    stx = min(max( min(xx), 1), xdim);
    edx = min(max( max(xx), 1), xdim);
    sty = min(max( min(yy), 1), ydim);
    edy = min(max( max(yy), 1), ydim);

    % Process columns
    bw = false(size(mask));
    for x = stx : edx
        sm = 0;
        pval = false;
        for y = sty : edy
            v = mask(y,x);
            if v > 0
                sm = sm + v;
                pval = mod(sm,2) ~= 0 ;
            end
            bw(y,x) = pval;
        end
    end

end

%
% points along a line, restricted to integer coordinates
%
function pts = lineptsi(p1, p2)

    x1 = p1(1); y1 = p1(2);
    x2 = p2(1); y2 = p2(2);

    dx = abs(x2 - x1);
    dy = abs(y2 - y1);
    flip = false;
    if dx >= dy
        % Sample along x
        if x1 > x2
            [x2,x1] = deal(x1,x2);
            [y2,y1] = deal(y1,y2);
            flip = true;
        end
        m = (y2 - y1)/(x2 - x1);

        pts = zeros(2,x2-x1+1);
        pts(1,:) = x1 : x2;
        pts(2,:) = round(y1 + m*(pts(1,:)-x1));

    else
        % Sample along y
        if y1 > y2
            [x2,x1] = deal(x1,x2);
            [y2,y1] = deal(y1,y2);
            flip = true;
        end
        m = (x2 - x1)/(y2 - y1);

        pts = zeros(2,y2-y1+1);
        pts(2,:) = y1 : y2;
        pts(1,:) = round(x1 + m*(pts(2,:)-y1));

    end
    if flip
        pts = fliplr(pts);
    end

end


