function likelihood = computeLikelihood( obj, itds, ilds, azimuth )
% COMPUTELIKELIHOOD Computes the observation likelihood for a specific set
%   of ITDs and ILDs, given an azimuth angle in radians.
%
% REQUIRED INPUTS:
%   itds                            - NxM matrix of ITDs, where N is the
%                                     number of frames and M is the number
%                                     of filterbank channels.
%   ilds                            - NxM matrix of ILDs, where N is the
%                                     number of frames and M is the number
%                                     of filterbank channels.
%   azimuth                         - Azimuth angle in radians.
%
% OUTPUTS:
%   likelihood                      - NxM matrix containing the observation
%                                     likelihoods at all time-frequency
%                                     bins.
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
try
    validateattributes( itds, {'numeric'}, {'real', '2d'} );
catch ME
    error( 'ObservationModel.computeLikelihood needs numeric real 2d input for itds.' );
end
try
    validateattributes( ilds, {'numeric'}, {'real', '2d'} )
catch ME
    error( 'ObservationModel.computeLikelihood needs numeric real 2d input for ilds.' );
end
try
    validateattributes( azimuth, {'numeric'}, {'real', '>=', -pi, '<=', pi, 'vector'} )
catch ME
    error( 'ObservationModel.computeLikelihood needs numeric real input between -pi and pi for azimuth.' );
end

% Check if sizes of binaural features match.
if any( size( itds ) ~= size( ilds ) )
    error('Dimensions of binaural features do not match.');
end

% Get number of channels.
[numSamples,numChannels] = size( itds );

% Initialize likelihoods.
likelihood = zeros( numSamples, numChannels, numel( azimuth ) );

binauralFeatures = permute( cat( 3, itds, ilds ), [1,3,2] );

dm = obj.computeDataMatrix( azimuth, ...
                            obj.trainingParameters.models.model_order );
for channelIdx = 1 : numChannels
    % Compute model predicition.
    modelPrediction = dm * obj.modelParameters(channelIdx).beta;
    
    % Get likelihood.
    for azimuthIdx = 1 : numel( azimuth )
        likelihood(:,channelIdx,azimuthIdx) = mvnpdf( ...
                   binauralFeatures(:,:,channelIdx), ...
                   modelPrediction(azimuthIdx,:), obj.modelParameters(channelIdx).sigma );
    end
end

end