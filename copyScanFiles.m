%copyScanFiles
%
% -Usage -
%    copyScanFiles(setpath, basenm, srcfile, tgtfile)
%
%
function copyScanFiles(setpath, basenm, srcfile, tgtfile)

    scanfiles = findScansInSet(setpath, basenm);
    
    fx = 0;
    for i = 1 : numel(scanfiles)
        [scandr,scanfilenm,~] = fileparts(scanfiles{i});
        [parentdr,scannm,~] = fileparts(scandr);
        
        % source file
        spath = fullfile(scandr, srcfile);
        if ~exist(spath,'file')
            fprintf('cannot find file %s in %s\n',srcfile,scannm);
            continue;
        end
        
        % target file
        tpath = fullfile(scandr,tgtfile);
        copyfile(spath, tpath);

        fx = fx+1;
    end
    fprintf('copied %d files\n',fx);
    

end
