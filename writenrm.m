function writenrm(nrm, fpath)
%WRITENRM Save a normal map in PNG format.
%	writenrm(NRM, FILENAME) saves a normal map to the file specified by the
%	string FILENAME. 
%
%   The normal map NRM must be an M-by-N-by-3 array containing the unit-length
%   vectors at every pixel, with the X, Y and Z components of the 
%   surface normal saved in the channels 1-3, respectively. 
%

    if ~exist(fpath,'file')
        error('cannot find file %s',fpath);
    end

    cnrm = sqrt(sum(nrm.^2,3));
    nrm = nrm./repmat(cnrm,1,1,3);
    imwrite(im2uint16(min(max( (nrm+1)/2, 0),1)), fpath);

end
