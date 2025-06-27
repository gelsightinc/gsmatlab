function [imout,ff] = readimg(fpath, ch, varargin)
%READIMG Reads an image from a scan.
%   IM = readimg(FILENAME) reads an image file specified by the string FILENAME.
%   FILENAME must be in the current directory, in a directory on the MATLAB
%   path, or include a full or relative path to a file. If FILENAME is a path to
%   a scan.yaml file, READIMG returns the first image in the scan.
%
%   IM = readimg(SCANFILE, CH) reads the image at channel CH from the scan.yaml
%   file specified by the string SCANFILE. The argument CH can be set to the
%   string 'all' to return all the channels as an M-by-N-by-L matrix where L is
%   the number of channels in the scan.
%
%   [IM,FF] = readimg(SCANFILE, CH, 'flatfield', F) reads the image at channel
%   CH from the scan.yaml file SCANFILE and applies flatfield correction if the
%   input argument F is set to true. The second output argument FF is the
%   flatfield model, which can be applied to future scans by supplying it as the
%   input argument F.
%

    % Was flatfield supplied?
    doflat = false;
    ff     = [];
    if numel(varargin) == 2 
        arg1 = varargin{1};
        arg2 = varargin{2};
        if strcmp(arg1(1:2),'ff') || strcmp(arg1(1:2),'fl')
            if isstruct(arg2)
                ff = arg2;
                doflat = true;
            elseif islogical(arg2) && arg2
                doflat = true;
            elseif isnumeric(arg2) && arg2 > 0
                doflat = true;
            end
        end
    end

    if ~exist(fpath,'file')
        error('cannot find file %s',fpath);
    end

    [parentdr,filenm,fileext] = fileparts(fpath);
    if strcmp(fileext,'.png')
        imout = im2double(imread(fpath));
    elseif strcmp(fileext,'.yaml')
        sdata = readscan(fpath);
        channels = 1;
        if ischar(ch) 
            if strcmp(ch,'all')
                channels = 1 : numel(sdata.images);
            elseif ch >= '1' && ch <= num2str(numel(sdata.images))
                channels = str2num(ch);
            end
        elseif isnumeric(ch)
            channels = max(min(ch, numel(sdata.images)), 1);
        end

        % Get image size
        info = imfinfo(sdata.images(1).path);
        ydim = info.Height;
        xdim = info.Width;

        imout = zeros(ydim,xdim,numel(channels));

        for i = 1 : numel(channels)
            cx = channels(i);
            img = im2double(imread(sdata.images(cx).path));

            if doflat && isfield(sdata,'calib') 
                cpath = sdata.calib;
                if ~exist(cpath,'file')
                    [pdir,filenm,fext] = fileparts(fpath);
                    cpath = fullfile(pdir,sdata.calib);
                end
                if ~exist(cpath,'file')
                    warning('cannot find calibration file');
                end
                if isempty(ff)
                    ff = flatfieldmodel(cpath);

                    if ~isfield(ff,'correction')
                        ff.correction = loadcmap(ff);
                    end
                end

                if ~isempty(ff.correction) && size(ff.correction,3) >= cx
                    img = min(max( img.*ff.correction(:,:,cx), 0), 1);;
                else
                    ff = [];
                end
            end
            imout(:,:,i) = img;
        end
    else
        error('unrecognized file type %s',fpath);
    end


end


%
% Load flatfield model from calibration file
%
function ff = flatfieldmodel(fpath)
    ff = [];
    if ~exist(fpath,'file')
        return;
    end
    
    fd = fopen(fpath,'r');
    
    line = fgetl(fd);
    while ischar(line)
        % Find key
        colons = strfind(line,':');
        lastline = [];
        if ~isempty(colons)
            colonix = colons(1);
            key = line(1:colonix-1);
            key = strtrim(key);
            
            value = strtrim(line(colonix+1:end));
            if strcmp(key,'flatfield')
                [a,lastline] = loadflatfield(fd);
                ff = a;
            end
        end
        if ~isempty(lastline)
            line = lastline;
        else
            line = fgetl(fd);
        end
    end
    fclose(fd);

    % Look for model file
    if ~isempty(ff) 
        [parentdr,calibnm,calibext] = fileparts(fpath);

        if ~isempty(ff.modelfile)
            files = dir(parentdr);
            found = false;
            modelpath = ff.modelfile;
            for i = 1 : numel(files)
                if strcmp(files(i).name,ff.modelfile)
                    modelpath = fullfile(parentdr,ff.modelfile);
                    found = true;
                end
            end
            if found && exist(modelpath,'file')
                ff.modelfile = modelpath;
            else
                ff = [];
            end

        else
            ff = [];
        end
    end


end

%
%
%
function [ff,lastline] = loadflatfield(fd)
    
    %modelfile: model.png
    %modelsize: 616, 514
    %nL: 6
    %scale: [0.507653710856, 0.502936759126, 0.487795945104, 0.497057198552, 0.487979214811, 0.502659764869]
    %size: 2464, 2056

    % Newer versions of scan.yaml can have parentheses for sizes
    %modelsize: (616, 514)
    %size: (2464, 2056)

    ff.modelfile = '';
    ff.modelsize = [1 1];
    ff.nL        = 6;
    ff.scale     = 0.5*ones(1,6);
    ff.size      = [1 1];

    line = fgetl(fd);
    lastline = line;
    ix = 1;
    while ischar(line)
        colons = strfind(line,':');
        
        if isempty(colons)
            line = fgetl(fd);
            continue;
        end
        % Count leading whitespace
        whiteix = min(find(isspace(line) == 0));
        if whiteix == 1
            lastline = line;
            return;
        end

        colonix = colons(1);
        
        key = strtrim(line(1:colonix-1));
        
        value = strtrim(line(colonix+1:end));

        if strcmp(key,'modelfile')
            ff.modelfile = value;
        elseif strcmp(key,'modelsize')
            ff.modelsize = str2num(regexprep(value,'[\(\)]',' '));
        elseif strcmp(key,'nL')
            ff.nL = str2num(value);
        elseif strcmp(key,'scale')
            ff.scale = str2num(value);
        elseif strcmp(key,'size')
            ff.size = str2num(regexprep(value,'[\(\)]',' '));
        end
        
        line = fgetl(fd);
    end

end



%
%
%
function correction = loadcmap(ff)

    correction = [];
	
    if ~exist(ff.modelfile,'file')
        return;
    end
    allch = im2double(imread(ff.modelfile));

    [yalldim,xalldim] = size(allch);
    nrows = floor((ff.nL-1)/3) + 1;

    xsm = ff.modelsize(1);
    ysm = ff.modelsize(2);
    if ~(xsm*3 == xalldim && ysm*nrows == yalldim)
        return;
    end

    xfull = ff.size(1);
    yfull = ff.size(2);

    cx = 1;
    correction = zeros(yfull,xfull,ff.nL);
    for r = 0 : (nrows-1)
        for c = 0 : 2
            xst =  c*xsm;
            yst =  r*ysm;
            img = allch(yst+(1:ysm), xst+(1:xsm));
            correction(:,:,cx) = ff.scale(cx) ./ imresize(img, [yfull xfull], 'bicubic');
            cx = cx + 1;
            if cx > ff.nL
                break;
            end
        end
    end



end


