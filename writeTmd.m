function writetmd(hm, mmp, fpath, roi)
%WRITETMD Writes a 3D surface to a TMD file.
%	writetmd(HM, MMP, FILENAME) writes the 3D surface HM with XY spatial 
%   resolution MMP in millimeters-per-pixel to the file specified by the 
%   string FILENAME.
%
%	writetmd(HM, MMP, FILENAME, ROI) writes the 3D surface HM with XY spatial
%	resolution MMP to the file specified by the string FILENAME using crop
%	region ROI specified by the row vector [XMIN XMAX YMIN YMAX]. The number of
%	rows in HM must be ROI(4)-ROI(3)+1 and the number of columns in HM must be
%   ROI(2)-ROI(1)+1, otherwise this region ROI does not correspond to the 
%   array HM.
%
%   See also readtmd

% Last Modified: 1/26/2014

    hasroi = false;
    if exist('roi','var') 
        if length(roi) ~= 4
            error('ROI must be specified as [XMIN XMAX YMIN YMAX]');
        end
        if size(hm) ~= [roi(4)-roi(3)+1  roi(2)-roi(1)+1]
            error('ROI and heightmap are not the same size');
        end
        hasroi = true;
    else
        roi = [];
    end

	fd = fopen(fpath, 'wb');

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

