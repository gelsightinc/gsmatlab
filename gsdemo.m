%GSDEMO Simple demo script showing how to plot a profile from a GelSight scan.
%
[parentdr,filenm] = fileparts(mfilename('fullpath'));

spath = fullfile(parentdr,'demo','groove','scan.yaml');
if ~exist(spath,'file')
    error('cannot find scan file for demo %s',spath);
end

hpath = fullfile(parentdr,'demo','groove','heightmap.tmd');
if ~exist(hpath,'file')
    error('cannot find TMD file %s',hpath);
end

sdata = readscan(spath);
lns = getshape(sdata.annotations, [], 'Line1');
if isempty(lns)
    error('cannot find line in scan file');
end
ln = lns{1};

[hm,dt] = readtmd(hpath);
mmpp = dt.mmpp;

% Load first image
im = im2double(imread(sdata.images(1).path));

% Get the profile from the heightmap
p = getprofile(hm, ln, mmpp);

% Level the profile using the spcified regions as the reference
[lp,A] = levelprofile(p, {[0.3 0.9], [3.1 3.6]});

% Dimensions in mm
xd = [1 size(hm,2)]*mmpp;
yd = [1 size(hm,1)]*mmpp;

figure(1)
clf
subplot(131)
imagesc(im,'XData',xd,'YData',yd);
colorbar
axis image 
title('image 1');
xlabel('X (mm)');
ylabel('Y (mm)');
hold on
plotshape('line',ln*mmpp); % Plot units are in mm, multiply by resolution

subplot(132)
imagesc(hm,'XData',xd,'YData',yd);
colorbar
axis image 
title('height (Z)');
xlabel('X (mm)');
ylabel('Y (mm)');
hold on
plotshape('line',ln*mmpp);

zmicrons = lp(2,:)*1000;
subplot(133)
plot(lp(1,:),zmicrons,'b','LineWidth',2);
xlabel('T (mm)');
ylabel(['Z (\mu' 'm)']);
title('Profile along line')
set(gca,'PlotBoxAspectRatio',[3 2 1]);
axis([lp(1,1) lp(1,end) min(zmicrons)-50 max(zmicrons)+50]);
grid on

