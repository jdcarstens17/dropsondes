% Load_TCDROPS_Main.m - Written by Jake Carstens, starting 04/03/2023 (Current version written 06/26/2024)
% Purpose: Assist Michael Kopelman's tropical cyclone moist static energy climatology work.

% "Home Base" script to process dropsonde data from Jon Zawislak's TCDROPS dataset, including sonde data itself
% and several storm-specific and environmental variables. These include SST, wind shear, storm intensity and
% intensification rate, and dropsonde distance and azimuth from the TC center.

% The data file currently used has sonde data interpolated to pressure levels at 5 hPa resolution, optimal for simple
% calculation of MSE. Variables needed for this analysis, and their dimensions, are listed below.

% 1.  storm_name - Name of storm that dropsonde assesses. Example: al_sam2021. chars --> convert to strings. (SONDE_NUM)
% 2.  flight_id - Flight number/ID, based on program name. chars --> convert to strings. (SONDE_NUM)
% 3.  aircraft_type - Aircraft type. Example: p3, giv, c130, dc8, gh. chars --> convert to strings. (SONDE_NUM)
% 4.  vertical_levels - Pressure levels, in 5 hPa increments from 50 --> 1010 hPa. (NLEVS)
% 5.  temperature - Temperature in Celsius --> convert to Kelvin. (SONDE_NUM,NLEVS)
% 6.  height - Altitude of dropsonde in m. (SONDE_NUM,NLEVS)
% 7.  wvmr - Water vapor mixing ratio in kg/kg. (SONDE_NUM,NLEVS)
% 8.  type_BT - Categorization of storm type, including extratropical or subtropical storms. (SONDE_NUM)
% 9.  mslp_BT - Minimum sea level pressure (hPa) from nearest best track time. (SONDE_NUM)
% 10. vmax_BT - Maximum sustained wind speed (kt) from nearest best track time. (SONDE_NUM)
% 11. cp_hdg - Heading of storm motion (degrees). (SONDE_NUM)
% 12. sst - Nearest sea surface temperature (C) from NASA JPL GHRSST OI dataset. (SONDE_NUM)
% 13. vwsh_mag - Deep layer vertical wind shear (kt) from SHIPS. (SONDE_NUM)
% 14. dist - Distance of sonde (km) from interpolated best track TC center. (SONDE_NUM,NLEVS)
% 15. dist_hires - Distance (km) from 2-minute HRD-derived TC center --> PREFERRED. (SONDE_NUM,NLEVS)
% 16. azimuth - Azimuth (degrees from north) of sonde from interpolated best track TC center. (SONDE_NUM,NLEVS)
% 17. azimuth_hires - Azimuth (degrees from north) from 2-minute HRD-derived TC center --> PREFERRED. (SONDE_NUM,NLEVS)
% 18. azimuth_shr - Azimuth (degrees from north) of sonde from deep-layer shear vector. (SONDE_NUM,NLEVS)
% 19. azimuth_shr_hires - Shear-relative azimuth (degrees from north) from 2-minute HRD-derived TC center --> PREFERRED. (SONDE_NUM,NLEVS)
% 20. flp_sfmr_rmax_mean - Mean SFMR-derived radius of maximum winds (km) within 3 hours of dropsonde launch. (SONDE_NUM)
% 21. time_elapsed - Time (s) since dropsonde was launched. (SONDE_NUM,NLEVS)
% 22. month - Month of dropsonde launch. (SONDE_NUM)
% 23. day - Day of dropsonde launch. (SONDE_NUM)
% 24. hour - Hour of dropsonde launch. (SONDE_NUM)
% 25. minute - Minute of dropsonde launch. (SONDE_NUM)
% 26. second - Second of dropsonde launch, rounded to the nearest integer. (SONDE_NUM)
% 27. latitude_initial - Latitude of dropsonde launch (deg N). (SONDE_NUM)
% 28. longitude_initial - Longitude of dropsonde launch (deg E). (SONDE_NUM)
% 29. latitude - Latitude of dropsonde at a particular pressure level (deg N). (SONDE_NUM,NLEVS)
% 30. longitude - Longitude of dropsonde at a particular pressure level (deg E). (SONDE_NUM,NLEVS)
% 31. vmax_change_p6 - Intensity change (kt) 6 hours after nearest best track time. (SONDE_NUM)
% 32. vmax_change_p12 - Intensity change (kt) 12 hours after nearest best track time. (SONDE_NUM)
% 33. vmax_change_p18 - Intensity change (kt) 18 hours after nearest best track time. (SONDE_NUM)
% 34. vmax_change_p24 - Intensity change (kt) 24 hours after nearest best track time. (SONDE_NUM)

% ---------------------------- LOAD IN ALL DATA, THEN FIGURE OUT WHAT TO DISCARD. ------------------------------------
% I will call many variables the same name they have in TC-DROPS, appending "_total" onto them for now.
% Exceptions include the SFMR-derived radius of maximum winds (flp_sfmr_rmax_mean), because that's a bit confusing.
% Other exceptions include "latitude_initial" --> "latitude_launch", to specify that we're looking at data from the top down.

tic % You'll see "toc" at the end. This utility just tracks how long it takes to run things!
% BIG BLOCK OF CODE TO LOAD EVERYTHING IN BRUTE FORCE. ALL VARIABLES LISTED ABOVE ARE INCLUDED.
ncid=netcdf.open('/earl/s0/jdc6324/TCDROPS/Data/all_storms_pressure_dropsonde_dataset_ver1.2.nc','NOWRITE');
did=netcdf.inqVarID(ncid,'storm_name'); storm_name=netcdf.getVar(ncid,did).'; num_sondes_total=length(storm_name(:,1));
did=netcdf.inqVarID(ncid,'flight_id'); flight_total=netcdf.getVar(ncid,did).';
did=netcdf.inqVarID(ncid,'aircraft_type'); plane_total=netcdf.getVar(ncid,did).';
did=netcdf.inqVarID(ncid,'vertical_levels'); pressure=netcdf.getVar(ncid,did);
did=netcdf.inqVarID(ncid,'temperature'); temperature_total=netcdf.getVar(ncid,did);
did=netcdf.inqVarID(ncid,'height'); height_total=netcdf.getVar(ncid,did);
did=netcdf.inqVarID(ncid,'wvmr'); mixing_ratio_total=netcdf.getVar(ncid,did);
did=netcdf.inqVarID(ncid,'type_BT'); type_total=netcdf.getVar(ncid,did);
did=netcdf.inqVarID(ncid,'mslp_BT'); mslp_total=netcdf.getVar(ncid,did);
did=netcdf.inqVarID(ncid,'vmax_BT'); vmax_total=netcdf.getVar(ncid,did);
did=netcdf.inqVarID(ncid,'cp_hdg'); heading_total=netcdf.getVar(ncid,did);
did=netcdf.inqVarID(ncid,'sst'); sst_total=netcdf.getVar(ncid,did);
did=netcdf.inqVarID(ncid,'vwsh_mag'); shear_total=netcdf.getVar(ncid,did);
did=netcdf.inqVarID(ncid,'dist'); dist_total=netcdf.getVar(ncid,did);
did=netcdf.inqVarID(ncid,'dist_hires'); dist_hires_total=netcdf.getVar(ncid,did);  % If this isn't available for a given sonde, we use the above instead.
did=netcdf.inqVarID(ncid,'azimuth'); azimuth_total=netcdf.getVar(ncid,did);
did=netcdf.inqVarID(ncid,'azimuth_hires'); azimuth_hires_total=netcdf.getVar(ncid,did);  % Likewise for the azimuths.
did=netcdf.inqVarID(ncid,'azimuth_shr'); azimuth_shear_total=netcdf.getVar(ncid,did);
did=netcdf.inqVarID(ncid,'azimuth_shr_hires'); azimuth_shear_hires_total=netcdf.getVar(ncid,did);
did=netcdf.inqVarID(ncid,'flp_sfmr_rmax_mean'); rmax_total=netcdf.getVar(ncid,did);  % I have an alternative baked in later in case there's no SFMR.
did=netcdf.inqVarID(ncid,'time_elapsed'); time_total=netcdf.getVar(ncid,did);
did=netcdf.inqVarID(ncid,'month'); month_total=netcdf.getVar(ncid,did);
did=netcdf.inqVarID(ncid,'day'); day_total=netcdf.getVar(ncid,did);
did=netcdf.inqVarID(ncid,'hour'); hour_total=netcdf.getVar(ncid,did);
did=netcdf.inqVarID(ncid,'minute'); minute_total=netcdf.getVar(ncid,did);
did=netcdf.inqVarID(ncid,'second'); second_total=netcdf.getVar(ncid,did);
did=netcdf.inqVarID(ncid,'latitude_initial'); latitude_launch_total=netcdf.getVar(ncid,did);     % Makes it a bit easier to track the launch points...
did=netcdf.inqVarID(ncid,'longitude_initial'); longitude_launch_total=netcdf.getVar(ncid,did);   % ... though one could theoretically use plain lat/lon.
did=netcdf.inqVarID(ncid,'latitude'); latitude_total=netcdf.getVar(ncid,did);
did=netcdf.inqVarID(ncid,'longitude'); longitude_total=netcdf.getVar(ncid,did);
did=netcdf.inqVarID(ncid,'vmax_change_p6'); vmax_6_total=netcdf.getVar(ncid,did);     % I could see these variables being particularly useful for
did=netcdf.inqVarID(ncid,'vmax_change_p12'); vmax_12_total=netcdf.getVar(ncid,did);   % compositing down the road.
did=netcdf.inqVarID(ncid,'vmax_change_p18'); vmax_18_total=netcdf.getVar(ncid,did);
did=netcdf.inqVarID(ncid,'vmax_change_p24'); vmax_24_total=netcdf.getVar(ncid,did);
netcdf.close(ncid); % Phew. That's over with.

% ------- THIS NEXT SECTION IS IMPORTANT. HERE, WE IMPOSE CONDITIONS TO LIMIT OUR DATASET TO WHAT WE WANT. ------- %
% Variables I'm going to maintain include information about time, TC wind radii/intensity/intensification rate,
% SST and shear, dropsonde-derived variables such as temperature/mixing ratio/pressure/height, and dropsonde metadata
% such as the plane it was released from, the storm it's meant to assess, and its distance/azimuth from the storm center.

% START BY INITIALIZING A BUNCH OF BLANK ARRAYS. THESE VARIABLES WILL ALL EVENTUALLY GO INTO THE CONDENSED .MAT FILE.
year=[]; month=[]; day=[]; hour=[]; minute=[]; second=[]; rmw=[]; time=[];
temperature=[]; height=[]; mixing_ratio=[]; basin=strings; name=strings; plane=strings; flight=strings;
type=[]; mslp=[]; vmax=[]; heading=[]; sst=[]; shear=[]; rad=[]; azi=[]; azi_shr=[];
latitude_launch=[]; longitude_launch=[]; latitude=[]; longitude=[];
vmax_6=[]; vmax_12=[]; vmax_18=[]; vmax_24=[]; num_sondes_tc=0;
% num_sondes_tc will count the number of sondes we actually want to keep, based on our conditions.

for y=1:num_sondes_total   % LOOP THROUGH ALL SONDES IN TC-DROPS, AND DECIDE WHAT WE WANT TO KEEP!
  disp(y)  % This loop probably takes on the order of 15 minutes to run through. Just FYI.
  trim_name=deblank(storm_name(y,:));   % This just gets rid of annoying white space characters surrounding the TC name.
                                        % From here, I'll further split it up to pull the basin, year, and name separately.

% HERE'S THE CONDITION PART! IF ANY OF THE BELOW CONDITIONS ARE MET, WE SKIP THIS SONDE AND DON'T INCLUDE IT IN THE FINAL DATASET.
% THE CURRENT VERSION BELOW HAS THE FOLLOWING CONDITIONS:
% 1. trim_name(3) ~= '_' - Turns out that when the name doesn't have an underscore in its 3rd character, it's an invest, wave from a field campaign, or some other non-TC entity.
% 2. trim_name(1) ~= 'a' - The first 2 characters in "trim_name" are the basin, so this means we're ditching everything besides the Atlantic.
%                          I do this because wind radii are tracked differently, and we don't have SHIPS wind shear data over there (at least, that I can easily find).
% 3. all(time_total(y,:) == -999) - This will discard sondes that are completely blank.
% 4. type_total(y) - "4" is a TD, "5" is a TS, "6" is a HU. Anything outside this range is non-tropical. So I aim to keep those between 4-6.
% 5. plane_total(y,3) ~= 'v' - This will axe anything from planes that are not the G-IV.

  if (trim_name(3) ~= '_' || trim_name(1) ~= 'a' || all(time_total(y,:) == -999) || type_total(y) < 4 || type_total(y) > 6 || plane_total(y,3) ~= 'v')
    continue;
  end

% IF WE MADE IT TO THIS POINT, THAT MEANS THE SONDE IS GOOD TO INCLUDE. SO LET'S LOAD THAT DATA INTO OUR INITIALLY-BLANK MATRICES!
  num_sondes_tc=num_sondes_tc+1;              % Need to add a new sonde first, since each variable will be loaded into a new index.
  time(num_sondes_tc,:)=time_total(y,:);      % Just be careful to match the dimensions of the new data matrix to the original!
  month(num_sondes_tc)=month_total(y);
  day(num_sondes_tc)=day_total(y);
  hour(num_sondes_tc)=hour_total(y);
  minute(num_sondes_tc)=minute_total(y);
  second(num_sondes_tc)=second_total(y);
  year(num_sondes_tc)=str2num(trim_name(end-3:end));   % This will extract an integer corresponding to the year (i.e. 2004)
  basin(num_sondes_tc)=convertCharsToStrings(trim_name(1:2));      % The first 2 characters represent the basin (al,ep,wp)
  name(num_sondes_tc)=convertCharsToStrings(trim_name(4:end-4));   % Then, everything else is the name of the TC.
  plane(num_sondes_tc)=convertCharsToStrings(deblank(plane_total(y,:)));   % Trim white space characters off to get the plane ID.
  flight(num_sondes_tc)=convertCharsToStrings(deblank(flight_total(y,:)));
  type(num_sondes_tc)=type_total(y,:);     % Is it a TD, TS, HU, or something non-tropical or non-TC?
  mslp(num_sondes_tc)=mslp_total(y,:);     % Section to collect storm-specific info.
  vmax(num_sondes_tc)=vmax_total(y,:);
  rmw(num_sondes_tc)=rmax_total(y);        % This pulls from SFMR, which is most likely to exist in low-level recon. See later for workaround.
  temperature(num_sondes_tc,:)=temperature_total(y,:);   % Sonde-specific variables.
  height(num_sondes_tc,:)=height_total(y,:);
  mixing_ratio(num_sondes_tc,:)=mixing_ratio_total(y,:);
  sst(num_sondes_tc)=sst_total(y,:);      % From NOAA OISST
  shear(num_sondes_tc)=shear_total(y,:);  % From SHIPS
  heading(num_sondes_tc)=heading_total(y,:);
  rad(num_sondes_tc,:)=dist_hires_total(y,:);  % "hires" uses the 2-minute-resolution HRD tracks, if available.
  rad(find(rad(num_sondes_tc,:)==-999))=dist_total(y,find(rad(num_sondes_tc,:)==-999));  % If not, we use linear interpolation between best track fixes.
  azi(num_sondes_tc,:)=azimuth_hires_total(y,:);
  azi(find(azi(num_sondes_tc,:)==-999))=azimuth_total(y,find(azi(num_sondes_tc,:)==-999));
  azi_shr(num_sondes_tc,:)=azimuth_shear_hires_total(y,:);   % Shear-rotated azimuth, where 0 deg is directly downshear.
  azi_shr(find(azi_shr(num_sondes_tc,:)==-999))=azimuth_shear_total(y,find(azi_shr(num_sondes_tc,:)==-999));
  latitude_launch(num_sondes_tc)=latitude_launch_total(y);
  longitude_launch(num_sondes_tc)=longitude_launch_total(y);
  latitude(num_sondes_tc,:)=latitude_total(y,:);
  longitude(num_sondes_tc,:)=longitude_total(y,:);
  vmax_6(num_sondes_tc)=vmax_6_total(y);
  vmax_12(num_sondes_tc)=vmax_12_total(y);
  vmax_18(num_sondes_tc)=vmax_18_total(y);
  vmax_24(num_sondes_tc)=vmax_24_total(y);
end

% CLEAR ALL OF OUR RAW DATA LOADED IN FROM TC-DROPS DIRECTLY. WE DON'T NEED THAT ANYMORE AND WE ONLY WANT TO SAVE THE CONDENSED DATA
clear flight_total plane_total temperature_total height_total mixing_ratio_total type_total mslp_total vmax_total heading_total sst_total shear_total
clear dist_total dist_hires_total azimuth_total azimuth_hires_total azimuth_shear_total azimuth_shear_hires_total rmax_total time_total
clear month_total day_total hour_total minute_total second_total latitude_launch_total longitude_launch_total
clear vmax_6_total vmax_12_total vmax_18_total vmax_24_total latitude_total longitude_total

% For all variables that we want to throw in the .mat file, change all of the -999 (missing) values to NaN. This can be done in one line.
% There will probably still be individual sondes with weird values. QC doesn't always get the full job done!
% If you find that these outliers present problems, I encourage you to explore strategies to remove them from the dataset.
% Otherwise, feel free to contact me and I can attempt to impose additional quality-based conditions limiting the dataset.
temperature(temperature==-999)=NaN; height(height==-999)=NaN; mixing_ratio(mixing_ratio==-999)=NaN;
type(type==-999)=NaN; mslp(mslp==-999)=NaN; vmax(vmax==-999)=NaN; heading(heading==-999)=NaN;
sst(sst==-999)=NaN; shear(shear==-999)=NaN; rad(rad==-999)=NaN; azi(azi==-999)=NaN;
azi_shr(azi_shr==-999)=NaN; time(time==-999)=NaN; rmw(rmw==-999)=NaN;
latitude_launch(latitude_launch==-999)=NaN; longitude_launch(longitude_launch==-999)=NaN;
latitude(latitude==-999)=NaN; longitude(longitude==-999)=NaN;
vmax_6(vmax_6==-999)=NaN; vmax_12(vmax_12==-999)=NaN; vmax_18(vmax_18==-999)=NaN; vmax_24(vmax_24==-999)=NaN;

% CALL NEW FUNCTION INTRODUCED 10/5, quality_control.m, TO IDENTIFY ERRONEOUS DATA IMPACTING THE MSE CALCULATION AND SET TO -999.
% ERRORS WERE IDENTIFIED IN LATE SEPTEMBER REGARDING NEGATIVE HEIGHTS, AND JAKE ALSO FOUND TEMPERATURE READINGS ABOVE 50C (UNREALISTIC).
% MIXING RATIO SEEMS MOSTLY FINE, THOUGH VALUES NEAR 30 g/kg HAVE BEEN SEEN, WHICH ALSO SEEM A BIT HIGH (WOULD IMPLY A ~90F DEWPOINT)
% INITIAL CRITERIA FOR REMOVAL: T > 35C, Z < 0, Q > 30.
% MORE RIGID TESTS MAY BE APPLIED LATER IF DEEMED NECESSARY.
[temperature,height,mixing_ratio]=quality_control(pressure,temperature,height,mixing_ratio);

% CLEAR OUT SOME EXTRA UNNECESSARY VARIABLES BEFORE COLLECTING A COUPLE MORE PIECES OF INFORMATION.
clear did ncid num_sondes_tc num_sondes_total storm_name trim_name y
mse = calculate_mse(pressure,temperature+273.15,height,mixing_ratio);  % A one-stop shop function to calculate MSE at each vertical level for each sonde.
[rmw,r34,r50,r64] = calc_windradii(year,month,day,hour,minute,second,basin,name,rmw);  % Gather wind radii information from the Extended Best Track dataset.
[lmi,n_hours_from_lmi] = find_lmi(year,month,day,hour,minute,second,basin,name);       % Identify the storm's lifetime maximum intensity, and how far that sonde is in time from it.
% RMW is collected here if an SFMR-derived value does not already exist (NaN above).
% The above function takes the longest of anything in my current code base
% Thankfully, you won't need to worry about this, as you'll have the data you need.
cd /earl/s0/jdc6324/TCDROPS/REPOSITORY/Data                  % Change this to wherever you'd want to house your data files.
%save -v7.3 TCDROPS_Basins_AL_Planes_GIV.mat    % Save all existing variables in workspace to a .mat file, and we're done!
save -v7.3 TCDROPS_Basins_AL_Planes_GIV.mat pressure height temperature mixing_ratio mse mslp vmax vmax_24 rmw rad azi lmi n_hours_from_lmi azi_shr shear sst

% LET'S CONCLUDE BY CREATING THE SAME DERIVED DATA FILE IN NETCDF FORMAT.
ncfile=['/earl/s0/jdc6324/TCDROPS/REPOSITORY/Data/TCDROPS_Basins_AL_Planes_GIV.nc'];
nccreate(ncfile,'sonde','Datatype','int32','Dimensions',{'sonde',length(name)});
ncwrite(ncfile,'sonde',1:length(name));
nccreate(ncfile,'pressure','Datatype','single','Dimensions',{'pressure',length(pressure)});
ncwrite(ncfile,'pressure',pressure);
%nccreate(ncfile,'quadrant','Datatype','string','Dimensions',{'quadrant',4});
%ncwrite(ncfile,'quadrant',["NE","NW","SW","SE"]);
%nccreate(ncfile,'name','Datatype','string','Dimensions',{'sonde',length(name)});
%ncwrite(ncfile,'name',name);
%nccreate(ncfile,'flight','Datatype','string','Dimensions',{'sonde',length(name)});
%ncwrite(ncfile,'flight',flight);
%nccreate(ncfile,'basin','Datatype','string','Dimensions',{'sonde',length(name)});
%ncwrite(ncfile,'basin',basin);
%nccreate(ncfile,'plane','Datatype','string','Dimensions',{'sonde',length(name)});
%ncwrite(ncfile,'plane',plane);
%nccreate(ncfile,'latitude_launch','Datatype','single','Dimensions',{'sonde',length(name)});
%ncwrite(ncfile,'latitude_launch',latitude_launch);
%nccreate(ncfile,'longitude_launch','Datatype','single','Dimensions',{'sonde',length(name)});
%ncwrite(ncfile,'longitude_launch',longitude_launch);
%nccreate(ncfile,'year','Datatype','int32','Dimensions',{'sonde',length(name)});
%ncwrite(ncfile,'year',year);
%nccreate(ncfile,'month','Datatype','int32','Dimensions',{'sonde',length(name)});
%ncwrite(ncfile,'month',month);
%nccreate(ncfile,'day','Datatype','int32','Dimensions',{'sonde',length(name)});
%ncwrite(ncfile,'day',day);
%nccreate(ncfile,'hour','Datatype','int32','Dimensions',{'sonde',length(name)});
%ncwrite(ncfile,'hour',hour);
%nccreate(ncfile,'minute','Datatype','int32','Dimensions',{'sonde',length(name)});
%ncwrite(ncfile,'minute',minute);
%nccreate(ncfile,'second','Datatype','int32','Dimensions',{'sonde',length(name)});
%ncwrite(ncfile,'second',second);
%nccreate(ncfile,'type','Datatype','int32','Dimensions',{'sonde',length(name)});
%ncwrite(ncfile,'type',type);
nccreate(ncfile,'height','Datatype','int32','Dimensions',{'sonde',length(name),'pressure',length(pressure)});
ncwrite(ncfile,'height',height);
nccreate(ncfile,'temperature','Datatype','single','Dimensions',{'sonde',length(name),'pressure',length(pressure)});
ncwrite(ncfile,'temperature',temperature);
nccreate(ncfile,'mixing_ratio','Datatype','single','Dimensions',{'sonde',length(name),'pressure',length(pressure)});
ncwrite(ncfile,'mixing_ratio',mixing_ratio);
nccreate(ncfile,'mse','Datatype','single','Dimensions',{'sonde',length(name),'pressure',length(pressure)});
ncwrite(ncfile,'mse',mse);
%nccreate(ncfile,'latitude','Datatype','single','Dimensions',{'sonde',length(name),'pressure',length(pressure)});
%ncwrite(ncfile,'latitude',latitude);
%nccreate(ncfile,'longitude','Datatype','single','Dimensions',{'sonde',length(name),'pressure',length(pressure)});
%ncwrite(ncfile,'longitude',longitude);
%nccreate(ncfile,'time','Datatype','single','Dimensions',{'sonde',length(name),'pressure',length(pressure)});
%ncwrite(ncfile,'time',time);
nccreate(ncfile,'mslp','Datatype','int32','Dimensions',{'sonde',length(name)});
ncwrite(ncfile,'mslp',mslp);
nccreate(ncfile,'vmax','Datatype','int32','Dimensions',{'sonde',length(name)});
ncwrite(ncfile,'vmax',vmax);
%nccreate(ncfile,'vmax_6','Datatype','int32','Dimensions',{'sonde',length(name)});
%ncwrite(ncfile,'vmax_6',vmax_6);
%nccreate(ncfile,'vmax_12','Datatype','int32','Dimensions',{'sonde',length(name)});
%ncwrite(ncfile,'vmax_12',vmax_12);
%nccreate(ncfile,'vmax_18','Datatype','int32','Dimensions',{'sonde',length(name)});
%ncwrite(ncfile,'vmax_18',vmax_18);
nccreate(ncfile,'vmax_24','Datatype','int32','Dimensions',{'sonde',length(name)});
ncwrite(ncfile,'vmax_24',vmax_24);
nccreate(ncfile,'rmw','Datatype','int32','Dimensions',{'sonde',length(name)});
ncwrite(ncfile,'rmw',rmw);
%nccreate(ncfile,'r34','Datatype','single','Dimensions',{'sonde',length(name),'quadrant',4});
%ncwrite(ncfile,'r34',r34);
%nccreate(ncfile,'r50','Datatype','single','Dimensions',{'sonde',length(name),'quadrant',4});
%ncwrite(ncfile,'r50',r50);
%nccreate(ncfile,'r64','Datatype','single','Dimensions',{'sonde',length(name),'quadrant',4});
%ncwrite(ncfile,'r64',r64);
%nccreate(ncfile,'heading','Datatype','single','Dimensions',{'sonde',length(name)});
%ncwrite(ncfile,'heading',heading);
nccreate(ncfile,'rad','Datatype','single','Dimensions',{'sonde',length(name),'pressure',length(pressure)});
ncwrite(ncfile,'rad',rad);
nccreate(ncfile,'azi','Datatype','single','Dimensions',{'sonde',length(name),'pressure',length(pressure)});
ncwrite(ncfile,'azi',azi);
nccreate(ncfile,'lmi','Datatype','int32','Dimensions',{'sonde',length(name)});
ncwrite(ncfile,'lmi',lmi);
nccreate(ncfile,'n_hours_from_lmi','Datatype','single','Dimensions',{'sonde',length(name)});
ncwrite(ncfile,'n_hours_from_lmi',n_hours_from_lmi);
nccreate(ncfile,'azi_shr','Datatype','single','Dimensions',{'sonde',length(name),'pressure',length(pressure)});
ncwrite(ncfile,'azi_shr',azi_shr);
nccreate(ncfile,'shear','Datatype','int32','Dimensions',{'sonde',length(name)});
ncwrite(ncfile,'shear',shear);
nccreate(ncfile,'sst','Datatype','single','Dimensions',{'sonde',length(name)});
ncwrite(ncfile,'sst',sst);

ncwriteatt(ncfile,'sonde','long_name','Dropsonde Number');
ncwriteatt(ncfile,'pressure','long_name','Pressure');
%ncwriteatt(ncfile,'quadrant','long_name','Storm-Relative Quadrant');
%ncwriteatt(ncfile,'name','long_name','Storm Name');
%ncwriteatt(ncfile,'flight','long_name','Flight ID');
%ncwriteatt(ncfile,'basin','long_name','Ocean Basin');
%ncwriteatt(ncfile,'plane','long_name','Aircraft Name');
%ncwriteatt(ncfile,'latitude_launch','long_name','Latitude of Dropsonde Launch');
%ncwriteatt(ncfile,'longitude_launch','long_name','Longitude of Dropsonde Launch');
%ncwriteatt(ncfile,'year','long_name','Year of Dropsonde Launch');
%ncwriteatt(ncfile,'month','long_name','Month of Dropsonde Launch');
%ncwriteatt(ncfile,'day','long_name','Day of Dropsonde Launch');
%ncwriteatt(ncfile,'hour','long_name','Hour of Dropsonde Launch');
%ncwriteatt(ncfile,'minute','long_name','Minute of Dropsonde Launch');
%ncwriteatt(ncfile,'second','long_name','Second of Dropsonde Launch');
%ncwriteatt(ncfile,'type','long_name','Storm Classification');
ncwriteatt(ncfile,'height','long_name','Altitude');
ncwriteatt(ncfile,'temperature','long_name','Temperature');
ncwriteatt(ncfile,'mixing_ratio','long_name','Water Vapor Mixing Ratio');
ncwriteatt(ncfile,'mse','long_name','Moist Static Energy');
%ncwriteatt(ncfile,'latitude','long_name','Latitude');
%ncwriteatt(ncfile,'longitude','long_name','Longitude');
%ncwriteatt(ncfile,'time','long_name','Seconds Since Dropsonde Launch');
ncwriteatt(ncfile,'mslp','long_name','Minimum TC Sea Level Pressure');
ncwriteatt(ncfile,'vmax','long_name','Maximum Sustained TC Wind Speed');
%ncwriteatt(ncfile,'vmax_6','long_name','6-Hour Intensity Change After Observation');
%ncwriteatt(ncfile,'vmax_12','long_name','12-Hour Intensity Change After Observation');
%ncwriteatt(ncfile,'vmax_18','long_name','18-Hour Intensity Change After Observation');
ncwriteatt(ncfile,'vmax_24','long_name','24-Hour Intensity Change After Observation');
ncwriteatt(ncfile,'rmw','long_name','Radius of Maximum Winds');
%ncwriteatt(ncfile,'r34','long_name','Radius of 34-Knot Winds (Storm-Relative Quadrants)');
%ncwriteatt(ncfile,'r50','long_name','Radius of 50-Knot Winds (Storm-Relative Quadrants)');
%ncwriteatt(ncfile,'r64','long_name','Radius of 64-Knot Winds (Storm-Relative Quadrants)');
%ncwriteatt(ncfile,'heading','long_name','Storm Motion Heading');
ncwriteatt(ncfile,'rad','long_name','Distance from TC Center');
ncwriteatt(ncfile,'azi','long_name','Storm-Relative Azimuth');
ncwriteatt(ncfile,'lmi','long_name','Lifetime Maximum Intensity');
ncwriteatt(ncfile,'n_hours_from_lmi','long_name','Number of Hours from Lifetime Maximum Intensity');
ncwriteatt(ncfile,'azi_shr','long_name','Shear-Relative Azimuth');
ncwriteatt(ncfile,'shear','long_name','Deep-Layer Wind Shear Magnitude');
ncwriteatt(ncfile,'sst','long_name','Sea Surface Temperature');

ncwriteatt(ncfile,'sonde','units',' ');
ncwriteatt(ncfile,'pressure','units','hPa');
%ncwriteatt(ncfile,'quadrant','units',' ');
%ncwriteatt(ncfile,'name','units',' ');
%ncwriteatt(ncfile,'flight','units',' ');
%ncwriteatt(ncfile,'basin','units',' ');
%ncwriteatt(ncfile,'plane','units',' ');
%ncwriteatt(ncfile,'latitude_launch','units','degrees north');
%ncwriteatt(ncfile,'longitude_launch','units','degrees east');
%ncwriteatt(ncfile,'year','units',' ');
%ncwriteatt(ncfile,'month','units',' ');
%ncwriteatt(ncfile,'day','units',' ');
%ncwriteatt(ncfile,'hour','units',' ');
%ncwriteatt(ncfile,'minute','units',' ');
%ncwriteatt(ncfile,'second','units',' ');
%ncwriteatt(ncfile,'type','units',' ');
ncwriteatt(ncfile,'height','units','m');
ncwriteatt(ncfile,'temperature','units','K');
ncwriteatt(ncfile,'mixing_ratio','units','kg/kg');
ncwriteatt(ncfile,'mse','units','J/kg');
%ncwriteatt(ncfile,'latitude','units','degrees north');
%ncwriteatt(ncfile,'longitude','units','degrees east');
%ncwriteatt(ncfile,'time','units','s');
ncwriteatt(ncfile,'mslp','units','hPa');
ncwriteatt(ncfile,'vmax','units','knots');
%ncwriteatt(ncfile,'vmax_6','units','knots');
%ncwriteatt(ncfile,'vmax_12','units','knots');
%ncwriteatt(ncfile,'vmax_18','units','knots');
ncwriteatt(ncfile,'vmax_24','units','knots');
ncwriteatt(ncfile,'rmw','units','km');
%ncwriteatt(ncfile,'r34','units','km');
%ncwriteatt(ncfile,'r50','units','km');
%ncwriteatt(ncfile,'r64','units','km');
%ncwriteatt(ncfile,'heading','units','degrees counterclockwise from east');
ncwriteatt(ncfile,'rad','units','km');
ncwriteatt(ncfile,'azi','units','degrees clockwise from north');
ncwriteatt(ncfile,'lmi','units','knots');
ncwriteatt(ncfile,'n_hours_from_lmi','units','hours');
ncwriteatt(ncfile,'azi_shr','units','degrees clockwise from north');
ncwriteatt(ncfile,'shear','units','knots');
ncwriteatt(ncfile,'sst','units','degrees Celsius');

clear
cd /earl/s0/jdc6324/TCDROPS/REPOSITORY/Functions   % Sets me up to dive right into other functions in my "CallToFunctions.m" script.
toc
