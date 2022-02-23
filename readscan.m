function sdata = readscan(fpath)
%READSCAN Reads a scan file.
%   SDATA = readscan(FILENAME) returns a structure whose fields contain 
%   information about the scan saved in the YAML file specified by the
%   string FILENAME.
%
%   The return value SDATA is a struct with the following fields:
%   
%   images       A struct array with complete paths to the images in the scan
%
%   mmperpixel   The XY spatial resolution in millimeters-per-pixel
%
%   annotations  A struct array of annotations (e.g., shapes) saved in the scan
%                file. Pixel coordinates are converted from origin (0,0) to 
%                origin (1,1) by adding 1.
%
%   See also writescan

    if ~exist(fpath,'file')
        error('cannot locate scan file: %s',fpath);
    end
    
    fd = fopen(fpath,'r');
    
    line = fgetl(fd);
    while ischar(line)
        % Find key
        colonix = strfind(line,':');
        lastline = [];
        if ~isempty(colonix)
            key = line(1:colonix-1);
            key = strtrim(key);
            
            value = strtrim(line(colonix+1:end));
            if strcmp(key, 'version')
                sdata.version = str2double(value);
            elseif strcmp(key,'iscalib')
                sdata.iscalib = strcmp(value,'true');
            elseif strcmp(key,'images')
                [impaths,lastline] = loadimages(fd, fpath);
                sdata.images = impaths;
            elseif strcmp(key,'calib')
                sdata.calib = findcalib(fpath, value);
            elseif strcmp(key,'calibradius')
                sdata.calibradius = str2num(value);
            elseif strcmp(key,'calibspacing')
                sdata.calibspacing = str2num(value);
            elseif strcmp(key,'crop')
                sdata.crop = str2num(value)+1;
            elseif strcmp(key,'guid')
                sdata.guid = value;
            elseif strcmp(key,'mmperpixel')
                sdata.mmperpixel = str2num(value);
            elseif strcmp(key,'annotations')
                [a,lastline] = loadannotations(fd);
                sdata.annotations = a;
            elseif strcmp(key,'routines')
                [s,lastline,lines] = ignorestruct(fd);
                sdata.routines = lines;
            elseif strcmp(key,'stage')
                [s,lastline,lines] = ignorestruct(fd);
                sdata.stage = lines;
            elseif strcmp(key,'camera')
                [a,lastline] = loadcamera(fd);
                sdata.camera = a;
            elseif strcmp(key,'device')
                [a,lastline] = loaddevice(fd);
                sdata.device = a;
            elseif strcmp(key,'target')
                [s,lastline] = loadtarget(fd);
                sdata.target = s;
                if strcmp(lower(s.type),'bga')
                    sdata.calibradius = s.radius;
                    sdata.calibspacing = s.pitch;
                end
            end
            
        end
        
        if ~isempty(lastline)
            line = lastline;
        else
            line = fgetl(fd);
        end
    end
    
    
    fclose(fd);
   
    % Now check the version of the scan file
    % If it is version 2.0 or greater, 
    % the annotations are now stored in Analysis/scancontext.yaml
    % annotations = shapes for this version
    if ~isfield(sdata,'version')
        sdata.version = 1;
    end

    if sdata.version >= 2
        [scandr,scanfile,scanext] = fileparts(fpath);
        scancontext = fullfile(scandr, 'Analysis/scancontext.yaml');
        if ~exist(scancontext, 'file')
            fprintf('no annotations %s\n',scancontext);
        else
            sdata.annotations = loadshapesasannotations(scancontext);
        end
    end 
    
end

%
%
%
function [impaths,lastline] = loadimages(fd, scanpath)
    
    [parentdr,parentnm,ext] = fileparts(scanpath);
    line = fgetl(fd);
    ix = 1;
    while ischar(line)
        % Lists must have dash then space
        dashix = strfind(line,'- ');
        if isempty(dashix)
            lastline = line;
            return;
        end
        
        name = strtrim(line(dashix+1:end));
        impaths(ix).path = fullfile(parentdr,name);
        impaths(ix).name = name;
        ix = ix + 1;
        line = fgetl(fd);
    end
    

end


%
%
%
function annotations = loadshapesasannotations(fpath)

    fd = fopen(fpath,'r');
    
    line = fgetl(fd);
    annotations = [];
    while ischar(line)

        % Find key

        colonix = strfind(line,':');
        lastline = [];
        if ~isempty(colonix)
            key = line(1:colonix-1);
            key = strtrim(key);
            
            value = strtrim(line(colonix+1:end));
            if strcmp(key, 'shapes')
                [a,lastline] = loadannotations(fd);
                annotations = a;
            end
            
        end
        
        if ~isempty(lastline)
            line = lastline;
        else
            line = fgetl(fd);
        end
    end
    
    fclose(fd);
    
end

%
%
%
function [annotations,lastline] = loadannotations(fd)
    
    line = fgetl(fd);
    lastline = line;
    ix = 0;
    while ischar(line)
        % Find dashes not associated with numbers
        dashes = (line == '-');
        numbers = isstrprop(line,'digit');
        dashix = find(dashes(1:end-1) & ~numbers(2:end));
        colonix = strfind(line,':');
        
        if isempty(colonix)
            line = fgetl(fd);
            continue;
        end
        % Count leading whitespace
        whiteix = min(find(isspace(line) == 0));
        if whiteix == 1
            lastline = line;
            return;
        end
        
        
        if ~isempty(dashix)
            ix = ix + 1;
            key = strtrim(line(dashix+1 : colonix-1));
        else
            key = strtrim(line(1:colonix-1));
        end
        
        value = strtrim(line(colonix+1:end));

        if strcmp(key,'type')
            annotations(ix).type = value;
        elseif strcmp(key,'name')
            annotations(ix).name = value;
        elseif strcmp(key,'label')
            annotations(ix).label = value;
        elseif strcmp(key,'id')
            annotations(ix).id = str2num(value);
        elseif strcmp(key,'x1')
            annotations(ix).x1 = str2num(value)+1;
        elseif strcmp(key,'x2')
            annotations(ix).x2 = str2num(value)+1;
        elseif strcmp(key,'y1')
            annotations(ix).y1 = str2num(value)+1;
        elseif strcmp(key,'y2')
            annotations(ix).y2 = str2num(value)+1;
        elseif strcmp(key,'x')
            annotations(ix).x = str2num(value)+1;
        elseif strcmp(key,'y')
            annotations(ix).y = str2num(value)+1;
        elseif strcmp(key,'gx')
            annotations(ix).gx = str2num(value);
        elseif strcmp(key,'gy')
            annotations(ix).gy = str2num(value);
        elseif strcmp(key,'r')
            annotations(ix).r = str2num(value);
        elseif strcmp(key,'w')
            annotations(ix).w = str2num(value);
        elseif strcmp(key,'h')
            annotations(ix).h = str2num(value);
        elseif strcmp(key,'closed')
            annotations(ix).closed = str2num(value);
        elseif strcmp(key,'points')
            annotations(ix).points = parsePointList(value);
        end
        %fprintf('%s : %s\n',key,value);
        
        line = fgetl(fd);
    end
    
    

end


%
% Load the target block
%
function [tgt,lastline] = loadtarget(fd)
    
    line = fgetl(fd);
    lastline = line;
    ix = 1;
    while ischar(line)
        colonix = strfind(line,':');
        
        if isempty(colonix)
            line = fgetl(fd);
            continue;
        end
        % Count leading whitespace
        whiteix = min(find(isspace(line) == 0));
        if whiteix == 1
            lastline = line;
            return;
        end
        
        
        key = strtrim(line(1:colonix-1));
        
        value = strtrim(line(colonix+1:end));

        if strcmp(key,'type')
            tgt(ix).type = value;
        elseif strcmp(key,'pitch')
            tgt(ix).pitch = str2num(value);
        elseif strcmp(key,'radius')
            tgt(ix).radius = str2num(value);
        end
        %fprintf('%s : %s\n',key,value);
        
        line = fgetl(fd);
    end

end

%
% Load the device block
%
function [tgt,lastline] = loaddevice(fd)
    
    line = fgetl(fd);
    lastline = line;
    ix = 1;
    while ischar(line)
        colonix = strfind(line,':');
        
        if isempty(colonix)
            line = fgetl(fd);
            continue;
        end
        % Count leading whitespace
        whiteix = min(find(isspace(line) == 0));
        if whiteix == 1
            lastline = line;
            return;
        end
        
        
        key = strtrim(line(1:colonix-1));
        value = strtrim(line(colonix+1:end));

        if strcmp(key,'devicetype')
            tgt(ix).devicetype = value;
        elseif strcmp(key,'devicetemp')
            tgt(ix).devicetemp = str2num(value);
        elseif strcmp(key,'serialnumber')
            tgt(ix).serialnumber = value;
        end
        %fprintf('%s : %s\n',key,value);
        
        line = fgetl(fd);
    end

end

%
% Load the camera block
%
function [cdata,lastline] = loadcamera(fd)
    
    line = fgetl(fd);
    lastline = line;

    % Initialize struct
    cdata.cameraid     = '';
    cdata.cameratype   = '';
    cdata.gelid        = '';
    cdata.lensfocuspos = 0;
    cdata.shutter      = 0;

    while ischar(line)
        colonix = strfind(line,':');
        
        if isempty(colonix)
            line = fgetl(fd);
            continue;
        end
        % Count leading whitespace
        whiteix = min(find(isspace(line) == 0));
        if whiteix == 1
            lastline = line;
            return;
        end
        
        key = strtrim(line(1:colonix-1));
        value = strtrim(line(colonix+1:end));

        if strcmp(key,'cameraid')
            cdata.cameraid = value;
        elseif strcmp(key,'cameratype')
            cdata.cameratype = value;
        elseif strcmp(key,'gelid')
            cdata.gelid = value;
        elseif strcmp(key,'lensfocuspos')
            cdata.lensfocuspos = str2num(value);
        elseif strcmp(key,'shutter')
            cdata.shutter = str2num(value);
        end
        %fprintf('%s : %s\n',key,value);
        
        line = fgetl(fd);
    end

end


%
%
%
function [st,lastline,lines] = ignorestruct(fd)
    st = 0;
    line = fgetl(fd);
    lastline = line;
    ix = 1;
    while ischar(line)
        dashix = strfind(line,'-');
        colonix = strfind(line,':');
    
        % Count leading whitespace
        whiteix = min(find(isspace(line) == 0));
        if whiteix == 1
            lastline = line;
            return;
        end
        
        lines{ix} = line;
        ix = ix + 1;
        line = fgetl(fd);
    end
end

%
% Parse point list for polygon / polyline
%
function pts = parsePointList(list)

    points = strrep(strrep(list, '[',''),']','');
    pat = '(?<x>\d+\.?\d*)\s*,\s*(?<y>\d+\.?\d*)';

    matches = regexp(points, pat, 'names');
    for i = 1 : numel(matches)
        pts(1,i) = str2num(matches(i).x)+1;
        pts(2,i) = str2num(matches(i).y)+1;
    end

end

%
% find calibration file
%
function cpath = findcalib(fpath, value)

    [scandr,scanfile] = fileparts(fpath);
    [setdr,scannm]    = fileparts(scandr);
    [parentdr,setnm]  = fileparts(setdr);
    [cdir,cname,cext] = fileparts(value);

    cfile = [cname cext];
    cpath = '';
    if isempty(cname)
        return;
    end

    found = false;
    % Does the set have the specified file?
    files = dir(setdr);
    cpath = '';
    for i = 1 : numel(files)
        if strcmp(files(i).name,cfile)
            cpath = fullfile(setdr, cfile);
            found = true;
            break;
        end
    end

    if ~found
        files = dir(parentdr);
        for i = 1 : numel(files)
            if strcmp(files(i).name,cfile)
                cpath = fullfile(setdr, cfile);
                found = true;
                break;
            end
        end
    end


end

