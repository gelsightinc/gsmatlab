function copyScanFiles(spath, basenm, srcfile, tgtfile)
%COPYSCANFILES  Copy scan.yaml files within scan folders to a different name
%
%   copyScanFiles(spath, basenm, srcfile, tgtfile)
%
%
 
% Author: Kimo Johnson, kimo@gelsight.com
% Last revision: June 18, 2019


    scanfiles = findScansInSet(spath, basenm);
    
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
