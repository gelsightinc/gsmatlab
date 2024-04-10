function sdata = readtarget(fpath)
%READSCAN Reads a target file.
%   TDATA = readtarget(FILENAME) returns a structure whose fields contain 
%   information about the scan saved in the YAML file specified by the
%   string FILENAME.
%
%   The return value TDATA is a struct with the fields that depend on the target
%   type.
%

    if ~exist(fpath,'file')
        error('cannot locate yaml file: %s',fpath);
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
            if strcmp(key,'type')
                sdata.type = value;
            elseif strcmp(key,'radius')
                sdata.calibradius = str2num(value);
            elseif strcmp(key,'pitch')
                sdata.calibspacing = str2num(value);
            elseif strcmp(key,'shapes')
                [a,lastline] = loadannotations(fd);
                sdata.annotations = a;
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

