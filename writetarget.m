function writetarget(tdata, outname)
%WRITETARGET Saves a target struct in YAML format.
%   writetarget(TDATA, FILENAME) saves a target struct TDATA to the file specified 
%   by the string FILENAME.
%   
%   The struct TDATA is assumed to have some of the following fields:
%   
%   type         A string specifying the type of target
%
%   annotations  A struct array of annotations (e.g., shapes).  Pixel 
%                coordinates are converted from origin (1,1) to origin (0,0) 
%                by subtracting 1.
%
%   See also readscan

    if ~isfield(tdata,'type')
        error('input struct must have a type field');
    end

    fd = fopen(outname,'w');
    
    writefield(fd, tdata, 'type', 'plainstring');

    typ = lower(tdata.type);
    if strcmp(typ,'bga')
        savebga(fd, tdata);
    elseif strcmp(typ,'flat')
        ; % Nothing else to do
    elseif strcmp(typ,'groovecircle') || strcmp(typ,'groove')
        savegroove(fd, tdata);
    else
        warning('unrecognized target type %s',tdata.type);
    end

    fclose(fd);
end

%
% Save BGA data
%
function savebga(fd, tdata)
   
    % Update field names
    if isfield(tdata,'calibradius') && ~isfield(tdata,'radius')
        tdata.radius = tdata.calibradius;
    end
    if isfield(tdata,'calibspacing') && ~isfield(tdata,'pitch')
        tdata.pitch = tdata.calibspacing;
    end
    if isfield(tdata,'annotations') && ~isfield(tdata,'shapes')
        tdata.shapes = tdata.annotations;
    end
    fields = {'radius', 'pitch'};

    for i = 1 : numel(fields)
        writefield(fd, tdata, fields{i}, 'double');
    end

    if isfield(tdata,'shapes')
        fprintf(fd,'shapes:\n');
        saveannotations(fd, tdata.shapes);
    end

end

%
% Save Groove and GrooveCircle data
%
function savegroove(fd, tdata)
    fields = {'depth', 'width', 'pad'};
    for i = 1 : numel(fields)
        writefield(fd, tdata, fields{i}, 'double');
    end

    % GrooveCircle fields
    fields = {'distance', 'diameter'};
    for i = 1 : numel(fields)
        if isfield(tdata,fields{i})
            writefield(fd, tdata, fields{i}, 'double');
        end
    end

    if isfield(tdata,'annotations')
        fprintf(fd,'annotations:\n');
        saveannotations(fd, tdata.annotations);
    end

    if isfield(tdata,'line')
        fprintf(fd,'line:\n');
        saveannotations(fd, tdata.line);
    end

    if isfield(tdata,'circles')
        fprintf(fd,'circles:\n')
        saveannotations(fd, tdata.circles);
    end

end


%
%
%
function writefield(fd, tdata, fieldnm, ftype, indent)

    if ~isfield(tdata,fieldnm)
        return;
    end
    if ~exist('indent','var')
        indent = false;
    end
    if indent
        fprintf(fd,'    ');
    end
    
    if strcmp(ftype,'logical')
        fprintf(fd,'%s: %d\n',fieldnm,tdata.(fieldnm));
    elseif strcmp(ftype,'bool')
        tf = 'false';
        if tdata.(fieldnm)
            tf = 'true';
        end
        fprintf(fd,'%s: %s\n',fieldnm,tf);
    elseif strcmp(ftype,'double')
        fprintf(fd,'%s: %.9f\n',fieldnm,tdata.(fieldnm));
    elseif strcmp(ftype,'string')
        fprintf(fd,'%s: "%s"\n',fieldnm,tdata.(fieldnm));
    elseif strcmp(ftype,'plainstring')
        fprintf(fd,'%s: %s\n',fieldnm,tdata.(fieldnm));
    elseif strcmp(ftype,'int')
        fprintf(fd,'%s: %d\n',fieldnm,tdata.(fieldnm));
    end

end


%
%
%
function saveannotations(fd, annotations)
    for i = 1 : numel(annotations)
        a = annotations(i);
        typ = lower(a.type);
        % Shapes with names and IDs are saved as structs
        if isfield(a,'name') && isfield(a,'id')
            if strcmp(typ,'line')
                fprintf(fd,'  - type: %s\n',a.type);
                fprintf(fd,'    name: %s\n',a.name);
                fprintf(fd,'    id: %d\n',a.id);
                fprintf(fd,'    x1: %.8f\n',a.x1-1);
                fprintf(fd,'    x2: %.8f\n',a.x2-1);
                fprintf(fd,'    y1: %.8f\n',a.y1-1);
                fprintf(fd,'    y2: %.8f\n',a.y2-1);
            elseif strcmp(typ,'circle')
                fprintf(fd,'  - type: %s\n',a.type);
                fprintf(fd,'    name: %s\n',a.name);
                fprintf(fd,'    id: %d\n',a.id);
                fprintf(fd,'    x: %.8f\n',a.x-1);
                fprintf(fd,'    y: %.8f\n',a.y-1);
                fprintf(fd,'    r: %.8f\n',a.r);
            elseif strcmp(typ,'gridcircle')
                fprintf(fd,'  - type: %s\n',a.type);
                fprintf(fd,'    name: %s\n',a.name);
                fprintf(fd,'    id: %d\n',a.id);
                fprintf(fd,'    x: %.8f\n',a.x-1);
                fprintf(fd,'    y: %.8f\n',a.y-1);
                fprintf(fd,'    r: %.8f\n',a.r);
                fprintf(fd,'   gx: %.d\n',a.gx  );
                fprintf(fd,'   gy: %.d\n',a.gy  );
            elseif strcmp(typ,'rectangle')
                fprintf(fd,'  - type: %s\n',a.type);
                fprintf(fd,'    name: %s\n',a.name);
                fprintf(fd,'    id: %d\n',a.id);
                fprintf(fd,'    x: %.8f\n',a.x-1);
                fprintf(fd,'    y: %.8f\n',a.y-1);
                fprintf(fd,'    w: %.8f\n',a.w);
                fprintf(fd,'    h: %.8f\n',a.h);
            elseif strcmp(typ,'point')
                fprintf(fd,'  - type: %s\n',a.type);
                fprintf(fd,'    name: %s\n',a.name);
                fprintf(fd,'    id: %d\n',a.id);
                fprintf(fd,'    x: %.8f\n',a.x-1);
                fprintf(fd,'    y: %.8f\n',a.y-1);
            else
                warning('unrecognized annotation type: %s',a.type);
            end
        else
        % Shapes without names and IDs are saved as tuples
            if strcmp(typ,'circle') || strcmp(typ,'gridcircle')
                fprintf(fd,'  - (%.8f, %.8f, %.8f)\n',a.x-1,a.y-1,a.r);
            elseif strcmp(typ,'line')
                fprintf(fd,'  - (%.8f, %.8f, %.8f, %.8f)\n',...
                    a.x1-1,a.y1-1,a.x2-1,a.y2-1);
            else
                warning('unrecognized annotation type: %s',a.type);
            end

        end
    end
end

