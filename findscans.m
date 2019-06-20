function scans = findscans(spath, scannm, tag)
%FINDSCANS Reads a 3D measurement saved in TMD format.
%   S = findscans(SPATH) finds all scans within the folder specified by the
%   string SPATH. The output S is a struct array with paths to the scan.yaml, 
%   heightmap, and normalmap files. 
%

    if ~exist('scannm','var')
        scannm = [];
    end
    if ~exist('tag','var')
        tag = [];
    end
    
    localfiles = dir(fpath);
    scans = [];
    sx    = 1;
    for i = 1 : numel(localfiles)
        % Skip hidden files and directories
        if strcmp(localfiles(i).name(1),'.')
            continue;
        end

        if length(localfiles(i).name) < length(basenm)
            continue;
        end

        % Skip files
        localpath = fullfile(fpath,localfiles(i).name);
        if ~isdir(localpath)
            continue;
        end

        st = strfind(localfiles(i).name,basenm);

        scanpath = fullfile(localpath,'scan.yaml');
        % if the basenm is empty, then we save the scan
        % otherwise, we only save scans that match basenm
        if exist(scanpath,'file') && (isempty(basenm) || ~isempty(st))
            scans(sx).yamlpath = scanpath;
            scans(sx).tmdpath = '';
            scans(sx).nrmpath = '';
            scans(sx).tmdfiles = [];
            scans(sx).nrmfiles = [];
            sx = sx + 1;
            continue;
        end

        % If we get here, we are looking at a directory that does not
        % have a scan.yaml file
        if ~exist(scanpath,'file')
            tempscans = findscans(localpath, scannm, tag);
            for i = 1 : numel(tempscans)
                scans(sx) = tempscans(i);
                sx = sx + 1;
            end
        end
    end
    
    % Find 3D files within matching scans

end

%
%
%
function files = get3dfiles(fpath, basenm, tag)

    if ~exist('tag','var')
        tag = [];
    end
    
    allfiles = dir(fpath);
    ix = 1;
    for i = 1 : numel(allfiles)
        if length(allfiles(i).name) < length(basenm)
            continue;
        end
        
        st = strfind(allfiles(i).name,basenm);
        if isempty(st) || st ~= 1
            continue;
        end
        
        dpath = fullfile(fpath,allfiles(i).name);
        if ~isdir(dpath)
            continue;
        end
        
        localfiles = dir(dpath);
        tmdpath = '';
        images = [];
        tmdfiles = [];
        tmdix = 1;
        for j = 1 : numel(localfiles)
            [tempdr,tempnm,tempex] = fileparts(localfiles(j).name);
            
            if strcmp(localfiles(j).name,'scan.yaml')
                %thisscan = ReadYaml(fullfile(dpath,localfiles(j).name));
                thisscan = readscanfile(fullfile(dpath,localfiles(j).name));
                for imix = 1 : numel(thisscan.images)
                    images(imix).path = fullfile(dpath,thisscan.images(imix).path);
                end
            end
            
            if strcmp(tempex,'.tmd')
                tmdfiles(tmdix).path = fullfile(dpath,localfiles(j).name);
                
                tmdix = tmdix + 1;
            end

            sx = strfind(localfiles(j).name,tag);
            if strcmp(tempex,'.tmd') && ~isempty(sx)
                tmdpath = fullfile(fpath,allfiles(i).name,localfiles(j).name);
            end
                        
        end
        
        if ~isempty(tmdfiles) && length(tmdpath) == 0
            tmdpath = tmdfiles(1).path;
        end
        
        if length(tmdpath) == 0 && isempty(images)
            continue;
        end
        
        if isempty(tmdpath) && ~isempty(tag)
            warning('no TMD file found with tag = %s',tag);
        end
        
        if numel(tmdfiles) == 1
            tmdpath = tmdfiles(1).path;
        end
        
        if numel(tmdfiles) > 1 && isempty(tag)
            warning('%d TMD files found in %s, using first',numel(tmdfiles),dpath);
            tmdpath = tmdfiles(1).path;
        end
        
        % Check for normal maps with same names as TMD files
        [tmdparent,tmdname,tmdext] = fileparts(tmdpath);
        nrmpath = fullfile(tmdparent,[tmdname '_nrm.png']);
        if ~exist(nrmpath,'file')
            nrmpath = '';
        end
        
        for tmdix = 1 : numel(tmdfiles)
            [tmdparent,tmdname,tmdext] = fileparts(tmdfiles(tmdix).path);
            localnrmpath = fullfile(tmdparent,[tmdname '_nrm.png']);
            if ~exist(localnrmpath,'file')
                localnrmpath = '';
            end 
            nrmfiles(tmdix).path = localnrmpath;
        end
        
        files(ix).scanpath = fullfile(dpath,'scan.yaml');
        files(ix).tmdpath  = tmdpath;
        files(ix).nrmpath  = nrmpath;
        files(ix).tmdfiles = tmdfiles;
        files(ix).nrmfiles = nrmfiles;
        files(ix).images   = images;
        ix = ix + 1;
    end

end

