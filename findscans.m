function scans = findscans(spath, scannm, tag)
%FINDSCANS Finds all scans and associated files under the specified path
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
    
    sdata = scandata();

    localfiles = dir(spath);
    scans = sdata([]);

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
        if ~isfolder(localpath)
            continue;
        end

        st = strfind(localfiles(i).name,scannm);

        scanpath = fullfile(localpath,'scan.yaml');

        % If stitch.yaml exists, treat stitched scan as a scan
        stitchpath = fullfile(localpath,'stitch.yaml');
        if exist(stitchpath,'file')
            scanpath = stitchpath;
        end

        % if the scannm is empty, then we save the scan
        % otherwise, we only save scans that match scannm
        if exist(scanpath,'file') && (isempty(scannm) || ~isempty(st))
            [scandr,scanfile,scanext] = fileparts(scanpath);
            [parentdr,scanfoldernm,sxt]   = fileparts(scandr);
            scans(sx).name     = [scanfoldernm sxt];
            scans(sx).yamlpath = scanpath;
            scans(sx).tmdpath  = '';
            scans(sx).nrmpath  = '';
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
function sdata = scandata()
    sdata.name     = '';
    sdata.yamlpath = '';
    sdata.tmdpath  = '';
    sdata.nrmpath  = '';
    sdata.tmdfiles = '';
    sdata.nrmfiles = '';
end

%
%
%
function sdata = add3dfiles(yamlpath, tag)

    [scandr,scanfile,scanext] = fileparts(yamlpath);
    [parentdr,scanfoldernm,sxt]   = fileparts(scandr);
    % sxt is non-empty when folder name ends with something that looks like an extension
    sdata.name     = [scanfoldernm sxt];   
    sdata.yamlpath = yamlpath;
    sdata.tmdpath  = '';
    sdata.nrmpath  = '';
    sdata.tmdfiles = [];
    sdata.nrmfiles = [];

    [fpath,scanfile] = fileparts(yamlpath);
    
    localfiles = dir(fpath);
    tmdfiles = [];
    nrmfiles = [];
    tmdix = 1;
    nrmix = 1;
    tmdpath = '';
    nrmpath = '';
    for i = 1 : numel(localfiles)
        
        [tempdr,tempnm,tempex] = fileparts(localfiles(i).name);
        
        % If the extension is tmd, add it to the list of TMD files
        if strcmp(tempex,'.tmd')
            tmdfiles(tmdix).path = fullfile(fpath,localfiles(i).name);
            tmdix = tmdix + 1;
        end

        % If the filename ends in _nrm.png, add it to the list of normal maps
        if ~isempty(strfind(localfiles(i).name,'_nrm.png'))
            nrmfiles(nrmix).path = fullfile(fpath,localfiles(i).name);
            nrmix = nrmix + 1;
        end

        % If this file contains the suffix, set tmdpath or nrmpath
        sx = [];
        if ~isempty(tag)
            sx = strfind(localfiles(i).name,tag);
        end
        if ~isempty(sx) 
            if strcmp(tempex,'.tmd')
                tmdpath = fullfile(fpath,localfiles(i).name);
            end
            if ~isempty(strfind(localfiles(i).name,'_nrm.png'))
                nrmpath = fullfile(fpath,localfiles(i).name);
            end
        end
                    
    end
        
    if ~isempty(tmdfiles) && length(tmdpath) == 0
        tmdpath = tmdfiles(1).path;
    end
    if ~isempty(nrmfiles) && length(nrmpath) == 0
        nrmpath = nrmfiles(1).path;
    end
        
    % If the tag isn't empty, make sure we found either tmdpath or nrmpath
    if ~isempty(tag) && isempty(nrmpath) && isempty(tmdpath)
        warning('no TMD or normal map found with tag = %s',tag);
    end
        
    if numel(tmdfiles) == 1
        tmdpath = tmdfiles(1).path;
    end
    if numel(nrmfiles) == 1
        nrmpath = nrmfiles(1).path;
    end
        
    if isempty(tag)
        if numel(tmdfiles) > 1 
            warning('%d TMD files found in %s, using first',numel(tmdfiles),scanfoldernm);
            tmdpath = tmdfiles(1).path;
        end
        if numel(nrmfiles) > 1 
            warning('%d normal maps found in %s, using first',numel(nrmfiles),scanfoldernm);
            nrmpath = nrmfiles(1).path;
        end
    end
        
    % Check for normal maps with same names as TMD files
    if ~isempty(tmdpath)
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
    end
        
    sdata.tmdpath  = tmdpath;
    sdata.nrmpath  = nrmpath;
    sdata.tmdfiles = tmdfiles;
    sdata.nrmfiles = nrmfiles;

end

