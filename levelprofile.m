function [rpts,A,lpts] = levelprofile(pts, rg, ord)
%LEVELPROFILE Level a profile to make the specified regions horizontal.
%   Q = levelprofile(P, REGIONS) levels the profile P according to the regions
%   specified in the array REGIONS. The output profile Q is the profile P
%   rotated to make the specified regions of profile P horizontal. 
%
%   The REGIONS parameter is an M-by-2 array of [START END] values for
%   a region in the same units as the first dimension of the profile P(1,:).  
%   The REGIONS parameter can also be a cell array of [START END] vectors 
%   specifying multiple regions to use together for leveling.
%
%   The leveling algorithm calculates a rotation to make the specified regions 
%   of the profile horizontal. 
%
%   [Q,A] = levelprofile(P, REGIONS) levels the profile P according to the 
%   regions specified in the array REGIONS and returns the transformation
%
%   [Q,A,Y] = levelprofile(P, REGIONS, ORD) fits a polynomial of order ORD
%   to the regions specified in the array REGIONS and performs higher-order
%   detrending by subtracting the best-fit polynomial Y from the surface.
%
% See also getprofile

    if ~exist('rg','var')
        rg = [1 size(pts,2)];
    end

    if ~iscell(rg)
        if size(rg,2) < 2
            error('regions parameter must be array or cell array');
        end
        for i = 1 : size(rg,1)
            regions{i} = rg(i,:);
        end
    else
        regions = rg;
    end

    % Detrending order
    if ~exist('ord','var')
        ord = 1;
    end

    allinds = 1 : size(pts,2);
    if nargin > 1
        allinds = [];
        for i = 1 : numel(regions)
            r = regions{i};
            inds = find(pts(1,:) >= r(1) & pts(1,:) <= r(2));

            allinds = [allinds inds];
        end

    end
    spts = pts(:,allinds);

    [U,T,M] = localpca(spts);

    % Rotate points if axis is flipped
    u = U(:,1);
    if u(1) < 0
        u = -u;
    end
    
    th = atan2(u(2),u(1));
    R = [cos(th) sin(th); -sin(th) cos(th)];
    
    % Mean value
    tpts = R*(spts - repmat(M,1,size(spts,2)));
    Z0 = mean(tpts,2);

    p1 = R*(pts(:,1)-M);
    Z0(1) = p1(1);
    rpts = pts - repmat(M,1,size(pts,2));
    rpts = R*rpts - repmat(Z0,1,size(pts,2));

    % Rigid transformation
    A = eye(3,3);
    A(1:2,1:2) = R;
    A(1:2,3)   =  -Z0 - R*M;

    lpts = inv(A)*[rpts(1,:); zeros(1,size(rpts,2)); ones(1,size(rpts,2))];

    % Higher-order detrending
    if ord > 1
        xv = rpts(1,allinds)';
        B = pmatrix(xv, ord);

        cf = B\rpts(2,allinds)';

		lf = cf(1)*ones(1,size(rpts,2));
		xv = rpts(1,:);

		for x = 1 : ord
            lf = lf + cf(x+1)*xv.^x;
        end
		rpts(2,:) = rpts(2,:) - lf;

        lpts = inv(A)*[rpts(1,:); lf; ones(1,size(rpts,2))];
    end
    lpts = lpts(1:2,:);
    
end

%
%
%
function [U,T,M] = localpca(X)

    [nRows, nColumns] = size( X );

    % Compute the column vector mean
    M = mean( X, 2 );

    % The zero-mean form of X
    Xzm = X - repmat(M,1,size(X,2));

    S = Xzm*Xzm'/(nColumns-1);
    [V,E] = eig(S);
    clear S;
    
    E = real(diag(E));  
    V = real(V);
  
    % Sort the eigenvalues
    [srtd,inds] = sort(E, 'descend');
    clear srtd
    
    U = V(:,inds);
    T = E(inds);
end

%
% matrix for polynomial fit
%
function A = pmatrix(xv, ord)

    nsamples = length(xv);
    ncf = ord + 1;
    A = zeros(nsamples,ncf);
    A(:,1) = 1;
    for x = 1 : ord
        A(:,x+1) = xv.^x;
    end

end
