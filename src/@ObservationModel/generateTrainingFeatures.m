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
    numLoops = length( obj.trainingParameters.simulator.impulse_responses ) * 100 * numLevels;
else
    % Set MCT levels to 'Inf' only.
    mctLevels = {'Inf'};
    
    numLoops = length( obj.trainingParameters.simulator.impulse_responses ) * 100;
end
loopCounter = 1;

% Initialize matrices for accumulating features and target azimuths. These
% matrices can get quite big, so they are pre-allocated here. 
overlap = obj.trainingParameters.features.win_size - ...
    obj.trainingParameters.features.hop_size;
numFrames = floor( (5 - overlap) / obj.trainingParameters.features.hop_size );
numChannels = obj.trainingParameters.features.fb_num_channels;

itds = cell( numel( obj.trainingParameters.simulator.impulse_responses ), 1 );
ilds = cell( numel( obj.trainingParameters.simulator.impulse_responses ), 1 );
targetAzimuths = cell( numel( obj.trainingParameters.simulator.impulse_responses ), 1 );

% Initialize the progress bar.
display.progressBar( true, 'Extracting features...' );

% Generate binaural features using the generated training signals. If 
% corresponding signals have already been generated, the auralization is
% skipped automatically.
iridx = 0;
for irSet = obj.trainingParameters.simulator.impulse_responses
    iridx = iridx + 1;
    % Get name of impulse response set.
    [~, irName] = fileparts( irSet{:} );
    
    % determine available azimuths
    warning( 'off', 'all' );
    brirFile = db.getFile( irSet{:} );
    srcPosition = sofa.getLoudspeakerPositions(brirFile, 1, 'cartesian');
    listenerPosition = sofa.getListenerPositions(brirFile, 1, 'cartesian');
    brirSrcOrientation = SOFAconvertCoordinates(...
        srcPosition - listenerPosition, 'cartesian', 'spherical');
    [~, listenerIdxs] = sofa.getListenerPositions(brirFile, 1, 'cartesian');
    availableHeadOrientations = sofa.getHeadOrientations(brirFile, listenerIdxs);
    availableHeadOrientations = wrapTo360( availableHeadOrientations );
    availableAzimuths = wrapTo180( brirSrcOrientation(1) - availableHeadOrientations );
    warning( 'on', 'all' );

    N = numel( availableAzimuths ) * numel( mctLevels );
    itds{iridx} = zeros( N * numFrames, numChannels );
    ilds{iridx} = zeros( N * numFrames, numChannels );
    targetAzimuths{iridx} = zeros( N * numFrames, 1 );
    curIdx = 1;
    
    for mctLevel = mctLevels
        % Check if multi-conditional training is necessary.
        if ~(ischar( mctLevel{:} ) && strcmpi( mctLevel{:}, 'inf' ))
            % For the moment, always use diffuse noise from anechoic KEMAR
            % 3m generation (diffuse noise should not be processed with
            % reverberation, since this will make it directional again.
            diffuseNoiseSignal = audioread( fullfile(obj.signalPath, ...
                'QU_KEMAR_anechoic_3m_diffuse.wav' ) );
        end
        
        % Loop over all specified azimuth angles. All angles that are not
        % covered by the azimuth increment are skipped here. It is possible to
        % generate them later by changing the increment parameter in the
        % training configuration file.
        for azimuth = availableAzimuths'
            % Update progress bar.
            display.progressBar( false, 'Extracting features...', ...
                round( loopCounter ), numLoops );
            
            % Get feature file name.
            fileName = obj.getFeatureFileName( irName, round( azimuth ), mctLevel{:} );
            
            if ~exist( fullfile(obj.featurePath, fileName), 'file' )                
                % Get file name for current settings.
                dataFileName = obj.getDataFileName( irName, round( azimuth ) );
                
                % Load corresponding audio file and (optionally) add diffuse
                % noise. The spatialized binaural signals are also truncated to
                % a fixed length of one second here.
                [earSignals, signalSamplingRate] = ...
                    audioread( fullfile(obj.signalPath, dataFileName) );
%                 earSignals = earSignals( 1 : signalSamplingRate, : );
                
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
            itds{iridx}(curIdx:curIdx+numFrames-1,:) = features.itds;
            ilds{iridx}(curIdx:curIdx+numFrames-1,:) = features.ilds;
            targetAzimuths{iridx}(curIdx:curIdx+numFrames-1) = ...
                repmat( features.azimuth ./ 180 .* pi, numFrames, 1 );
            
            loopCounter = loopCounter + 100 / numel( availableAzimuths );
            curIdx = curIdx + numFrames;
        end
    end
end

itds = cat( 1, itds{:} );
ilds = cat( 1, ilds{:} );
targetAzimuths = cat( 1, targetAzimuths{:} );

% Exit feature extraction framework.
display.sectionFooter();

end