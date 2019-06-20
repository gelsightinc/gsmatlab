function nrm = readnrm(fpath)
%READNRM Reads a normal map saved in PNG format.
%   NRM = readnrm(FILENAME) reads a normal map from the file specified by the
%   string FILENAME. FILENAME must be in the current directory, in a
%   directory on the MATLAB path, or include a full or relative path to a file.
%
%   The return value NRM is an M-by-N-by-3 array containing the unit-length
%   surface normal at every pixel, with the X, Y and Z components of the 
%   surface normal saved in the channels 1-3, respectively. The values
%   of the X and Y components span the range -1 to 1 and the values of the 
%   Z component span the range 0-1. Positive Z values of the surface normal
%   face the observer.
%

    if ~exist(fpath,'file')
        error('cannot find file %s',fpath);
    end

    nrm = 2*im2double(imread(fpath))-1;

end
