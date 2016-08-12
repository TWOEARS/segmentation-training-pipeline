function trainingResults( modelParameters )
%SHOWTRAININGLOG Summary of this function goes here
%   Detailed explanation goes here

% Get number of filterbank channels.
numChannels = length( modelParameters );

% Print results
fprintf('%s\t%s\t%s\t%s\t%s\t%s\t%s\n\n', 'Classname', '#Components', ...
    'Cov.Type', '#Iterations', 'Converged', 'Neg.Log-lik', 'BIC');
for modelIdx = 1 : numClasses
    % Get current model
    file = load(fullfile(pathToModelFiles, fileList{modelIdx}));
    
    % Get model parameters
    numComponents = file.model.NumComponents;
    covType = file.model.CovarianceType;
    numIterations = file.model.NumIterations;
    isConverged = file.model.Converged;
    logLik = file.model.NegativeLogLikelihood;
    bic = file.model.BIC;
    
    fprintf('%-12s\t%-12i\t%-12s\t%-12i\t%-12i\t%-12f\t%-12f\n', classNames{modelIdx}, ...
        numComponents, covType, numIterations, isConverged, logLik, bic);
end

end

