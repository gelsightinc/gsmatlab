%write_tmd
%	
%
% -Usage-
%	write_tmd(hm, mmp, fname)
%	write_tmd(hm, mmp, roi, fname)
%
% -Inputs-
%	hm       The heightmap in mm
%	mmp
%   [roi]    Region of interest (hm comes from larger scan)
%            [x1 x2 y1 y2]
%	fname
%
% -Outputs-
%	None
%
% Last Modified: 8/24/2017
function write_tmd(hm, mmp, varargin)

    hasroi = false;
    if nargin == 3
        if ~ischar(varargin{1})
            error('third input must be a filename');
        end
        fname = varargin{1};
    elseif nargin == 4
        if ~isnumeric(varargin{1}) || ~(length(varargin{1}) == 4)
            error('ROI must be specified as 4 numbers [x1 x2 y1 y2]');
        end
        roi = varargin{1};
        hasroi = true;
        if ~ischar(varargin{2})
            error('fourth input must be a filename');
        end
        fname = varargin{2};

        if size(hm) ~= [roi(4)-roi(3)+1  roi(2)-roi(1)+1]
            error('ROI and heightmap are not the same size');
        end
    end


	fd = fopen(fname, 'wb');

	header = 'Binary TrueMap Data File v2.0\r\n\0';
	header = zeros(32,1,'uint8');
	header(1:29) = 'Binary TrueMap Data File v2.0';
	header(30) = uint8(13); % '\r';
	header(31) = uint8(10); % '\n';
	header(32) = uint8(0); % '\0';
	fwrite(fd,header);

	% comment field
	header(1) = uint8(0); % '\0';
	fwrite(fd,header(1));

	% Image size
	[rows,cols] = size(hm);
	buf = int2charbuf(cols);
	fwrite(fd,buf);

	buf = int2charbuf(rows);
	fwrite(fd,buf);

	% Length of x and y
	lengthx = zeros(1,1,'single');
	lengthx(1) = mmp*cols;

	lengthy = zeros(1,1,'single');
	lengthy(1) = mmp*rows;
	fwrite(fd,lengthx,'float32');
	fwrite(fd,lengthy,'float32');

	% Offsets
    if ~hasroi
        zero = zeros(1,1,'single');
        fwrite(fd,zero,'float32');
        fwrite(fd,zero,'float32');
    else
        offsetx = zeros(1,1,'single');
        offsetx(1) = mmp*(roi(1)-1);

        offsety = zeros(1,1,'single');
        offsety(1) = mmp*(roi(3)-1);
        fwrite(fd,offsetx,'float32');
        fwrite(fd,offsety,'float32');
    end

	% Write matrix
	hmt = hm';
	fwrite(fd,hmt(:),'float32');

	fclose(fd);
end

%
%
%
function buf = int2charbuf(x)
	xbuf = zeros(1,1,'uint32');
	xbuf(1) = x;
	buf = zeros(4,1,'uint8');

	buf(4) = bitand(bitshift(xbuf,-24), uint32(255));
	buf(3) = bitand(bitshift(xbuf,-16), uint32(255));
	buf(2) = bitand(bitshift(xbuf,-8 ), uint32(255));
	buf(1) = bitand(xbuf, uint32(255));

end

