classdef ObservationModel
    % OBSERVATIONMODEL This class represents an observation model for
    %   binaural cues at specific center frequencies of the filterbank. It
    %   models interaural time- and level-differences (ITD and ILD)
    %   expected for all possible azimuth angles. A simple regression model
    %   with additive, zero-mean Gaussian noise is used for this purpose.
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
    
    properties ( GetAccess = public, SetAccess = private )
        modelOrder              % Order of the regression model.
        regressionCoeffs        % Coefficients of the regression functions,
                                % represented as a [2xM+1] matrix, where M
                                % is the model order.
        noiseCovariance         % [2x2] noise covariance matrix.
    end
    
    properties ( Access = private )
        basePath                % Path to folder where all files related to
                                % observation model training should be
                                % stored.
        signalPath              % Path where all training audio files will
                                % be stored.
        featurePath             % Path where all training features will be 
                                % stored.
        trainingParameters      % Struct-variable, containing all
                                % parameters used for training.
        trainingLog             % Struct-variable, containing all 
                                % information gathered during training. It
                                % contains the fields 'logLikelihood',
                                % 'BIC', 'modelOrder' and 'rmse',
                                % representing the log-likelihood, Bayesian
                                % information criterion, model order and
                                % the root-mean-squared error achieved
                                % during training.
    end
    
    methods ( Static, Hidden )
        fileName = getDataFileName( impulseResponseName, azimuth )
        
        fileName = getFeatureFileName( impulseResponseName, azimuth, mctLevel )
        
        noisySignal = addDiffuseNoise( earSignals, diffuseNoiseSignal, ...
            desiredSNR)
    end
    
    methods ( Access = public )
        function obj = ObservationModel( trainingParameters )
            % OBSERVATIONMODEL An instance of this class can be created
            %   either 'empty' or with pre-specified parameters.
            %
            % REQUIRED INPUTS:
            %   trainingParameters  - Parameter structure, which is created
            %                         by the SegmentationTrainer class.
            
            % Check input arguments.
            p = inputParser();
            
            p.addRequired( 'TrainingParameters', @isstruct );
            p.parse( trainingParameters );
            
            % Add parameters to class properties and check if a
            % corresponding model has already been trained. If not,
            % training is started automatically.
            obj.trainingParameters = p.Results.TrainingParameters;
            
            % Get base path where all feature extraction-related files
            % should be stored.
            obj.basePath = fullfile( xml.dbTmp, 'learned_models', ...
                'SegmentationKS' );
            
            % Initialize all additional paths for storing temporary data
            % used for training.
            obj.signalPath = fullfile( obj.basePath, 'train_signals' );
            
            featureHash = DataHash( obj.trainingParameters.simulator, ...
                obj.trainingParameters.features );
            obj.featurePath = fullfile( obj.basePath, 'train_features', ...
                featureHash);
            
            obj.generateTrainingSignals();
            obj.generateTrainingFeatures();
        end
        
        function train( obj )
            % TRAIN Runs model training according to the specified training
            %   parameters.
        end
    end
    
    methods ( Access = private )
        generateTrainingSignals( obj )
        
        generateTrainingFeatures( obj )
    end
end