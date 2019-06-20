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
%   BW = shapemask(SHAPE, S, SZ) sets the size of the binary mask BW to be SZ
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
        sz = sizefromshape(typ, pts);
    end

    bw = false(sz);
    [xv,yv] = meshgrid(1:sz(2),1:sz(1));


	% Circle
	if strcmp(typ,'cir')
        bw = sqrt( (xv-pts(1)).^2 + (yv-pts(2)).^2 ) < pts(3);

	% Rectangular ROI
	elseif strcmp(typ,'roi')
        r = round(pts);
        bw(r(3):r(4),r(1):r(2)) = true;
	
	% Polygon
	elseif strcmp(typ,'pol')
        dst = norm(pts(:,1) - pts(:,end));
        if dst > 1
            p = [pts pts(:,1)];
        else
            p = pts;
        end
        bw = polymask(pts);

	else
		error(sprintf('unrecognized type: %s',fulltype));
	end


end

	
%
% Get mask size (nrows,ncols) from shape
%
function sz = sizefromshape(typ, pts)

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
    else
        error('unsupported shape type');
    end
    sz = [edy-sty+1 edx-stx+1];

end

%
%
%
function bw = polymask(pts)

    scale = 5;

    % upscale the perimeter



end

