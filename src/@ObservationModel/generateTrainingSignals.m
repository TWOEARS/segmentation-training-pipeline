function generateTrainingSignals( obj )
% GENERATETRAININGSIGNALS This function generates binaural signals to be
%   used for training, according to the specified training parameters. The
%   binaural signals are stored as *.wav-files in the data directory of the
%   Two!Ears framework.
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

display.sectionHeader( 'ObservationModel::Training::DataGeneration' );

% Assemble path where binaural signals used for training should be stored.
% If the corresponding folder does not exist yet, it will be created
% automatically.
if ~exist( obj.signalPath, 'dir' )
    mkdir( obj.signalPath );
end

% Get azimuth increment from training parameters. To simplify the data
% generation, the azimuth increment is forced to be a whole number. Real
% numbers will be automatically rounded towards the nearest integer.
azimuthIncrement = max( ...
    round(obj.trainingParameters.simulator.azimuth_increment), 1 );

display.subsection( 'Initializing binaural simulator...' );

% Initialize the binaural simulator and fix all simulation parameters that
% will not change during data generation.
sim = simulator.SimulatorConvexRoom();

if strcmpi( obj.trainingParameters.simulator.sim, 'ssr_binaural' )
    renderer = @ssr_binaural;
elseif strcmpi( obj.trainingParameters.simulator.sim, 'ssr_brs' )
    renderer = @ssr_brs;
else
    error( 'Unknown renderer chosen.' );
end

sim.set( ...
    'Renderer', renderer, ...  % Renderer for binaural HRIRs
    'MaximumDelay', 0.05, ...
    'PreDelay', 0.0, ...    
    'LengthOfSimulation', 5, ...    % Fixed to five seconds here.
    'Sources', {simulator.source.Point()}, ...
    'Sinks', simulator.AudioSink(2), ...
    'Verbose', false );

sim.Sources{1}.set( ...
    'Name', 'WhiteNoisePoint', ...
    'AudioBuffer', simulator.buffer.Noise, ...
    'Volume', 1 );

sim.Sinks.set( ...
    'Position', [0; 0; 1.75], ...   % Cartesian position of the dummy head
    'Name', 'DummyHead' );          % Identifier of the audio sink.

% Initialize the progress bar.
display.progressBar( true, 'Rendering signals...' );
% Get total number of loops for displaying the progress bar and initialize
% the loop counter.
numLoops = length( obj.trainingParameters.simulator.impulse_responses ) * 100;
loopCounter = 1;


% Generate binaural signals using white noise stimuli for all specified
% impulse responses. If corresponding signals have already been generated,
% the auralization is skipped automatically.
for irSet = obj.trainingParameters.simulator.impulse_responses
    % Get name of impulse response set.
    [~, irName] = fileparts( irSet{:} );
    
    % Add impulse response set to binaural simulator settings and suppress 
    % warnings that can occur during initialization.
    warning( 'off', 'all' );
    sim.Sources{1}.IRDataset = simulator.DirectionalIR( irSet{:}, 1 );
    
    % Check if specified sampling rate matches the sampling rate of the
    % impulse responses.
    sim.set( 'SampleRate', sim.Sources{1}.IRDataset.SampleRate );

    sim.init();

    % Initialize diffuse noise signal for current set of impulse responses.
    diffuseNoiseSignal = zeros( sim.SampleRate, 2 );    
    
    % determine available azimuths
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
            
    % Loop over all specified azimuth angles. All angles that are not
    % covered by the azimuth increment are skipped here. It is possible to
    % generate them later by changing the increment parameter in the
    % training configuration file.
    for azm_ho = [availableAzimuths,availableHeadOrientations]'
        % Get file name for current settings and check if file has already
        % been created. If not, the auralization process is started
        % automatically.
        fileName = obj.getDataFileName( irName, round( azm_ho(1) ) );
        
        % Update progress bar.
        display.progressBar( false, 'Rendering signals...', round( loopCounter ), numLoops );
        loopCounter = loopCounter + 100 / numel( availableAzimuths );
        
        if ~exist( fullfile(obj.signalPath, fileName), 'file' )
            % Set head orientation in binaural simulator and re-initialize
            % the simulation framework.
            [crp(1),crp(2)] = sim.getCurrentRobotPosition();
            [~,~,brirTorsoDefault] = sim.Sources{1}.getHeadLimits();
            sim.moveRobot( crp(1), crp(2), brirTorsoDefault, 'absolute' );
            % 'absolute' mode means: relative wrt torso...
            headToTorsoAzm = mod( azm_ho(2), 360 ) - mod( brirTorsoDefault, 360 );
            sim.rotateHead( round( headToTorsoAzm ), 'absolute' );
            sim.init();
            
            % Get the processed ear signals, normalize to prevent clipping
            % and save them in a *.wav-file.
            earSignals = double( sim.getSignal() );
            earSignals = earSignals ./ max( abs(earSignals(:)) );
            audiowrite( fullfile(obj.signalPath, fileName), earSignals, sim.SampleRate );
        elseif ~exist( fullfile(obj.signalPath, [irName, '_diffuse.wav']), 'file' )
            % Read audio signal for computation of white noise signal.
            earSignals = audioread( fullfile(obj.signalPath, fileName) );
            % Append current directional signal to diffuse noise signal.
            diffuseNoiseSignal = diffuseNoiseSignal + earSignals( 1 : sim.SampleRate, : );
        end
    end
    
    if ~exist( fullfile(obj.signalPath, [irName, '_diffuse.wav']), 'file' )
        % Normalize diffuse noise signal and save it in separate file.
        diffuseNoiseSignal = diffuseNoiseSignal ./ numel( availableAzimuths );
        audiowrite( fullfile(obj.signalPath, [irName, '_diffuse.wav']), ...
            diffuseNoiseSignal, sim.SampleRate );
    end
end

% Shut-down simulator and exit data generation framework
sim.set( 'ShutDown', true );
display.sectionFooter();

end