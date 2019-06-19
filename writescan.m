function writescan(sdata, outname)
%WRITESCAN Saves a scan struct in YAML format.
%	writescan(SDATA, FILENAME) saves a scan struct SDATA to the file specified 
%   by the string FILENAME.
%   
%   The struct SDATA is assumed to have some of the following fields:
%   
%   images       A struct array with complete paths to the images in the scan
%
%   mmperpixel   The XY spatial resolution in millimeters-per-pixel
%
%   annotations  A struct array of annotations (e.g., shapes).  Pixel 
%                coordinates are converted from origin (1,1) to origin (0,0) 
%                by subtracting 1.
%
%   See also readscan

    fd = fopen(outname,'w');
    writefield(fd, sdata, 'iscalib', 'logical');
    
    fprintf(fd,'images:\n');
    for i = 1 : numel(sdata.images)
        fprintf(fd, '  - %s\n',sdata.images(i).name);
    end
    fields = {'calibradius', 'calibspacing', 'mmperpixel'};
    for i = 1 : numel(fields)
        writefield(fd, sdata, fields{i}, 'double');
    end
    writefield(fd, sdata, 'calib', 'string');
    
    if isfield(sdata,'crop')
        fprintf(fd,'crop: [%d, %d, %d, %d]\n',sdata.crop-1);
    end
      
    if isfield(sdata,'stage')
        fprintf(fd,'stage:\n');
        if iscell(sdata.stage)
            for i = 1 : numel(sdata.stage)
                fprintf(fd,'%s\n',sdata.stage{i});
            end
        else
        
        fields = {'posx','posy','posz'};
        for i = 1 : numel(fields)
            fprintf(fd,'  %s: %d\n',fields{i},sdata.stage.(fields{i}));
        end
        end
    end

	if isfield(sdata,'annotations')
		fprintf(fd,'annotations:\n');
		saveannotations(fd, sdata.annotations);
	end

	if isfield(sdata,'transform')
		fprintf(fd,'transform: ');
		% Save matrices in row-major order
		A = sdata.transform';
		writevector(fd, A(:));
		fprintf(fd,'\n');
	end
    
    
    fclose(fd);

end

%
%
%
function writefield(fd, sdata, fieldnm, ftype)

    if ~isfield(sdata,fieldnm)
        return;
    end
    
    if strcmp(ftype,'logical')
        fprintf(fd,'%s: %d\n',fieldnm,sdata.(fieldnm));
    elseif strcmp(ftype,'double')
        fprintf(fd,'%s: %.9f\n',fieldnm,sdata.(fieldnm));
    elseif strcmp(ftype,'string')
        fprintf(fd,'%s: "%s"\n',fieldnm,sdata.(fieldnm));
    elseif strcmp(ftype,'int')
        fprintf(fd,'%s: %d\n',fieldnm,sdata.(fieldnm));
    end

end

%
%
%
function writevector(fd, vec)
	fprintf(fd,'[');
	for i = 1 : length(vec)-1
		fprintf(fd,'%.8f, ',vec(i));
	end
	fprintf(fd,'%.8f',vec(end));
	fprintf(fd,']');
end

%
%
%
function saveannotations(fd, annotations)
	for i = 1 : numel(annotations)
		a = annotations(i);
		if strcmp(a.type,'Line')
			fprintf(fd,'  - type: %s\n',a.type);
			fprintf(fd,'    name: %s\n',a.name);
			fprintf(fd,'    id: %d\n',a.id);
			fprintf(fd,'    x1: %.8f\n',a.x1-1);
			fprintf(fd,'    x2: %.8f\n',a.x2-1);
			fprintf(fd,'    y1: %.8f\n',a.y1-1);
			fprintf(fd,'    y2: %.8f\n',a.y2-1);
        elseif strcmp(a.type,'Circle')
			fprintf(fd,'  - type: %s\n',a.type);
			fprintf(fd,'    name: %s\n',a.name);
			fprintf(fd,'    id: %d\n',a.id);
			fprintf(fd,'    x: %.8f\n',a.x-1);
			fprintf(fd,'    y: %.8f\n',a.y-1);
			fprintf(fd,'    r: %.8f\n',a.r);
        elseif strcmp(a.type,'Rectangle')
			fprintf(fd,'  - type: %s\n',a.type);
			fprintf(fd,'    name: %s\n',a.name);
			fprintf(fd,'    id: %d\n',a.id);
			fprintf(fd,'    x: %.8f\n',a.x-1);
			fprintf(fd,'    y: %.8f\n',a.y-1);
			fprintf(fd,'    w: %.8f\n',a.w);
            fprintf(fd,'    h: %.8f\n',a.h);
        elseif strcmp(a.type,'Point')
			fprintf(fd,'  - type: %s\n',a.type);
			fprintf(fd,'    name: %s\n',a.name);
			fprintf(fd,'    id: %d\n',a.id);
			fprintf(fd,'    x: %.8f\n',a.x-1);
			fprintf(fd,'    y: %.8f\n',a.y-1);
        else
			warning('unrecognized annotation type: %s',a.type);
		end
	end
end

