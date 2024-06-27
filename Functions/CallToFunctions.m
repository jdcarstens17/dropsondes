load('/earl/s0/jdc6324/TCDROPS/REPOSITORY/Data/TCDROPS_Basins_AL_Planes_GIV.mat')

%storm_stats(vmax,mslp,rmw,sst,shear,rad,azi,azi_shr);
%composites(mse,pressure,rad,rmw,vmax,vmax_24,sst,shear);
heatmaps(rad,rmw,azi,azi_shr,vmax,vmax_24,sst,shear);
