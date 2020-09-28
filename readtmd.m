function [hm,data] = readtmd(fpath)
%READTMD Reads a 3D measurement saved in TMD format.
%   [HM,DATA] = readtmd(FILENAME) reads the 3D surface from the file specified
%   by the string FILENAME. FILENAME must be in the current directory, in a
%   directory on the MATLAB path, or include a full or relative path to a file.
%
%   The return value HM is an array containing the 3D surface Z values in
%   millimeters. The return value DATA is a struct with the following fields:
%   
%   lengthx   The length of the x-axis in millimeters 
%
%   lengthy   The length of the y-axis in millimeters 
%
%   offsetx   The offset of this surface along the x-axis in millimeters with 
%             respect to the full field of view. This field and offsety are 
%             set when the 3D algorith is run in a cropped region.
%
%   offsety   The offset of this surface along the y-axis in millimeters with 
%             respect to the full field of view. 
%
%   mmpp      The XY spatial resolution in millimeters-per-pixel
%
%   See also writetmd

% Last Modified: 9/28/2020

    if ~exist(fpath,'file')
        error('cannot find file %s',fpath);
    end

    fd = fopen(fpath,'r'); 
    if fd == -1
        error('read_tmd cannot open %s',fpath);
    end

    header = fread(fd, 32, 'uchar');

    actheader = zeros(32,1,'uint8');
    actheader(1:29) = 'Binary TrueMap Data File v2.0';
    actheader(30) = uint8(13); % '\r';
    actheader(31) = uint8(10); % '\n';
    actheader(32) = uint8(0); % '\0';
    
    if any(header ~= actheader)
        error('incorrect header');
    end

    comments = [];
    byte = fread(fd, 1, 'uint8');
    while byte ~= 0
        comments = [comments byte];
        byte = fread(fd, 1, 'uint8');
    end

    % Read number of columns
    cols = fread(fd, 1, 'uint32');

    % Read number of rows
    rows = fread(fd, 1, 'uint32');

    % Length of axes
    data.lengthx = fread(fd, 1, 'single');
    data.lengthy = fread(fd, 1, 'single');

    % Offsets
    data.offsetx = fread(fd, 1, 'single');
    data.offsety = fread(fd, 1, 'single');

    data.mmpp    = data.lengthx / cols;

    hmbuf = fread(fd, rows*cols, 'single');
    hm = reshape(hmbuf,[cols rows])';

    fclose(fd);
end
