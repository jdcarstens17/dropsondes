function [rmw,r34,r50,r64] = calc_windradii(year,month,day,hour,minute,second,basin,name,rmw)
% FUNCTION calc_windradii.m - Written by Jake Carstens 4/5/2023

% PURPOSE: Parse through the Extended Best Track Dataset (Demuth et al. 2006) and assign the nearest fix's
%          34, 50, and 64 knot wind radii to each dropsonde in TC-DROPS. Also, if there is no existing
%          SFMR-derived radius of maximum winds, use the EXBT to assign one in its place.

% INPUTS:
% 1. year   - Year that dropsonde was released in. 1-D array.
% 2. month  - Month of dropsonde launch. 1-D array.
% 3. day    - Day of dropsonde launch. 1-D array.
% 4. hour   - Hour of dropsonde launch. 1-D array.
% 5. minute - Minute of dropsonde launch. 1-D array.
% 6. second - Second of dropsonde launch. 1-D array.
% 7. basin  - Basin that dropsonde was released in. 1-D array.
% 8. name   - Name of TC that dropsonde is sampling. 1-D array.
% 9. rmw    - Radius of maximum winds derived from SFMR in main function. 1-D array.

% OUTPUTS:
% 1. rmw - Radius of maximum winds, where EXBT fills in any gaps left by SFMR. 1-D array.
% 2. r34 - Radius of 34-knot (TS) winds in NE --> NW --> SW --> SE quadrants. 2-D matrix (sonde,quadrant).
% 3. r50 - Radius of 50-knot winds derived from EXBT. 2-D matrix (sonde,quadrant).
% 4. r64 - Radius of 64-knot (HU) winds. 2-D matrix (sonde,quadrant).

  r34=NaN(length(year),4); r50=NaN(length(year),4); r64=NaN(length(year),4);
  for n=1:length(year)   % LOOP THROUGH ALL DROPSONDES!
    disp(n)  % This takes on the order of 1 hour to run. Just FYI. Easily the longest part of my existing codebase as it's rather brute force.
% THE IDEA: USE "basin" TO IDENTIFY WHAT EXBT FILE TO OPEN. I HAVE MERGED THE EXBT CP AND EP FILES INTO ONE, AND MATCHED NAMING CONVENTIONS FOR TDs.
    fid=fopen(['/earl/s0/jdc6324/TCDROPS/Data/EXBT_' convertStringsToChars(upper(basin(n))) '.txt'],'r');
    format_info='%8c %s %6c %f %f %f %f %f %f %f %f %f %3f %3f %3f %3f %3f %3f %3f %3f %3f %3f %3f %3f %1c %f %4c'; a=textscan(fid,format_info);
% THE ABOVE LINE LOADS IN ALL LINES OF EXBT AS A CELL MATRIX, WHERE "c" MEANS CHARACTER ARRAY, "f" MEANS FLOATING-POINT NUMBER, ETC.
    exbt=zeros(length(a{4}),1);  % This is a placeholder array to account for the fact that EXBT doesn't have time down to the nearest millisecond.
% BELOW: datetime ARRAYS ARE REALLY COOL! I'M JUST MERGING THE YEAR, MONTH, DAY, ETC. INTO AN ARRAY THAT HELPS US FIND THE CLOSEST FIX TIME TO THE SONDE.
    tracktime=datetime(a{4},str2num(a{3}(:,1:2)),str2num(a{3}(:,3:4)),str2num(a{3}(:,5:6)),exbt,exbt,exbt);
    sondetime=datetime(year(n),month(n),day(n),hour(n),minute(n),second(n));   % Pass in sonde metadata accordingly.

    for t=2:length(exbt)  % Loop through EXBT to check that the sonde/best track storm names match, and find the closest fix time to assign to sonde.
      if (strcmpi(name(n),a{2}(t,1:length(name(n)))) == 1 && seconds(sondetime-tracktime(t-1)) >= 0 && seconds(sondetime-tracktime(t)) < 0)
        tracksec=seconds(tracktime(t)-tracktime(t-1)); sondesec=seconds(sondetime-tracktime(t-1));
        if (sondesec./tracksec < 0.5) % We have found ourselves between 2 fixes! Which one are we closer to? That's all this checks for.
          nearest=t-1;
        else
          nearest=t;
        end
        for q=1:4  % With the nearest fix time assigned, let's go quadrant by quadrant to assign R34/50/64 values.
          r34(n,q)=a{q+12}(nearest).*1.852;  % Listed in nautical miles in EXBT, so I convert to km here.
          r50(n,q)=a{q+16}(nearest).*1.852;
          r64(n,q)=a{q+20}(nearest).*1.852;
        end
        r34(r34<0)=NaN;  r50(r50<0)=NaN; r64(r64<0)=NaN;  % Missing values are possible here too, especially before 2004! Account for that in this line.
        if (isnan(rmw(n)))   % If SFMR data is missing, throw in the EXBT value in its place.
          rmw(n)=a{9}(nearest).*1.852; rmw(rmw<0)=NaN;
        end
        break;  % We have found our fix and assigned it to the sonde, so break out and move on to the next sonde.
      end
    end
    fclose(fid);  % It's a bit clunky, but we'll close and re-open the EXBT file for each sonde, especially since the basins switch off sporadically.
  end
end
