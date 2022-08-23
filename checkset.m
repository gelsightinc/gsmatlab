function checkset(fpath)
%CHECKSET Check a set for images and TMD files
%   checkset(FOLDERPATH) iterates through all scans in a folder and
%   checks for image files and TMD files. 
%
%   
    scans = findscans(fpath);
    if numel(scans) == 0
        fprintf('no scans found in %s\n',fpath);
        return;
    end

    tmdcount = 0;
    completescan = 0;
    for i = 1 : numel(scans)
        if ~exist(scans(i).tmdpath,'file')
            fprintf('no tmd for %s\n',scans(i).name);
        else
            tmdcount = tmdcount + 1;
        end

        nimg = 0;
        sdata = readscan(scans(i).yamlpath);
        for j = 1 : numel(sdata.images)
            if exist(sdata.images(j).path,'file')
                nimg = nimg + 1;
            end
        end

        if nimg ~= numel(sdata.images)
            fprintf('missing images for %s\n',scans(i).name);
        else
            completescan = completescan + 1;
        end

    end
    fprintf('%d scans: %d TMDs, %d complete sets of images\n',...
        numel(scans),tmdcount,completescan);

end
