function progressBar( doInit, message, loopIdx, numLoops )
% PROGRESSBAR Displays as progress bar which can be used to inform the user
%   about the progress of a computation carried out within loops.
%
% REQUIRED INPUTS:
%   doInit                          - Initialization flag. Set this to true
%                                     of the progress bar should be
%                                     initialized. For using it within
%                                     loops, set it to false.
%   message                         - Additional message to be displayed
%                                     with the progress bar. Length should
%                                     not exceed 25 characters.
%   loopIdx                         - Current index of the loop where the
%                                     computation is carried out.
%   numLoops                        - Total number of loops.
%
% EXAMPLE:
%
%       numLoops = 100;
%       progressBar( true, 'Test' );
%
%       for loopIdx = 1 : numLoops
%           progressBar( false, 'Test', loopIdx, numLoops );
%           pause(0.1);
%       end
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

p.addRequired( 'DoInit', @islogical );
p.addRequired( 'Message', @isstr );

if doInit
    p.parse( doInit, message );
else
    p.addRequired( 'LoopIdx', @(x) validateattributes(x, {'numeric'}, ...
        {'scalar', 'integer', 'nonnegative'}) );
    p.addRequired( 'NumLoops', @(x) validateattributes(x, {'numeric'}, ...
        {'scalar', 'integer', 'nonnegative'}) );
    p.parse( doInit, message, loopIdx, numLoops );
end

% Create string containing the current progress information. At 
% initialization, the progress percentage is set to zero.
if doInit
    % Print "0% progress line".
    progressLine = sprintf( '  %-25s %3.0f %%%% [%-40s]', ...
        p.Results.Message, 0, '' );
    fprintf( progressLine );
else
    % Compute progress advancement in percent and create a string containing
    % the progress indicator symbols acoording to this percentage.
    progressPercentage = ( p.Results.LoopIdx / p.Results.NumLoops ) * 100;
    progressIndicator = repmat( '=', 1, round(40 * progressPercentage / 100) );
    
    % Update progress line with current progress percentage.
    progressLine = sprintf( '  %-25s %3.0f %%%% [%-40s]', ...
        p.Results.Message, progressPercentage, progressIndicator );
    
    % Overwrite old progress line with updated one.
    deleteLine = repmat( '\b', 1, length(progressLine) - 1 );
    fprintf( [deleteLine, progressLine] );
    
    % Insert line-break if the progress is finished.
    if progressPercentage >= 100
        fprintf('\n');
    end    
end

end