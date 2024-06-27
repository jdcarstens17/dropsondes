function htmp = heatmaps(rad,rmw,azi,azi_shr,vmax,vmax_24,sst,shear);
addpath('/earl/s0/jdc6324/PlotUtil')
% FUNCTION heatmaps: Written by Jake Carstens, current version 06/26/2024

% PURPOSE: Plot heatmaps of dropsonde launch points in radius/azimuth space relative to the TC center.
%          Uses a similar composite scheme to composites.m for MSE evaluation, while plotting in radial
%          coordinates of both raw and normalized radius, and azimuth coordinates in storm-relative,
%          motion-relative, and shear-relative space.

% INPUTS:
% 1. rad      - Radius of sonde from TC center at each level along its descent (km). 2-D matrix.
% 2. rmw      - Radius of maximum wind (km), derived either from concurrent SFMR data included in TC-DROPS (ideal),
%               or taken from the nearest best track fix value in the Extended Best Track dataset (Demuth et al. 2006).
%               1-D array sorted according to the sonde number (first dimension in mse/rad matrices).
% 3. azi      - Storm-relative azimuth of dropsonde at each level along its descent (deg clockwise from N). 2-D matrix.
% 4. azi_shr  - Same as azi, but rotated relative to the deep-layer vertical wind shear from SHIPS. 2-D matrix.
% 5. vmax     - TC maximum wind speed (intervals of 5 kt) nearest the time of the dropsonde launch. 1-D array.
% 6. vmax_24  - Intensity change (kt) in the 24 hours following the nearest best track time. 1-D array.
% 7. sst      - Near-TC SST (deg C) from NASA GHRSST nearest the time of the dropsonde launch. 1-D array.
% 8. shear   - Deep-layer wind shear magnitude (kt) from SHIPS nearest the time of the dropsonde launch. 1-D array.

% OUTPUTS: Spatial heatmaps of dropsonde launch positions in radius/azimuth space, composited according to factors such
%          as TC intensity/intensification rate, basin, plane, and month, among others. Options are included to plot
%          using raw and RMW-normalized radii, as well as azimuths relative to the storm, its motion, or the shear.

tic % You'll see a "toc" at the bottom. This is just a cool utility that tracks how long it takes to run something!

% ----------- YOU SHOULD ONLY NEED TO CHANGE THINGS BEFORE THE COUNT MATRICES ARE INITIALIZED BELOW ---------- %
% The first line will set up a list of compositing variables that we will loop through, developing binning schemes
% accordingly below. You may choose to add others (i.e. MSLP, latitude, year) at your leisure.
condition=["VMAX" "RATE" "SST" "SHEAR"]; % Hopefully these are intuitive enough.
for c=1:length(condition)
  rad_bins=[0:20:1000]; rmw_bins=[0:0.4:20];  % Set your radius and azimuth bins here! I'll calculate the normalized radius later.
  azi_storm_bins=[0:6:360]; azi_shear_bins=[0:6:360]; azi_motion_bins=[0:6:360];
                                              % Intent is to plot raw/normalized radius, and storm/motion/shear-relative azimuth.
% SET UP OUR VARIOUS CONDITIONS, AND CORRESPONDING PLOT TITLES AND FILE NAMES, HERE
  if (condition(c) == "VMAX")
    cmpvar=vmax;  % The variable we use for compositing (i.e. here, we composite by TC intensity).
    cmpbins=[10 34 64 83 96 113 137 200];  % In knots, so these are boundaries between Saffir-Simpson scale categories.
    plotname=["TD","TS","C1","C2","C3","C4","C5"];  % These will eventually go into the file names, along with "VMAX", for easy identification.
    plottitle=["Tropical Depressions","Tropical Storms","Cat. 1 Hurricanes","Cat. 2 Hurricanes","Cat. 3 Hurricanes","Cat. 4 Hurricanes","Cat. 5 Hurricanes","ALL"];
    % The above line will be what goes into the plot titles for the various bins.
  elseif (condition(c) == "RATE")
    cmpvar=vmax_24;  % For now, I use the 24-hour intensification rate, knowing that a 30 knot increase indicates rapid intensification.
    cmpbins=[-100 -29 -6 6 29 100];
    plotname=["RW","SW","SS","SI","RI"];  % I define steady state as TCs varying by 5 knots or less in 24 hours.
    plottitle=["Rapidly Weakening","Weakening","Steady-State","Intensifying","Rapidly Intensifying","ALL"];
  elseif (condition(c) == "SST")
    cmpvar=sst;
    cmpbins=25:1:31;  % Hopefully you get the idea by now.
    plotname=["25C","26C","27C","28C","29C","30C"];
    plottitle=["25-26^oC SST","26-27^oC SST","27-28^oC SST","28-29^oC SST","29-30^oC SST","30-31^oC SST","ALL"];
  elseif (condition(c) == "SHEAR")
    cmpvar=shear;
    cmpbins=[0:10:30 50];   % Shear is in knots. Generally, 10-20 knots is considered moderate shear, but these thresholds are somewhat arbitrary.
    plotname=["LShr","MShr","HShr","VShr"];
    plottitle=["Low Shear","Moderate Shear","High Shear","Very High Shear","ALL"];
  end

  count_rad_storm=zeros(length(cmpbins),length(rad_bins),length(azi_storm_bins));  % Notice how each dimension would include both of the "bounds"?
  count_rmw_storm=zeros(length(cmpbins),length(rmw_bins),length(azi_storm_bins));  % For rad/azi, this is because the pcolor function for plotting
  count_rad_shear=zeros(length(cmpbins),length(rad_bins),length(azi_shear_bins));  % introduces an offset that I can correct for with this.
  count_rmw_shear=zeros(length(cmpbins),length(rmw_bins),length(azi_shear_bins));   % For cmpbins, this is because I'll have the last bin hold all

  rad_giv=rad(:,10:end); azi_giv=azi(:,10:end); azi_shr_giv=azi_shr(:,10:end);
  for n=1:length(vmax)
    if (all(isnan(rad_giv(n,:)) == 1) || all(isnan(azi_giv(n,:)) == 1) || all(isnan(azi_shr_giv(n,:)) == 1))
      continue;   % Skip the sonde of all the radii/azimuths are NaN (rare, mostly early in dataset)
    end
    rad_init=rad_giv(n,find(rad_giv(n,:)>=0,1,'last'));   % First instance of non-NaN radius is used as the "launch" point.
    rmw_init=rad_init./rmw(n);  % Normalize by the RMW here!
    azi_storm_init=azi_giv(n,find(azi_giv(n,:)>=0,1,'last'));  % Do same approach to find launch azimuths.
    azi_shear_init=azi_shr_giv(n,find(azi_shr_giv(n,:)>=0,1,'last'));

% ------- THIS IS THE PART WHERE WE'LL ASSIGN RADIUS/AZIMUTH VALUES TO OUR VARIOUS COMPOSITE BINS, AS WELL AS THE FULL DISTRIBUTION ------- %
    for b=1:length(cmpbins)-1
      if (cmpvar(n) >= cmpbins(b) && cmpvar(n) < cmpbins(b+1))     % First, check to see if we're in the correct composite bin.
        for r=1:length(rad_bins)-1                                 % You should not have to change this - only the conditions above!
          if (rad_init >= rad_bins(r) && rad_init < rad_bins(r+1)) % First, we'll do things in raw radius space. I'll mark the normalized area below.
            for z=1:length(azi_storm_bins)-1                       % Now check to see if we're in the correct storm-relative azimuth bin.
              if (azi_storm_init >= azi_storm_bins(z) && azi_storm_init < azi_storm_bins(z+1))
                count_rad_storm(b,r,z)=count_rad_storm(b,r,z)+1;   % And if we are, add 1 dropsonde to that rad/azi bin.
                count_rad_storm(end,r,z)=count_rad_storm(end,r,z)+1;  % This is for the full distribution without binning.
              end
            end
            for z=1:length(azi_shear_bins)-1   % Let's do the same thing for the shear-relative azimuth space (still raw radius).
              if (azi_shear_init >= azi_shear_bins(z) && azi_shear_init < azi_shear_bins(z+1))
                count_rad_shear(b,r,z)=count_rad_shear(b,r,z)+1;   % You'll get the idea from here.
                count_rad_shear(end,r,z)=count_rad_shear(end,r,z)+1;
              end
            end
          end
        end
        for r=1:length(rmw_bins)-1   % Now, we'll do the same thing for the RMW-normalized version of the radius. Again, set your bounds near the start!
          if (rmw_init >= rmw_bins(r) && rmw_init < rmw_bins(r+1))
            for z=1:length(azi_storm_bins)-1
              if (azi_storm_init >= azi_storm_bins(z) && azi_storm_init < azi_storm_bins(z+1))
                count_rmw_storm(b,r,z)=count_rmw_storm(b,r,z)+1;
                count_rmw_storm(end,r,z)=count_rmw_storm(end,r,z)+1;
              end
            end
            for z=1:length(azi_shear_bins)-1
              if (azi_shear_init >= azi_shear_bins(z) && azi_shear_init < azi_shear_bins(z+1))
                count_rmw_shear(b,r,z)=count_rmw_shear(b,r,z)+1;
                count_rmw_shear(end,r,z)=count_rmw_shear(end,r,z)+1;
              end
            end
          end
        end
      end
    end
  end

% ---- PLOTTING SECTION USING THE polarpcolor.m FUNCTION, DOWNLOADED FROM THE MATLAB FILE EXCHANGE ---- %
% This will be loaded into the same directory that I save the plots to - make sure you copy this over to wherever you want your plots too!

  cd /earl/s0/jdc6324/TCDROPS/REPOSITORY/Heatmaps   % Change this to wherever you want to leave these plots.
  set(groot,'DefaultFigureColor','white')
  rticks={' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' '}; % This will prevent radius numbers from being plotted (looks messy)

% ENTER A LOOP TO PLOT ALL OF THE RAW/NORMALIZED AND STORM/SHEAR/MOTION-RELATIVE HEATMAPS BIN BY BIN
  for b=1:length(cmpbins)   % Plot each composite bin separately.
    heatmap_plot=reshape(count_rad_storm(b,:,:),length(rad_bins),length(azi_storm_bins)); % Matlab wants a 2D matrix or else it gets grumpy.
    maxval=max(max(max(heatmap_plot)));   % This will set the upper boundary for our colorbar.
    [h,l]=polarpcolor(rad_bins,azi_storm_bins,heatmap_plot.','Nspokes',13,'Ncircles',11,'Rticklabel',rticks);
% Above, 'Nspokes' is the azimuth lines in 30-deg increments, 'Ncircles' is radius circles at 100 km increments.
    colormap(turbo(maxval+1));  % Feel free to experiment with different colorbars, but keep the number of colors (maxval+1) the same!
    ylabel('Number of Dropsondes')
    ytickinterval=floor(maxval./20)+1;   % Plot up to 20 ticks on the colorbar, making sure that we don't have numbers overlapping (aesthetic).
    set(l,'YTick',[0:ytickinterval:maxval])
    limits=[-0.5 maxval+0.5];  % Introducing a 0.5 offset will center each color on the actual count value.
    caxis(limits)
    set(gca,'FontSize',14)
    str=strcat("Storm-Relative Heatmap - ",plottitle(b));   % Make sure composite bin name is being included in the title!
    title(str)
    if (b == length(cmpbins))
      frameid=sprintf('Heatmap_STORM_RAD_ALL.png');   % Recall that the last cmpbin is actually the full distribution.
    else
      frameid=sprintf('Heatmap_STORM_RAD_%02s_%02s.png',condition(c),plotname(b)); % Otherwise, make sure distinct bins are represented in plot titles.
    end
    set(gcf,'inverthardcopy', 'off');
    print(gcf,'-dpng',frameid);
    clf

% EVERYTHING BELOW WILL JUST BE THE SAME THING, BUT FOR THE DIFFERENT RADIUS AND AZIMUTH SCHEMES. I WILL REFRAIN FROM COMMENTING UNTIL AFTER THESE ARE PLOTTED.
    heatmap_plot=reshape(count_rad_shear(b,:,:),length(rad_bins),length(azi_shear_bins));
    maxval=max(max(max(heatmap_plot)));
    [h,l]=polarpcolor(rad_bins,azi_shear_bins,heatmap_plot.','Nspokes',13,'Ncircles',11,'Rticklabel',rticks);
    colormap(turbo(maxval+1));
    ylabel('Number of Dropsondes')
    ytickinterval=floor(maxval./20)+1;
    set(l,'YTick',[0:ytickinterval:maxval])
    limits=[-0.5 maxval+0.5];
    caxis(limits)
    set(gca,'FontSize',14)
    str=strcat("Shear-Relative Heatmap - ",plottitle(b));
    title(str)
    if (b == length(cmpbins))
      frameid=sprintf('Heatmap_SHEAR_RAD_ALL.png');
    else
      frameid=sprintf('Heatmap_SHEAR_RAD_%02s_%02s.png',condition(c),plotname(b));
    end
    set(gcf,'inverthardcopy', 'off');
    print(gcf,'-dpng',frameid);
    clf

    heatmap_plot=reshape(count_rmw_storm(b,:,:),length(rmw_bins),length(azi_storm_bins));
    maxval=max(max(max(heatmap_plot)));
    [h,l]=polarpcolor(rmw_bins,azi_storm_bins,heatmap_plot.','Nspokes',13,'Ncircles',11,'Rticklabel',rticks);
    colormap(turbo(maxval+1));
    ylabel('Number of Dropsondes')
    ytickinterval=floor(maxval./20)+1;
    set(l,'YTick',[0:ytickinterval:maxval])
    limits=[-0.5 maxval+0.5];
    caxis(limits)
    set(gca,'FontSize',14)
    str=strcat("Storm-Relative Heatmap - ",plottitle(b));
    title(str)
    if (b == length(cmpbins))
      frameid=sprintf('Heatmap_STORM_RMW_ALL.png');
    else
      frameid=sprintf('Heatmap_STORM_RMW_%02s_%02s.png',condition(c),plotname(b));
    end
    set(gcf,'inverthardcopy', 'off');
    print(gcf,'-dpng',frameid);
    clf

    heatmap_plot=reshape(count_rmw_shear(b,:,:),length(rmw_bins),length(azi_shear_bins));
    maxval=max(max(max(heatmap_plot)));
    [h,l]=polarpcolor(rmw_bins,azi_shear_bins,heatmap_plot.','Nspokes',13,'Ncircles',11,'Rticklabel',rticks);
    colormap(turbo(maxval+1));
    ylabel('Number of Dropsondes')
    ytickinterval=floor(maxval./20)+1;
    set(l,'YTick',[0:ytickinterval:maxval])
    limits=[-0.5 maxval+0.5];
    caxis(limits)
    set(gca,'FontSize',14)
    str=strcat("Shear-Relative Heatmap - ",plottitle(b));
    title(str)
    if (b == length(cmpbins))
      frameid=sprintf('Heatmap_SHEAR_RMW_ALL.png');
    else
      frameid=sprintf('Heatmap_SHEAR_RMW_%02s_%02s.png',condition(c),plotname(b));
    end
    set(gcf,'inverthardcopy', 'off');
    print(gcf,'-dpng',frameid);
    clf
  end
end
toc % Should spit out "Elapsed time is 47.8623 seconds" or something.
cd /earl/s0/jdc6324/TCDROPS/REPOSITORY/Functions  % Head back to directory where your functions are so you can run more!
disp('Finished plotting heatmaps')
return;
