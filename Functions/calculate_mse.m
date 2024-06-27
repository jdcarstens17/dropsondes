function mse = calculate_mse(pressure,temperature,height,mixing_ratio)
% FUNCTION mse: Written by Jake Carstens, current version 4/3/2023

% PURPOSE: Take dropsonde data (temperature, height, mixing ratio) on pressure levels and calculate moist static energy.

% INPUTS:
% 1. pressure      - Pressure levels (hPa), in 5 hPa increments from 50 --> 1010 hPa. 1-D array (level).
% 2. temperature   - Temperature, converted to Kelvin when calling this function. 2-D matrix (sonde,level).
% 3. height        - Altitude (m) at each pressure level along sonde's descent. 2-D matrix (sonde,level).
% 4. mixing_ratio  - Water vapor mixing ratio (g/kg) at each level. 2-D matrix (sonde,level).

% OUTPUTS: 2-D matrix of MSE (J/kg) in the same dimensions as temperature/height/mixing_ratio.
  cp=1005.0; % Specific heat capacity at constant pressure
  g=9.81;    % Gravitational acceleration
  L=2.5e6;   % Latent heat of vaporization
  mse=(cp.*temperature)+(g.*height)+(L.*mixing_ratio);
end
