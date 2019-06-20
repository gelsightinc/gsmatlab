function hm2 = detrendQuadraticMask(hm, mask, md)

	settings.quadratic = true;
	if exist('md','var') && ~md
		settings.quadratic = false;
	end

	[ydim,xdim] = size(hm);

	dim = max(xdim,ydim);

	%[xi,yi] = meshgrid(1:xdim,1:ydim);
    [yi,xi] = find(mask);
	xv = xi/dim;
	yv = yi/dim;


	if settings.quadratic
		A = [xv.^3 xv.^2.*yv.^1 xv.*yv.^2 yv.^3 xv.^2 xv.*yv yv.^2 xv yv ones(sum(mask(:)),1)];
	else
		A = [xv yv ones(sum(mask(:)),1)];
	end

	hv = hm(mask);
	qcf0 = pinv(A)*hv;
	qcf = qcf0;

	epsilon = 1e-2;
	mxw = 1/(2*epsilon);
	for i = 1 : 5
		err = abs(A*qcf - hv);

		xw = 1./(2*max(err, epsilon));

		xw = xw/mxw;

		W = diag(sparse(xw));
		qcf = inv(A'*W*A)*A'*W*hv;
	end
	

	[xi,yi] = meshgrid(1:xdim,1:ydim);
	xv = xi(:)/dim;
	yv = yi(:)/dim;
	if settings.quadratic
		Afull = [xv.^3 xv.^2.*yv.^1 xv.*yv.^2 yv.^3 xv.^2 xv.*yv yv.^2 xv yv ones(ydim*xdim,1)];
	else
		Afull = [xv yv ones(ydim*xdim,1)];
	end
	plane = reshape(Afull*qcf,ydim,xdim);

	hm2 = hm - plane;
	md = prctile(hm2(:),50);
	hm2 = hm2 - md;
	
end

