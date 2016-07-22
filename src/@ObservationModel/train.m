function modelParameters = train( obj )
% TRAIN Runs model training according to the specified training parameters.
%
% OUTPUTS:
%   modelParameters                 - Struct, containing trained models
%                                     for all center-frequencies.
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

% Run data generation scripts to create training files. If files matching 
% the current parameters have already been created, the data generation 
% steps will be skipped.
obj.generateTrainingSignals();
[itds, ilds, targetAzimuths, centerFrequencies] = obj.generateTrainingFeatures();

% Get unique target azimuth angles.
uniqueAzimuths = unique( targetAzimuths );
numUniqueAzimuths = length( uniqueAzimuths );

display.sectionHeader( 'ObservationModel::Training::Regression' );
display.progressBar( true, 'Training models...' );

% Initialize models for all center frequencies and compute data matrix for
% provided azimuth angles.
numChannels = obj.trainingParameters.features.fb_num_channels;
modelParameters = struct;
dataMatrix = obj.computeDataMatrix( targetAzimuths, ...
    obj.trainingParameters.models.model_order );

for channelIdx = 1 : numChannels
    display.progressBar( false, 'Training models...', channelIdx, ...
        numChannels );
    
    % Get binaural features for current channel and perform regression
    % model training.
    binauralFeatures = [itds( :, channelIdx ), ilds( :, channelIdx )];
    [beta, sigma, residuals, ~, logLikelihood] = mvregress( dataMatrix, ...
        binauralFeatures );
    
    % Accumulate statistics for all azimuth angles.
    measuredItdMean = zeros( numUniqueAzimuths, 1 );
    measuredItdStd = zeros( numUniqueAzimuths, 1 );
    measuredIldMean = zeros( numUniqueAzimuths, 1 );
    measuredIldStd = zeros( numUniqueAzimuths, 1 );
    for azimuthIdx = 1 : numUniqueAzimuths
        % Get corresponding binaural features for current azimuth.
        idx = ( targetAzimuths == uniqueAzimuths(azimuthIdx) );
        featureSubset = binauralFeatures( idx, : );
        
        measuredItdMean( azimuthIdx ) = mean( featureSubset(:, 1) );
        measuredItdStd( azimuthIdx ) = std( featureSubset(:, 1) );
        measuredIldMean( azimuthIdx ) = mean( featureSubset(:, 2) );
        measuredIldStd( azimuthIdx ) = std( featureSubset(:, 2) );
    end
    
    % Assemble model parameters.
    modelParameters( channelIdx ).beta = beta;
    modelParameters( channelIdx ).sigma = sigma;
    modelParameters( channelIdx ).logLikelihood = logLikelihood;
    modelParameters( channelIdx ).rmseITD = sqrt( mean(residuals(:, 1).^2) );
    modelParameters( channelIdx ).rmseILD = sqrt( mean(residuals(:, 2).^2) );
    modelParameters( channelIdx ).centerFrequency = centerFrequencies( channelIdx );
    modelParameters( channelIdx ).measuredItdMean = measuredItdMean;
    modelParameters( channelIdx ).measuredItdStd = measuredItdStd;
    modelParameters( channelIdx ).measuredIldMean = measuredIldMean;
    modelParameters( channelIdx ).measuredIldStd = measuredIldStd;
    modelParameters( channelIdx ).uniqueAzimuths = uniqueAzimuths;
end

display.sectionFooter();

end