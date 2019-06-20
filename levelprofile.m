function [rpts,A] = levelprofile(pts, rg)
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
%   matrix A.
%
% See also getprofile

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


    spts = pts;
    if nargin > 1
        spts = [];
        for i = 1 : numel(regions)
            r = regions{i};
            inds = find(pts(1,:) >= r(1) & pts(1,:) <= r(2));

            spts = [spts pts(:,inds)];
        end

    end

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
    rpts = pts - repmat(M,1,size(pts,2));
    rpts = R*rpts - repmat(Z0,1,size(pts,2));

    if nargout == 2
        A = eye(3,3);
        A(1:2,1:2) = R;
        A(1:2,3)   = -Z0 - R*M;
    end
    
end

%
%
%
function [U,T,M] = localpca(X)

    [nRows, nColumns] = size( X );

    % Compute the column vector mean
    M = mean( X, 2 );

    % The zero-mean form of X
    for k = 1 : nColumns
        X(:,k) = X(:,k) - M;
    end

    S = X*X'/(nColumns-1);
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

