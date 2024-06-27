function d = storm_stats(vmax,mslp,rmw,sst,shear,rad,azi,azi_shr);
addpath('/earl/s0/jdc6324/PlotUtil')
% FUNCTION storm_stats: Written by Jake Carstens, current version 06/26/2024

% PURPOSE: Plot basic information about TCs that dropsondes are launched into, specific to individual planes.
%          Generally presents histograms of TC intensity, environmental shear, dropsonde distance from the TC, etc.

% INPUTS:
% 1. vmax     - TC maximum wind speed (intervals of 5 kt) nearest the time of the dropsonde launch. 1-D array.
% 2. mslp     - TC minimum pressure (hPa) nearest the time of the dropsonde launch. 1-D array.
% 3. rmw      - Radius of maximum wind (km), derived either from concurrent SFMR data included in TC-DROPS (ideal),
%               or taken from the nearest best track fix value in the Extended Best Track dataset (Demuth et al. 2006).
%               1-D array sorted according to the sonde number (first dimension in mse/rad matrices).
% 4. sst      - Near-TC SST (deg C) from NASA GHRSST nearest the time of the dropsonde launch. 1-D array.
% 5. shear    - Deep-layer wind shear magnitude (kt) from SHIPS nearest the time of the dropsonde launch. 1-D array.
% 6. rad     - Radius of sonde from TC center at each level along its descent (km, 2-D matrix).
% 7. azi     - Azimuth of sonde (deg clockwise from N) at each level along its descent (2-D matrix).
% 8. azi_shr - Shear-rotated azimuth of sonde (deg clockwise from downshear) at each level along its descent (2-D matrix).

% OUTPUTS: Histograms of dropsonde sampling based on TC intensity, SST, shear, and wind radii, as well as dropsonde radius
%          and azimuth relative to the TC center.

tic % You'll see a "toc" at the bottom. This is just a cool utility that tracks how long it takes to run something!

% ----------- PLOT THE DISTRIBUTIONS FOR THE G-IV AS HISTOGRAMS ---------- %

cd /earl/s0/jdc6324/TCDROPS/REPOSITORY/StormStats   % Change this directory to whatever you're trying to store your plots in!
set(groot,'DefaultFigureColor','white')

% To simplify plotting, I use the "histogram" function. However, I maintain control of the binning using the arrays at the top of each
% block of plotting code (i.e. vmax_edges). You are welcome to experiment with different
% strategies at your leisure - just make sure to adjust the x-axis accordingly!

vmax_edges=[2.5:5:182.5];   % Since VMAX is already in 5 knot increments, doing a 5-kt increment for the histogram makes the most sense.
h=histogram(vmax,vmax_edges,'FaceColor','k');   % Color the bars according to "cmap" defined above.
set(gca,'FontSize',14)
xlabel('TC Maximum Wind Speed (knots)')
ylabel('Number of Sondes')
xlim([0 185])
set(gca,'XTick',[0:20:180])   % Again, if you change your binning scheme (vmax_edges), change these to fit with it!
grid on
str=strcat("Maximum Wind Speed - G-IV, NATL, N=",num2str(length(vmax)));  % Plots cumulative number of sondes in title as well.
title(str)
frameid=sprintf('Histogram_VMAX.png');
set(gcf,'inverthardcopy', 'off');
print(gcf,'-dpng',frameid);
clf

% Moving on to PMIN, which is in increments of 1 hPa according to best track data. The same procedure is generally followed from here.
pmin_edges=[875:3:1016];
h=histogram(mslp,pmin_edges,'FaceColor','k');
set(gca,'FontSize',14)
xlabel('TC Minimum Pressure (hPa)')
ylabel('Number of Sondes')
xlim([875 1015])
set(gca,'XTick',[875:20:1015])
grid on
str=strcat("Minimum Pressure - G-IV, NATL, N=",num2str(length(vmax)));
title(str)
frameid=sprintf('Histogram_PMIN.png');
set(gcf,'inverthardcopy', 'off');
print(gcf,'-dpng',frameid);
clf

% SST is next - There are some outliers, but we're mostly interested in the more subtropical/tropical SST values anyways.
% Similar considerations can be made for other variables like wind radii (example: a huge RMW is a sign the storm might be nearly extratropical).
sst_edges=[20.05:0.1:31.95];
h=histogram(sst,sst_edges,'FaceColor','k');
set(gca,'FontSize',14)
xlabel('Sea Surface Temperature (C)')
ylabel('Number of Sondes')
xlim([20 32])
set(gca,'XTick',[20:2:32])
grid on
str=strcat("Near-TC SST - G-IV, NATL, N=",num2str(length(vmax)));
title(str)
frameid=sprintf('Histogram_SST.png');
set(gcf,'inverthardcopy', 'off');
print(gcf,'-dpng',frameid);
clf

% Storm-relative azimuth here, followed by shear-relative azimuth. Here, we have hard bounds of 0-360 degrees.
% The histogram function will include something on the left edge of the bin.
% In other words, "10" would fall into the second bin, instead of the first, as I've written below.
azi_edges=[0:10:360];
h=histogram(azi(:,100),azi_edges,'FaceColor','k');
set(gca,'FontSize',14)
xlabel('Azimuth (Degrees Clockwise from North)')
ylabel('Number of Sondes')
xlim([0 360])
set(gca,'XTick',[0:45:360])
grid on
str=strcat("Storm-Relative Azimuth - G-IV, NATL, N=",num2str(length(vmax)));
title(str)
frameid=sprintf('Histogram_AZI.png');
set(gcf,'inverthardcopy', 'off');
print(gcf,'-dpng',frameid);
clf

azi_shr_edges=[0:10:360];
h=histogram(azi_shr(:,100),azi_shr_edges,'FaceColor','k');
set(gca,'FontSize',14)
xlabel('Azimuth (Degrees Clockwise from Downshear)')
ylabel('Number of Sondes')
xlim([0 360])
set(gca,'XTick',[0:45:360])
grid on
str=strcat("Shear-Relative Azimuth - G-IV, NATL, N=",num2str(length(vmax)));
title(str)
frameid=sprintf('Histogram_AZISHR.png');
set(gcf,'inverthardcopy', 'off');
print(gcf,'-dpng',frameid);
clf

% The next 5 sets of plots: Radius from center, RMW, R34, R50, and R64.
% Recall that I take the mean R34/50/64 across all 4 quadrants. This is reflected in the x-axis label.
rad_edges=[0:20:2000];
h=histogram(rad(:,100),rad_edges,'FaceColor','k');
set(gca,'FontSize',14)
xlabel('Distance from TC Center (km)')
ylabel('Number of Sondes')
xlim([0 2000])
set(gca,'XTick',[0:250:2000])
grid on
str=strcat("Dropsonde Radius - G-IV, NATL, N=",num2str(length(vmax)));
title(str)
frameid=sprintf('Histogram_RAD.png');
set(gcf,'inverthardcopy', 'off');
print(gcf,'-dpng',frameid);
clf

rmw_edges=[0:10:300];
h=histogram(rmw,rmw_edges,'FaceColor','k');
set(gca,'FontSize',14)
xlabel('Radius of Maximum Winds (km)')
ylabel('Number of Sondes')
xlim([0 300])
set(gca,'XTick',[0:30:300])
grid on
str=strcat("Radius of Maximum Winds - G-IV, NATL, N=",num2str(length(vmax)));
title(str)
frameid=sprintf('Histogram_RMW.png');
set(gcf,'inverthardcopy', 'off');
print(gcf,'-dpng',frameid);
clf

% Wrap up with vertical wind shear magnitude! We've somewhat accounted for direction with the shear-relative azimuth.
shear_edges=[0:1:50];
h=histogram(shear,shear_edges,'FaceColor','k');
set(gca,'FontSize',14)
xlabel('Deep-Layer Vertical Wind Shear (kt)')
ylabel('Number of Sondes')
xlim([0 50])
set(gca,'XTick',[0:5:50])
grid on
str=strcat("TC Wind Shear - G-IV, NATL, N=",num2str(length(vmax)));
title(str)
frameid=sprintf('Histogram_SHEAR.png');
set(gcf,'inverthardcopy', 'off');
print(gcf,'-dpng',frameid);
clf

cd /earl/s0/jdc6324/TCDROPS/REPOSITORY/Functions  % Change this to whatever directory you're running your functions out of!
toc  % Spits out something like "Elapsed time is 29.438 seconds".
disp('Finished plotting storm statistics')
return;
