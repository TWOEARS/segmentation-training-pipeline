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

sim.set( ...
    'Renderer', @ssr_binaural, ...  % Renderer for binaural HRIRs
    'MaximumDelay', 0.05, ...
    'PreDelay', 0.0, ...    
    'LengthOfSimulation', 1, ...    % Fixed to one second here.
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

% Get total number of loops for displaying the progress bar and initialize
% the loop counter.
numLoops = length( obj.trainingParameters.simulator.impulse_responses ) * ...
    ( 360 / azimuthIncrement );
loopCounter = 1;

% Initialize the progress bar.
display.progressBar( true, 'Rendering signals' );

% Generate binaural signals using white noise stimuli for all specified
% impulse responses. If corresponding signals have already been generated,
% the auralization is skipped automatically.
for irSet = obj.trainingParameters.simulator.impulse_responses
    % Get name of impulse response set.
    [~, irName] = fileparts( irSet{:} );
    
    % Add impulse response set to binaural simulator settings and suppress 
    % warnings that can occur during initialization.
    warning( 'off', 'all' );
    sim.set( 'HRIRDataset', simulator.DirectionalIR(irSet{:}) );
    warning( 'on', 'all' );
    
    % Check if specified sampling rate matches the sampling rate of the
    % impulse responses.
    if obj.trainingParameters.simulator.fs ~= sim.HRIRDataset.SampleRate
        error( 'ObservationModel:generateTrainingData:samplingRateMismatch', ...
            ['The specified sampling rate (', ...
            num2str(obj.trainingParameters.simulator.fs), ') does not ', ...
            'match the sampling rate of the impulse response set (', ...
            num2str(sim.HRIRDataset.SampleRate), ').']);
    else
        sim.set( 'SampleRate', obj.trainingParameters.simulator.fs );
    end
    
    % Initialize diffuse noise signal for current set of impulse responses.
    diffuseNoiseSignal = zeros( sim.SampleRate, 2 );    
    
    % Loop over all specified azimuth angles. All angles that are not
    % covered by the azimuth increment are skipped here. It is possible to
    % generate them later by changing the increment parameter in the
    % training configuration file.
    for azimuth = -180 : azimuthIncrement : 180 - azimuthIncrement
        % Get file name for current settings and check if file has already
        % been created. If not, the auralization process is started
        % automatically.
        fileName = obj.getDataFileName( irName, azimuth );
        
        % Update progress bar.
        display.progressBar( false, 'Rendering signals', loopCounter, numLoops );
        loopCounter = loopCounter + 1;
        
        if ~exist( fullfile(obj.signalPath, fileName), 'file' )
            % Set source position in binaural simulator and re-initialize
            % the simulation framework.
            sim.Sources{1}.set( ...
                'Position', [cosd(azimuth); sind(azimuth); 1.75] );
            sim.init();
            
            % Get the processed ear signals, normalize to prevent clipping
            % and save them in a *.wav-file.
            earSignals = double( sim.getSignal() );
            if max( abs(earSignals(:)) ) > 1
                earSignals = earSignals ./ max( abs(earSignals(:)) );
            end            
            audiowrite( fullfile(obj.signalPath, fileName), earSignals, ...
                sim.SampleRate );
        else
            % Read audio signal for computation of white noise signal.
            earSignals = audioread( fullfile(obj.signalPath, fileName) );
        end
        
        % Append current directional signal to diffuse noise signal.
        diffuseNoiseSignal = diffuseNoiseSignal + ...
            earSignals( 1 : sim.SampleRate, : );
    end
    
    % Normalize diffuse noise signal and save it in separate file.
    diffuseNoiseSignal = diffuseNoiseSignal ./ ( 360 / azimuthIncrement );
    if ~exist( fullfile(obj.signalPath, [irName, '_diffuse.wav']), 'file' )
        audiowrite( fullfile(obj.signalPath, [irName, '_diffuse.wav']), ...
            diffuseNoiseSignal, sim.SampleRate );
    end
end

% Shut-down simulator and exit data generation framework
sim.set( 'ShutDown', true );
display.sectionFooter();

end