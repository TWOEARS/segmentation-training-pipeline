function fileName = getFeatureFileName( impulseResponseName, azimuth, mctLevel )
% GETFEATUREFILENAME Returns the name of the feature file for a specific set of
%   impulse responses at a particular angle and MCT level.
%
% REQUIRED INPUTS:
%   impulseResponseName             - Name of the HRIR set that should be
%                                     used for creating the file.
%   azimuth                         - Source azimuth in degrees.
%   mctLevel                        - SNR for MCT.
%
% OUTPUTS:
%   fileName                        - Name of the corresponding data file.
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

p.addRequired( 'ImpulseResponseName', @isstr );
p.addRequired( 'Azimuth', @(x) validateattributes(x, {'numeric'}, ...
    {'integer', 'scalar', '>=', -180, '<=', 180}) );
p.parse( impulseResponseName, azimuth );

% Assemble file name for specified settings.
if ischar( mctLevel ) && strcmpi( mctLevel, 'inf' )
    fileName = fullfile( lower([p.Results.ImpulseResponseName, '_', ...
        num2str(p.Results.Azimuth), 'deg_inf.mat']) );
else
    fileName = fullfile( lower([p.Results.ImpulseResponseName, '_', ...
        num2str(p.Results.Azimuth), 'deg_', num2str(mctLevel), ...
        '_dB.mat']) );
end

end