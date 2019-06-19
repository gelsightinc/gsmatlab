function h = plotshape(fulltype,pts,clr)
%PLOTSHAPE Plots a shape in the current axes.
%   h = plotshape(SHAPE, S) plots the shape identified by the string SHAPE
%   and the array S. The return value is the chart line object returned from
%   the built-in plot command.
%
%   The form of the array S depends on the shape type:
%
%   Circle   S is a 1-by-3 array [X Y R] specifying the (X,Y) center and radius R
%            of the circle
%
%   Line     S is a 1-by-4 vector [X1 Y1 X2 Y2] or 2-by-2 array [X1 X2; Y1 Y2]
%            specifing the (X,Y) coordinates of the end points of the line 
%
%   Point    S is a 1-by-2 array [X Y] specifying the coordinates of the point
%
%   Polyline S is a 2-by-N array of points specifying a polyline or polygon
%
%   ROI      S is a 1-by-4 array [XMIN XMAX YMIN YMAX] specifying the coordinates
%            of a rectangular region of interest
%
%   See also getshape

% Last Modified: 6/19/2019

	typ = lower(fulltype(1:3));

	% Transpose points if necessary
	if size(pts,1) > 3
		pts = pts';
	end

	% Default values for color string
	if ~exist('clr','var')
		if strcmp(typ,'poi')	
			clr = 'b.';
		else
			clr = 'b';
		end
	end

	% Box is now called Polygon
	if strcmp(typ,'box')
		fulltype = 'polygon';
		typ      = 'pol';
	end


	% Bezier curve
	if strcmp(typ,'bez')
		npts = size(pts,2);
		dim  = size(pts,1);
		t = linspace(0,1,100);
		
		J = bezierbasis(t, npts-1);
		px = J*pts(1,:)';
		py = J*pts(2,:)';
		if dim == 3
			pz = J*pts(3,:)';
			plot3(px,py,pz,clr);
		else
			plot(px,py,clr);
		end

	% Uniform quadratic b-spline
	elseif strcmp(typ,'bsp')
		dim = size(pts,1);

		p = bspline2(pts);
		if dim == 3
			plot3(p(1,:),p(2,:),p(3,:),clr,'LineWidth',2);
		else
			plot(p(1,:),p(2,:),clr,'LineWidth',2);
		end
	
	% Closed b-spline
	elseif strcmp(typ,'cbs')
		dim = size(pts,1);

		p = closedbspline2(pts);
		if dim == 3
			plot3(p(1,:),p(2,:),p(3,:),clr,'LineWidth',2);
		else
			plot(p(1,:),p(2,:),clr,'LineWidth',2);
		end

	% Circle
	elseif strcmp(typ,'cir')
		% If specified in matrix form
		if (size(pts,1) == 3 && size(pts,2) == 3)
			pts = pts/pts(1);
			center = -pts(1:2,3);
			radius = sqrt(sum(center(1:2).^2) - pts(3,3));
		else
			center = pts(1:2);
			radius = pts(3);
		end

		thetas = linspace(0,2*pi,360)';
		pts = [center(1)+radius*cos(thetas) center(2)+radius*sin(thetas)];
		h = plot(pts(:,1),pts(:,2),clr);
		axis equal
		
	% Ellipse
	elseif strcmp(typ,'ell')
		% If not specified in matrix form
		if (size(pts,1) == 3 && size(pts,2) == 3)
			[x0,y0,a_ax,b_ax,phi] = ellipseparams(pts);
		else
			x0   = pts(1);
			y0   = pts(2);
			a_ax = pts(3);
			b_ax = pts(4);
			phi  = pts(5);
		end

		fitpts = ellipsepts(x0,y0,a_ax,b_ax,phi);
		h = plot(fitpts(:,1),fitpts(:,2),clr);
		axis equal

	
	% Line
	elseif strcmp(typ,'lin')	% lines
		% Plot a vector from the origin
        if all(size(pts) == [1 4]) || all(size(pts) == [4 1])
			h = plot([pts(1) pts(3)],[pts(2) pts(4)],clr,'LineWidth',2);

        elseif size(pts,2) == 1
			h = line([0 pts(1)],[0 pts(2)],'Color',clr,'LineWidth',2);
		
		% Plot a line between two points [x1 y1; x2 y2]
		elseif size(pts,2) == 2
			h = plot(pts(1,:),pts(2,:),clr,'LineWidth',2);
		
		elseif size(pts,2) == 3	
			h = plot(pts(1,2:3),pts(2,2:3),clr,'LineWidth',2);
		else
			h = plot(pts(1,3:4),pts(2,3:4),clr,'LineWidth',2);
		end

	% Point 2D
	elseif strcmp(typ,'poi') 
		[ydim,xdim] = size(pts);
		if any([ydim == 1 xdim == 1])
			if length(pts) == 2
				h = plot(pts(1),pts(2),clr);
			elseif length(pts) == 3
				h = plot3(pts(1),pts(2),pts(3),clr);
			else
				error('dimension of points must be 2 or 3.')
			end
		else
			if ydim == 3 & strcmp(lower(fulltype),'point3')
				h = plot3(pts(1,:),pts(2,:),pts(3,:),clr);
			else
				h = plot(pts(1,:),pts(2,:),clr);
			end

		end
	
	% Box
	% Polygon
	% Polyline
	elseif strcmp(typ,'pol')
		if strcmp(lower(fulltype),'polygon') == 1
            if norm(pts(:,end) - pts(:,1)) < 1e-3
                pts = [pts pts(:,1)];
            end
		end

		dim = size(pts,1);

		if dim==3
			plot3(pts(1,:),pts(2,:),pts(3,:),clr,'LineWidth',2)
		else
			plot(pts(1,:),pts(2,:),clr,'LineWidth',2)
		end
	
	% ROI
	elseif strcmp(typ,'roi')
		% I want the roi plotted outside the pixels
		if max(abs(pts)) > 10
			mnx = pts(1)-0.5;
			mxx = pts(2)+0.5;
			mny = pts(3)-0.5;
			mxy = pts(4)+0.5;
		else
			mnx = pts(1);
			mxx = pts(2);
			mny = pts(3);
			mxy = pts(4);
		end

		
		fullpts = [mnx mny; mxx mny; mxx mxy; mnx mxy; mnx mny]';
		
		h = plot(fullpts(1,:),fullpts(2,:),clr,'LineWidth',2);


	else
		error(sprintf('unrecognized type: %s',typ))
	end

	hold on

	if nargout == 0
		clear h
	end

end

	
%
%
%
function [fitpts] = ellipsepts(x0, y0, a_ax, b_ax, phi)

	n_pts = 360;
	
	ellipse_center = [x0 y0];

	thetas = linspace(0,2*pi,n_pts+1);
	thetas = thetas(1:n_pts);
	
	fitpts = [a_ax*cos(thetas); b_ax*sin(thetas)];
	R = [cos(phi) sin(phi); -sin(phi) cos(phi)];
	fitpts = R*fitpts;

	fitpts = repmat([x0 y0],n_pts,1) + fitpts';

end

%
%
%
function J = bezierbasis(t, N)

	coeffs = zeros(N+1,1);
	J = zeros(length(t),N+1);
	for i = 0 : N
		cf = nchoosek(N,i);
		J(:,i+1) = cf*(t.^i).*(1-t).^(N-i);
	end


end

%
%
%
function p = bspline2(control)

	npts = 200;

	dim = size(control,1);

	% degree
	p = 2;

	% number of control points is n+1
	nc = size(control,2);

	M = 0.5*[1 -2 1; -2 2 0; 1 1 0];

	np = floor(npts/(nc-2));
	t = linspace(0,1,np)';

	A = [t.^2 t ones(np,1)];

	p = zeros(dim,(nc-2)*np);
	for k = 2 : nc-1
		st = (k-2)*np + 1;
		ed = (k-1)*np;
		for d = 1 : dim
			px0 = control(d,k-1); 
			px1 = control(d,k+0); 
			px2 = control(d,k+1); 

			temp = A*M*[px0 px1 px2]';

			p(d,st:ed) = temp';
		end
	end

end

%
%
%
function p = closedbspline2(control)

	npts = 200;

	dim = size(control,1);

	% degree
	p = 2;

	% number of control points is n+1
	nc = size(control,2);

	M = 0.5*[1 -2 1; -2 2 0; 1 1 0];

	np = floor(npts/nc);
	t = linspace(0,1,np)';

	A = [t.^2 t ones(np,1)];

	p = zeros(dim,nc*np);
	for k = 1 : nc
		st = (k-1)*np + 1;
		ed = k*np;
		for d = 1 : dim
			ix1 = mod(k-2,nc)+1;
			ix2 = k;
			ix3 = mod(k,nc)+1;

			px0 = control(d,ix1); 
			px1 = control(d,ix2); 
			px2 = control(d,ix3); 

			temp = A*M*[px0 px1 px2]';

			p(d,st:ed) = temp';
		end
	end

end

