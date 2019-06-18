%read_tmd
%
%
% -Usage-
%	[hm,data] = read_tmd(fname)
%
% -Inputs-
%	fname
%
% -Outputs-
%	hm
%	data
%
% Last Modified: 1/26/2014
function [hm,data] = read_tmd(fname)

	fd = fopen(fname,'r'); 
	if fd == -1
		error('read_tmd cannot open %s',fname);
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

	data.mmp     = data.lengthx / cols;

	hmbuf = fread(fd, rows*cols, 'single');
	hm = reshape(hmbuf,[cols rows])';

	fclose(fd);
end
