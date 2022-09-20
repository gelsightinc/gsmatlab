function s = getshape(annotations, shape, name)
%GETSHAPE Get a shape from an annotations list.
%   S = getshape(ANNOTATIONS, SHAPE) returns a cell array of shapes of type 
%   SHAPE or an empty array if no shapes of type SHAPE exist in the
%   annotation list ANNOTATIONS. 
%
%   S = getshape(ANNOTATIONS, SHAPE, NAME) returns a shape with name specified
%   by the string NAME. When NAME is specified, SHAPE can be empty.
%
%   See also readscan

    if ~isstruct(annotations)
        error('annotations must be a struct array');
    end

    if nargin == 2
        name = [];
    end

    if isempty(shape) && isempty(name)
        error('the shape type or name must be specified');
    end

    s = {};
    sx = 1;

    stype = lower(shape);
    sname = lower(name);

    for i = 1 : numel(annotations)
        a = annotations(i);
        temp = [];
        if isempty(stype) && strcmp(lower(a.name),sname)
            temp = unpackshape(a);
        elseif isempty(sname) && strcmp(stype,lower(a.type))
            temp = unpackshape(a);
        elseif strcmp(stype,lower(a.type)) && strcmp(sname,lower(a.name))
            temp = unpackshape(a);
        end
        if ~isempty(temp)
            s{sx} = temp;
            sx = sx + 1;
        end
    end


end

%
%
%
function c = unpackshape(a)

    c = [];
    if strcmp(a.type,'Circle')
        c = [a.x a.y a.r];
    elseif strcmp(a.type,'Line')
        c = [a.x1  a.y1  a.x2  a.y2];
    elseif strcmp(a.type,'Point')
        c = [a.x a.y];
    elseif strcmp(a.type,'Rectangle')
        c = [a.x a.y a.w a.h];
    elseif strcmp(a.type,'PolyLine')
        c = a.points;
    end

end
