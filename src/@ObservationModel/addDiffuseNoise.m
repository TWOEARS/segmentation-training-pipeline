function noisySignal = addDiffuseNoise( earSignals, diffuseNoiseSignal, ...
    desiredSNR)
% ADDDIFFUSENOISE This function can be used to add diffuse noise to a
%   binaural signal at a specific signal-to-noise ratio.
%
% REQUIRED INPUTS:
%   earSignals                      - Spatialized binaural signals.
%   diffuseNoiseSignal              - Binaural, diffuse noise signal.
%   desiredSNR                      - Signal-to-noise ratio in dB.
%
% OUTPUTS:
%   noisySignal                     - Resulting mixture signal.
%
% AUTHOR:
%   Copyright (c) 2016      Christopher Schymura
%                           Cognitive Signal Processing Group
%                           Ruhr-Universitaet Bochum
%                           Universitaetsstr. 150
%                           44801 Bochum, Germany
%                           E-Mail: christopher.schymura@rub.de
%
% LICENSE INFORMATION:
%   This program is free software: you can redistribute it and/or
%   modify it under the terms of the GNU General Public License as
%   published by the Free Software Foundation, either version 3 of the
%   License, or (at your option) any later version.
%
%   This material is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
%   GNU General Public License for more details.
%
%   You should have received a copy of the GNU General Public License
%   along with this program. If not, see <http://www.gnu.org/licenses/>

% Check input arguments.
p = inputParser();

p.addRequired( 'EarSignals', @(x) validateattributes(x, {'numeric'}, ...
    {'2d', 'real', 'ncols', 2}) );
p.addRequired( 'DiffuseNoiseSignal', @(x) validateattributes(x, {'numeric'}, ...
    {'2d', 'real', 'ncols', 2}) );
p.addRequired( 'DesiredSNR', @(x) validateattributes(x, {'numeric'}, ...
    {'scalar', 'real'}) );
p.parse( earSignals, diffuseNoiseSignal, desiredSNR );

% Compute signal eneries and derive the corresponding noise gain factor.
signalEnergy = std( p.Results.EarSignals(:) );
noiseEnergy = std( p.Results.DiffuseNoiseSignal(:) );
noiseGain = (signalEnergy / noiseEnergy) * 10^(-p.Results.DesiredSNR / 20);

% Compute resulting noisy signal.
noisySignal = p.Results.EarSignals + noiseGain .* p.Results.DiffuseNoiseSignal;

end