function scans = findscans(spath, scannm, tag)
%FINDSCANS Reads a 3D measurement saved in TMD format.
%   S = findscans(SPATH) finds all scans within the folder specified by the
%   string SPATH. 
%
%   The output S is a struct array with paths saved in the following fields: 
%       yamlpath    Path to scan.yaml file
%       tmdpath     Path to heightmap
%       nrmpath     Path to normal map
%       tmdfiles    Struct array of all heightmaps found in scan
%       nrmfiles    Struct array of all normal maps found in scan
%
%   S = findscans(SPATH, SCAN) finds all scans within the folder SPATH with 
%   names that contain the string SCAN. 
%
%   S = findscans(SPATH, SCAN, TAG) sets tmdpath and nrmpath to the TMD file
%   that contains the string TAG if multiple TMD files are present in the scan
%   folder. 
%

    if ~exist('scannm','var')
        scannm = [];
    end
    if ~exist('tag','var')
        tag = [];
    end
    
    localfiles = dir(spath);
    scans = [];
    sx    = 1;
    for i = 1 : numel(localfiles)
        % Skip hidden files and directories
        if strcmp(localfiles(i).name(1),'.')
            continue;
        end

        if length(localfiles(i).name) < length(scannm)
            continue;
        end

        % Skip files
        localpath = fullfile(spath,localfiles(i).name);
        if ~isdir(localpath)
            continue;
        end

        st = strfind(localfiles(i).name,scannm);

        scanpath = fullfile(localpath,'scan.yaml');
        % if the scannm is empty, then we save the scan
        % otherwise, we only save scans that match scannm
        if exist(scanpath,'file') && (isempty(scannm) || ~isempty(st))
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
    for i = 1 : numel(scans)
        if isempty(scans(i).tmdpath)
            scans(i) = add3dfiles(scans(i).yamlpath, tag);
        end
    end

end

%
%
%
function sdata = add3dfiles(yamlpath, tag)

    sdata.yamlpath = yamlpath;
    sdata.tmdpath = '';
    sdata.nrmpath = '';
    sdata.tmdfiles = [];
    sdata.nrmfiles = [];

    [fpath,scanfile] = fileparts(yamlpath);
    
    localfiles = dir(fpath);
    tmdfiles = [];
    tmdix = 1;
    tmdpath = '';
    for i = 1 : numel(localfiles)
        
        [tempdr,tempnm,tempex] = fileparts(localfiles(i).name);
        
        if strcmp(tempex,'.tmd')
            tmdfiles(tmdix).path = fullfile(fpath,localfiles(i).name);
            tmdix = tmdix + 1;
        end

        sx = strfind(localfiles(i).name,tag);
        if strcmp(tempex,'.tmd') && ~isempty(sx)
            tmdpath = fullfile(fpath,localfiles(i).name);
        end
                    
    end
        
    if ~isempty(tmdfiles) && length(tmdpath) == 0
        tmdpath = tmdfiles(1).path;
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
        
    nrmfiles = [];
    for tmdix = 1 : numel(tmdfiles)
        [tmdparent,tmdname,tmdext] = fileparts(tmdfiles(tmdix).path);
        localnrmpath = fullfile(tmdparent,[tmdname '_nrm.png']);
        if ~exist(localnrmpath,'file')
            localnrmpath = '';
        end 
        nrmfiles(tmdix).path = localnrmpath;
    end
        
    sdata.tmdpath  = tmdpath;
    sdata.nrmpath  = nrmpath;
    sdata.tmdfiles = tmdfiles;
    sdata.nrmfiles = nrmfiles;

end

