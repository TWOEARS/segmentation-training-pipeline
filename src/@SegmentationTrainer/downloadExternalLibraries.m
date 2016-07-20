function downloadExternalLibraries()
% DOWNLOADEXTERNALLIBRARIES This script downloads all external libraries
%   that are needed to run the SegmentationKS training and automatically
%   adds the specific folders to the MATLAB serach path.
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

% Get base path to working directory
basePath = fileparts( mfilename('fullpath') );
pathToExternalLibraries = ...
    fullfile( basePath(1 : strfind(basePath, '@') - 1), '..', 'external' );

% Import helper functions for console output
import display.*

% Check if folder for external libraries exists
if ~exist( pathToExternalLibraries, 'dir' )
    mkdir( pathToExternalLibraries );
end

sectionHeader( 'Initializing::External libraries' );

% DataHash by Jan Simon
% More info at: http://www.mathworks.com/matlabcentral/fileexchange/31272-datahash

% Path to library
dataHashPath = fullfile( pathToExternalLibraries, 'data-hash' );

if ~exist( dataHashPath, 'dir' )
    subsection( 'Downloading::DataHash' );
    
    % URL for library download
    url = 'http://www.mathworks.com/matlabcentral/mlc-downloads/downloads/submissions/31272/versions/7/download/zip';
    
    % Start download
    urlwrite( url, fullfile(pathToExternalLibraries, 'DataHash.zip') );
    unzip( fullfile(pathToExternalLibraries, 'DataHash.zip'), dataHashPath );
    delete( fullfile(pathToExternalLibraries, 'DataHash.zip') );
end

addpath( dataHashPath );

% YAMLMatlab by Yauhen Yakimovich
% More info at: https://github.com/ewiger/yamlmatlab

% Path to library
yamlMatlabPath = fullfile( pathToExternalLibraries, 'yaml-matlab' );

if ~exist( yamlMatlabPath, 'dir' )
    subsection( 'Downloading::YAMLMatlab' );
    
    % URL for library download
    url = 'https://github.com/ewiger/yamlmatlab/archive/master.zip';
    
    % Start download
    urlwrite( url, fullfile(pathToExternalLibraries, 'yaml-matlab.zip') );
    unzip( fullfile(pathToExternalLibraries, 'yaml-matlab.zip'), yamlMatlabPath );
    movefile( fullfile(pathToExternalLibraries, 'yaml-matlab', ...
        'yamlmatlab-master', '+yaml'), pathToExternalLibraries );
    rmdir( fullfile(pathToExternalLibraries, 'yaml-matlab'), 's' );
    movefile( fullfile(pathToExternalLibraries, '+yaml'), ...
        fullfile(pathToExternalLibraries, 'yaml-matlab') );
    delete( fullfile(pathToExternalLibraries, 'yaml-matlab.zip') );
end

addpath( yamlMatlabPath );

sectionFooter();

end