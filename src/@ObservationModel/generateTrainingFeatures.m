function [itds, ilds, targetAzimuths, centerFrequencies] = ...
    generateTrainingFeatures( obj )
% GENERATETRAININGFEATURES This function generates binaural features to be
%   used for training, according to the specified training parameters. The
%   features are stored as *.mat-files in the data directory of the
%   Two!Ears framework.
%
% OUTPUTS:
%   itds                            - Matrix of interaurl-time-differences
%                                     to be used for training.
%   ilds                            - Matrix of
%                                     interaural-level-differences to be
%                                     used for training.
%   targetAzimuths                  - Vector of corresponding target
%                                     azimuth values in radians.
%   centerFrequencies               - Center frequencies of the filterbank
%                                     in Hz.
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

display.sectionHeader( 'ObservationModel::Training::FeatureExtraction' );

% If the corresponding folder does not exist yet, it will be created 
% automatically.
if ~exist( obj.featurePath, 'dir' )
    mkdir( obj.featurePath );
end

% Get azimuth increment from training parameters. To simplify the data
% generation, the azimuth increment is forced to be a whole number. Real
% numbers will be automatically rounded towards the nearest integer.
azimuthIncrement = max( ...
    round(obj.trainingParameters.simulator.azimuth_increment), 1 );

% Initialize the Auditory Front-End and get center frequencies.
[dataObj, managerObj] = tools.setupAuditoryFrontend( obj.trainingParameters );
centerFrequencies = dataObj.filterbank{1}.cfHz;

% Get total number of loops for displaying the progress bar and initialize
% the loop counter. This if-clause is additionally used to initialize the
% MCT-level variable for the corresponding loop.
if obj.trainingParameters.features.use_mct
    % Get desired MCT levels.
    mctLevels = obj.trainingParameters.features.mct_levels;
    numLevels = length( mctLevels );
    
    numLoops = length( obj.trainingParameters.simulator.impulse_responses ) * ...
        ( 360 / azimuthIncrement ) * numLevels;
else
    % Set MCT levels to 'Inf' only.
    mctLevels = {'Inf'};
    
    numLoops = length( obj.trainingParameters.simulator.impulse_responses ) * ...
        ( 360 / azimuthIncrement );
end
loopCounter = 1;

% Initialize matrices for accumulating features and target azimuths. These
% matrices can get quite big, so they are pre-allocated here. 
overlap = obj.trainingParameters.features.win_size - ...
    obj.trainingParameters.features.hop_size;
numFrames = floor( (1 - overlap) / obj.trainingParameters.features.hop_size );

numChannels = obj.trainingParameters.features.fb_num_channels;

itds = zeros( numLoops * numFrames, numChannels );
ilds = zeros( numLoops * numFrames, numChannels );
targetAzimuths = zeros( numLoops * numFrames, 1 );

% Initialize the progress bar.
display.progressBar( true, 'Extracting features...' );

% Generate binaural features using the generated training signals. If 
% corresponding signals have already been generated, the auralization is
% skipped automatically.
for irSet = obj.trainingParameters.simulator.impulse_responses
    % Get name of impulse response set.
    [~, irName] = fileparts( irSet{:} );
    for mctLevel = mctLevels
        % Check if multi-conditional training is necessary.
        if ~(ischar( mctLevel{:} ) && strcmpi( mctLevel{:}, 'inf' ))
            % Load diffuse noise file for coresponding HRIR set.
            diffuseNoiseSignal = audioread( fullfile(obj.signalPath, ...
                [irName, '_diffuse.wav']) );
        end
        
        % Loop over all specified azimuth angles. All angles that are not
        % covered by the azimuth increment are skipped here. It is possible to
        % generate them later by changing the increment parameter in the
        % training configuration file.
        for azimuth = -180 : azimuthIncrement : 180 - azimuthIncrement
            % Update progress bar.
            display.progressBar( false, 'Extracting features...', ...
                loopCounter, numLoops );
            
            % Get feature file name.
            fileName = obj.getFeatureFileName( irName, azimuth, mctLevel{:} );
            
            if ~exist( fullfile(obj.featurePath, fileName), 'file' )                
                % Get file name for current settings.
                dataFileName = obj.getDataFileName( irName, azimuth );
                
                % Load corresponding audio file and (optionally) add diffuse
                % noise. The spatialized binaural signals are also truncated to
                % a fixed length of one second here.
                [earSignals, signalSamplingRate] = ...
                    audioread( fullfile(obj.signalPath, dataFileName) );
                earSignals = earSignals( 1 : signalSamplingRate, : );
                
                if ~(ischar( mctLevel{:} ) && strcmpi( mctLevel{:}, 'inf' ))
                    earSignals = obj.addDiffuseNoise( earSignals, ...
                        diffuseNoiseSignal, mctLevel{:} );
                end
                
                % Resample ear signals.
                earSignals = [ ...
                    resample( earSignals(:, 1), ...
                    obj.trainingParameters.simulator.fs, signalSamplingRate ), ...
                    resample( earSignals(:, 2), ...
                    obj.trainingParameters.simulator.fs, signalSamplingRate )];
                
                % Perform feature extraction and get all binaural cues
                % available.
                managerObj.processSignal( earSignals );
                
                % Assemble data structure to save features.
                features.itds = dataObj.itd{1}.Data(:);
                features.ilds = dataObj.ild{1}.Data(:);
                features.impulseResponses = irName;
                features.azimuth = azimuth;
                features.mctLevel = mctLevel{:};
                features.filterbank = dataObj.filterbank{1}.Name;
                features.centerFrequencies = dataObj.filterbank{1}.cfHz;
                
                % Save extracted features as *.mat-file.
                save( fullfile(obj.featurePath, fileName), 'features', ...
                    '-v7.3' );
            else
                % Load generated feature file.
                file = load( fullfile(obj.featurePath, fileName) );
                features = file.features;
            end
            
            % Accumulate features. Azimuths are converted from degrees to
            % radians here, to comply with the model.
            startIdx = (loopCounter - 1) * numFrames + 1;
            endIdx = startIdx + numFrames - 1;
            itds( startIdx : endIdx, : ) = features.itds;
            ilds( startIdx : endIdx, : ) = features.ilds;
            targetAzimuths( startIdx : endIdx ) = ...
                repmat( features.azimuth, numFrames, 1 ) ./ 180 .* pi;
            
            loopCounter = loopCounter + 1;            
        end
    end
end

% Exit feature extraction framework.
display.sectionFooter();

end