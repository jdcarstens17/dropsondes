function [temperature,height,mixing_ratio] = quality_control(pressure,temperature,height,mixing_ratio)
% FUNCTION quality_control: Written by Jake Carstens, current version 10/5/2023

% PURPOSE: Identify and remove spurious data (T,Z,Q) relevant to moist static energy calculation, by imposing
%          a range of physically-reasonable values an observation must fall in at a given pressure level.

% INPUTS:
% 1. pressure      - Pressure levels (hPa), in 5 hPa increments from 50 --> 1010 hPa. 1-D array (level).
% 2. temperature   - Temperature (C). 2-D matrix (sonde,level).
% 3. height        - Altitude (m) at each pressure level along sonde's descent. 2-D matrix (sonde,level).
% 4. mixing_ratio  - Water vapor mixing ratio (kg/kg) at each level. 2-D matrix (sonde,level).

% OUTPUTS: Same 2-D matrices of temperature, height, and mixing_ratio, where -999 replaces any value deemed
%          to be physically-unreasonable.
  for n=1:length(temperature(:,1))
    disp(n)
    for z=1:length(pressure)

      % PROCEDURE I'LL USE FOR NOW: IF READING IS OUTSIDE OF A FIXED NUMBER OF STANDARD DEVIATIONS SET BY sd_limit_{VAR},
      % THEN WE'LL MAKE THAT VALUE A NAN. THIS WILL END UP MAKING THE FULL MSE A NAN AS WELL WHEN WE CALCULATE.

      % INFO ABOUT STANDARD DEVIATIONS:
      % mixing_ratio: Max S.D. is 6.3 g/kg at 215 hPa, typical S.D. is 2-3 g/kg in lower troposphere, steadily reducing above 750 hPa.
      % height: Max S.D. is 682.7 m at 75 hPa, highest in troposphere is 228.9 m at 300 hPa, typically in ballpark of 200 m with
      %         somewhat lower S.D.'s in the mid-troposphere (150 m?) and sharply reducing in the boundary layer.
      % temperature: Max S.D. is 4.22C at 100 hPa, highest in troposphere is 2.75C at 290 hPa, typically in ballpark of 1.5-2.5C,
      %              generally highest in the upper troposphere and lowest at the top of the boundary layer.

      % EXAMPLES OF EGREGIOUS OUTLIERS:
      % 1. Negative heights (or something like 100 m at 200 hPa... these jump out as weird-looking low values in MSE composite)
      % 2. Temperatures above freezing above ~400-500 hPa
      % 3. A mixing ratio I came across of 607 g/kg at 215 hPa (!)

      % NCAR EOL ARCHIVE USES 10 STANDARD DEVIATIONS AS ITS OUTLIER CHECK FOR TEMPERATURE AND RH, SO I'LL APPLY THOSE FOR NOW.
      % 5 SDs FOR HEIGHT IS MY OWN CHOICE, SUBJECT TO CHANGE. I'M OPTIMISTIC THIS WILL ELIMINATE THE PARTICULARLY WACKY STUFF.
      sd_limit_temp=10; sd_limit_height=5; sd_limit_mix=10;

      % THIS SECTION SIMPLY CHECKS IF A GIVEN READING IS WITHIN X STANDARD DEVIATIONS OF THE MEAN OF ALL SONDES AT THAT PRESSURE LEVEL!
      if ((temperature(n,z) > nanmean(temperature(:,z))+(std(temperature(:,z),'omitnan').*sd_limit_temp)) || (temperature(n,z) < nanmean(temperature(:,z))-(std(temperature(:,z),'omitnan').*sd_limit_temp)))
        temperature(n,z)=NaN;
      end
      if ((height(n,z) > nanmean(height(:,z))+(std(height(:,z),'omitnan').*sd_limit_height)) || (height(n,z) < nanmean(height(:,z))-(std(height(:,z),'omitnan').*sd_limit_height)) || (height(n,z) < 0))
        height(n,z)=NaN;
      end
      if ((mixing_ratio(n,z) > nanmean(mixing_ratio(:,z))+(std(mixing_ratio(:,z),'omitnan').*sd_limit_mix)) || (mixing_ratio(n,z) < nanmean(mixing_ratio(:,z))-(std(mixing_ratio(:,z),'omitnan').*sd_limit_mix)))
        mixing_ratio(n,z)=NaN;
      end
    end
  end
end
