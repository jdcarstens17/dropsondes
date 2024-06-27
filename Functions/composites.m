function cmp = composites(mse,pressure,rad,rmw,vmax,vmax_24,sst,shear);
addpath('/earl/s0/jdc6324/PlotUtil')
% FUNCTION composites: Written by Jake Carstens, current version 06/26/2024

% PURPOSE: Plot radius-pressure profiles of moist static energy in a composite framework, using a series of conditions
%          defined within the function. These are done using both raw and normalized radius coordinates, similar to
%          plot_mseprofiles.m. You are welcome to introduce new compositing conditions, as this serves as a starter pack.

% INPUTS:
% 1. mse      - Moist static energy (J/kg) recorded by dropsonde at each pressure level. 2-D matrix (sonde,level).
% 2. pressure - Pressure levels in 5 hPa increments from 50 --> 1010 hPa. 1-D array (level).
% 3. rad      - Radius of sonde from TC center at each level along its descent (km, 2-D matrix).
% 4. rmw      - Radius of maximum wind (km), derived either from concurrent SFMR data included in TC-DROPS (ideal),
%               or taken from the nearest best track fix value in the Extended Best Track dataset (Demuth et al. 2006).
%               1-D array sorted according to the sonde number (first dimension in mse/rad matrices).
% 5. vmax     - TC maximum wind speed (intervals of 5 kt) nearest the time of the dropsonde launch. 1-D array.
% 6. vmax_24  - Intensity change (kt) in the 24 hours following the nearest best track time. 1-D array.
% 7. sst      - Near-TC SST (deg C) from NASA GHRSST nearest the time of the dropsonde launch. 1-D array.
% 8. shear    - Deep-layer wind shear magnitude (kt) from SHIPS nearest the time of the dropsonde launch. 1-D array.

% OUTPUTS: Radius-pressure composite profiles of MSE (J/kg), organized by factors such as TC intensity, intensification
%          rate, basin, and aircraft, among others. Options using both raw and RMW-normalized radius are included.

tic % You'll see a "toc" at the bottom. This is just a cool utility that tracks how long it takes to run something!

% ----------- YOU SHOULD ONLY NEED TO CHANGE THINGS BEFORE THE MSE MATRICES ARE INITIALIZED BELOW ---------- %
% The first line will set up a list of compositing variables that we will loop through, developing binning schemes
% accordingly below. You may choose to add others (i.e. MSLP, latitude, year) at your leisure.
condition=["VMAX" "RATE" "SST" "SHEAR"]; % Hopefully these are intuitive enough.
for c=1:length(condition)

  radbins=[0:10:1000]; rmwbins=[0:0.2:20]; rad_norm=[];  % Set your radius bins here! I've created a blank matrix to hold the normalized radii for later.

% SET UP OUR VARIOUS CONDITIONS, AND CORRESPONDING PLOT TITLES AND FILE NAMES, HERE
  if (condition(c) == "VMAX")
    cmpvar=vmax;  % The variable we use for compositing (i.e. here, we composite by TC intensity).
    cmpbins=[10 34 64 83 96 113 137 200];  % In knots, so these are boundaries between Saffir-Simpson scale categories.
    plotname=["TD","TS","C1","C2","C3","C4","C5"];  % These will eventually go into the file names, along with "VMAX", for easy identification.
    plottitle=["Tropical Depressions","Tropical Storms","Cat. 1 Hurricanes","Cat. 2 Hurricanes","Cat. 3 Hurricanes","Cat. 4 Hurricanes","Cat. 5 Hurricanes"];
    % The above line will be what goes into the plot titles for the various bins.
  elseif (condition(c) == "RATE")
    cmpvar=vmax_24;  % For now, I use the 24-hour intensification rate, knowing that a 30 knot increase indicates rapid intensification.
    cmpbins=[-100 -29 -6 6 29 100];
    plotname=["RW","SW","SS","SI","RI"];  % I define steady state as TCs varying by 5 knots or less in 24 hours.
    plottitle=["Rapidly Weakening","Weakening","Steady-State","Intensifying","Rapidly Intensifying"];
  elseif (condition(c) == "SST")
    cmpvar=sst;
    cmpbins=25:1:31;  % Hopefully you get the idea by now.
    plotname=["25C","26C","27C","28C","29C","30C"];
    plottitle=["25-26^oC SST","26-27^oC SST","27-28^oC SST","28-29^oC SST","29-30^oC SST","30-31^oC SST"];
  elseif (condition(c) == "SHEAR")
    cmpvar=shear;
    cmpbins=[0:10:30 50];   % Shear is in knots. Generally, 10-20 knots is considered moderate shear, but these thresholds are somewhat arbitrary.
    plotname=["LShr","MShr","HShr","VShr"];
    plottitle=["Low Shear","Moderate Shear","High Shear","Very High Shear"];
  end

% Initialize MSE matrices for each of these composite bins, for both raw and normalized radii.
% We'll accumulate across the full dataset, so "count" will help us determine the average for a given r/p bin
% since multiple sondes may fall into one of these bins.

  mse_rad_all=zeros(length(radbins),length(pressure));
  mse_rmw_all=zeros(length(rmwbins),length(pressure));
  count_rad_all=zeros(length(radbins),length(pressure));
  count_rmw_all=zeros(length(rmwbins),length(pressure));
  mse_rad=zeros(length(cmpbins)-1,length(radbins),length(pressure));
  mse_rmw=zeros(length(cmpbins)-1,length(radbins),length(pressure));
  count_rad=zeros(length(cmpbins)-1,length(rmwbins),length(pressure));
  count_rmw=zeros(length(cmpbins)-1,length(rmwbins),length(pressure));

  for n=1:length(vmax)    % Loop through all of the sondes!
    for z=1:length(pressure)
      if (isnan(mse(n,z)) == 1 || isnan(rad(n,z)) == 1) % Skip the blank sondes or pressure levels
        continue;
      end
      rad_norm(n,z)=rad(n,z)./rmw(n);  % Normalizing the radius here!
      for r=1:length(radbins)-1        % Seek out the proper radius bin to place this particular sonde!
        if (rad(n,z) >= radbins(r) && rad(n,z) < radbins(r+1))
          mse_rad_all(r,z)=mse_rad_all(r,z)+mse(n,z);
          count_rad_all(r,z)=count_rad_all(r,z)+1;
          for b=1:length(cmpbins)-1
            if (cmpvar(n) >= cmpbins(b) && cmpvar(n) < cmpbins(b+1))
              mse_rad(b,r,z)=mse_rad(b,r,z)+mse(n,z);
              count_rad(b,r,z)=count_rad(b,r,z)+1;   % If we find the right bin, accumulate that sonde data.
              break;
            end
          end
        end
      end
      for r=1:length(rmwbins)-1
        if (rad_norm(n,z) >= rmwbins(r) && rad_norm(n,z) < rmwbins(r+1)) % Do the same for the normalized radius version.
          mse_rmw_all(r,z)=mse_rmw_all(r,z)+mse(n,z);
          count_rmw_all(r,z)=count_rmw_all(r,z)+1;
          for b=1:length(cmpbins)-1
            if (cmpvar(n) >= cmpbins(b) && cmpvar(n) < cmpbins(b+1))
              mse_rmw(b,r,z)=mse_rmw(b,r,z)+mse(n,z);
              count_rmw(b,r,z)=count_rmw(b,r,z)+1;   % If we find the right bin, accumulate that sonde data.
              break;
            end
          end
        end
      end
    end
  end
  count_rad(count_rad==0)=NaN; count_rmw(count_rmw==0)=NaN;
  mse_rad=mse_rad./count_rad; mse_rmw=mse_rmw./count_rmw;   % NaN out the blank bins, and get the average MSE value for each r/p bin.
  count_rad_all(count_rad_all==0)=NaN; count_rmw_all(count_rmw_all==0)=NaN;
  mse_rad_all=mse_rad_all./count_rad_all; mse_rmw_all=mse_rmw_all./count_rmw_all;

  cd /earl/s0/jdc6324/TCDROPS/REPOSITORY/Composites   % Change this to wherever you want to leave these plots.
  set(groot,'DefaultFigureColor','white')
  set(groot,'DefaultFigureColormap',turbo)

  h=pcolor(radbins,pressure,mse_rad_all.');
  colormap(turbo)                                     % Feel free to experiment with different color bars.
  set(h,'EdgeColor','none');                          % Prevents pcolor from drawing black boxes around every pixel.
  cbh=colorbar;
  set(cbh,'YTick',[310000:10000:360000])
  brighten(-0.5)
  limits=[310000 360000];
  caxis(limits)
  xlim([min(radbins) max(radbins)])
  ylim([190 1010])     % May want to change this and the YTicks - there usually isn't much above 190 hPa though.
  set(gca,'XTick',(min(radbins):max(radbins)/10:max(radbins)))  % Similarly to above, this just makes sure we're plotting 10 tick marks.
  set(gca,'YTick',[200:100:1000])
  set(gca,'FontSize',14)
  set(gca,'YDir','reverse')   % These two lines make sure pressure is decreasing with height, and varying logarithmically as in reality.
  set(gca,'YScale','log')
  grid on
  ylabel('Pressure (hPa)')
  xlabel('Radius (km)')
  title("Composite Moist Static Energy (J/kg)")
  frameid=sprintf('MSE_RAD_ALL.png');
  set(gcf,'inverthardcopy', 'off');
  print(gcf,'-dpng',frameid);
  clf

% THEN JUST DO THE EXACT SAME THING FOR THE NORMALIZED RADIUS VERSION! MAKE SIMILAR TWEAKS AS YOU SEE FIT TO THE AESTHETICS.

  h=pcolor(rmwbins,pressure,mse_rmw_all.');
  colormap(turbo)
  set(h,'EdgeColor','none');
  cbh=colorbar;
  set(cbh,'YTick',[310000:10000:360000])
  brighten(-0.5)
  limits=[310000 360000];
  caxis(limits)
  xlim([min(rmwbins) max(rmwbins)])
  ylim([190 1010])
  set(gca,'XTick',(min(rmwbins):max(rmwbins)/10:max(rmwbins)))
  set(gca,'YTick',[200:100:1000])
  set(gca,'FontSize',14)
  set(gca,'YDir','reverse')
  set(gca,'YScale','log')
  grid on
  ylabel('Pressure (hPa)')
  xlabel('Normalized Radius (R/RMW)')
  title("Composite Moist Static Energy (J/kg)")
  frameid=sprintf('MSE_RMW_ALL.png');
  set(gcf,'inverthardcopy', 'off');
  print(gcf,'-dpng',frameid);
  clf

  for b=1:length(cmpbins)-1   % After plotting EVERYTHING above, plot each composite bin separately using the same approach
    mse_rad_plot=reshape(mse_rad(b,:,:),length(radbins),length(pressure));  % Need to make data 2-D to make Matlab happy.
    h=pcolor(radbins,pressure,mse_rad_plot.');
    colormap(turbo)
    set(h,'EdgeColor','none');
    cbh=colorbar;
    set(cbh,'YTick',[310000:10000:360000])
    brighten(-0.5)
    limits=[310000 360000];
    caxis(limits)
    xlim([min(radbins) max(radbins)])
    ylim([190 1010])
    set(gca,'XTick',(min(radbins):max(radbins)/10:max(radbins)))
    set(gca,'YTick',[200:100:1000])
    set(gca,'FontSize',14)
    set(gca,'YDir','reverse')
    set(gca,'YScale','log')
    grid on
    ylabel('Pressure (hPa)')
    xlabel('Radius (km)')
    str=strcat("Moist Static Energy (J/kg) - ",plottitle(b));  % Include the composite bin in the plot title
    title(str)
    frameid=sprintf('MSE_RAD_%02s_%02s.png',condition(c),plotname(b));  % And also include the bin in the file name!
    set(gcf,'inverthardcopy', 'off');
    print(gcf,'-dpng',frameid);
    clf

    mse_rmw_plot=reshape(mse_rmw(b,:,:),length(rmwbins),length(pressure));
    h=pcolor(rmwbins,pressure,mse_rmw_plot.');
    colormap(turbo)
    set(h,'EdgeColor','none');
    cbh=colorbar;
    set(cbh,'YTick',[310000:10000:360000])
    brighten(-0.5)
    limits=[310000 360000];
    caxis(limits)
    xlim([min(rmwbins) max(rmwbins)])
    ylim([190 1010])
    set(gca,'XTick',(min(rmwbins):max(rmwbins)/10:max(rmwbins)))
    set(gca,'YTick',[200:100:1000])
    set(gca,'FontSize',14)
    set(gca,'YDir','reverse')
    set(gca,'YScale','log')
    grid on
    ylabel('Pressure (hPa)')
    xlabel('Normalized Radius (R/RMW)')
    str=strcat("Moist Static Energy (J/kg) - ",plottitle(b));
    title(str)
    frameid=sprintf('MSE_RMW_%02s_%02s.png',condition(c),plotname(b));
    set(gcf,'inverthardcopy', 'off');
    print(gcf,'-dpng',frameid);
    clf
  end
end
toc  % Should spit out "Elapsed time is 450.493 seconds" or something.
disp('Done plotting composite MSE profiles')
cd /earl/s0/jdc6324/TCDROPS/REPOSITORY/Functions
return;
