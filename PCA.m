% PCA Analysis on Image Metrics for the Four Lowest Hardness Values
% Date: 10/23/2024

clear all
close all

%% 1. Load and Prepare the Data

% Define the filename
% filename = 'allData_ZScoredNoNaNs.txt';
filename = 'standard_unscored.txt';

% Read the tab-delimited file into a table
data = readtable(filename, 'Delimiter', '\t');

% Extract hardness value from sample
hardness = data.sample;

% Exclude any rows with NaNs in hardness or metrics
valid_idx = ~isnan(hardness);
data = data(valid_idx, :);
hardness = hardness(valid_idx);

% Select only the four lowest unique hardness values
uniqueHardness = unique(hardness);
fourLowestHardness = uniqueHardness(1:5);  % Select the 4 lowest hardness levels

% Filter the dataset to include only these four lowest hardness values
lowHardnessIdx = ismember(hardness, fourLowestHardness);
data = data(lowHardnessIdx, :);
hardness = hardness(lowHardnessIdx);

% Gather relevant metrics into a feature matrix based on the provided header list
metrics = [data.numWhitePixels, data.numBlackPixels, data.ratio, ...
    data.numLargeBlobs, data.perimeterLength, data.axisRatio, ...
    data.countLargeHoles, data.medianLargeHoleAreas, data.maxLargeHoleAreas, ...
    data.meanDistances, data.stdDistances, data.modeDistances, ...
    data.medianDistances, data.skewnessDistances, data.erosionslope, ...
    data.frct01, data.medianEccentricity, data.medianArea, ...
    data.sumEdgesLow, data.sumEdgesHigh, data.areaOverEdgeLow, ...
    data.areaOverEdgeHigh, data.stdRaw, data.areaHigh, data.stdHigh, ...
    data.compactnessCenter, data.brightnessCenter, data.blackCoreFraction, ...
    data.intensityKurtosis, data.intensitySkewness, data.intensityRatio, ...
    data.skeletonLength, data.skeletonBranchPoints, data.skeletonEndPoints, ...
    data.fractalDim, data.log10Entropy, data.waveletEntropy, ...
    data.stdRays, data.lowRays, data.stdMaxRays, data.corrGLCM, ...
    data.energyGLCM, data.meanStd5, data.meanStd25, data.ms25over5, ...
    data.ms100over25, data.numContours];

% Handle any NaN values in metrics
nan_idx = any(isnan(metrics), 2);
metrics = metrics(~nan_idx, :);
hardness = hardness(~nan_idx);
data = data(~nan_idx, :);  % Ensure 'data' is synchronized

% %% 1.1 Remove outliers beyond 3 standard deviations
% % Since the data is z-scored, simply check for values greater than 3 or less than -3
% outlier_idx = any(abs(metrics) > 3, 2); % Find rows where any metric exceeds 3 sigma
% metrics = metrics(~outlier_idx, :);     % Remove outliers
% hardness = hardness(~outlier_idx);      % Remove corresponding hardness values
% data = data(~outlier_idx, :);           % Ensure 'data' is synchronized
% 
% % Count the number of outliers removed
% num_outliers = sum(outlier_idx); % Count the number of outliers

%% 2. Perform PCA

% Standardize the data before performing PCA
[metrics_zscored, mu, sigma] = zscore(metrics);

% Remove outliers beyond 3 standard deviations
outlier_idx = any(abs(metrics_zscored) > 3, 2); % Find rows where any metric exceeds 3 sigma
metrics_zscored = metrics_zscored(~outlier_idx, :);     % Remove outliers
hardness = hardness(~outlier_idx);      % Remove corresponding hardness values
data = data(~outlier_idx, :);           % Ensure 'data' is synchronized

% Count the number of outliers removed
num_outliers = sum(outlier_idx); % Count the number of outliers
fprintf('Number of outliers removed: %d\n', num_outliers);

validCols = ~all(isnan(metrics_zscored),1) & std(metrics_zscored,0,1,'omitnan')>0;
metrics_zscored = metrics_zscored(:, validCols);


% Perform Principal Component Analysis (PCA)
[coeff, score, latent, tsquared, explained] = pca(metrics_zscored);


% The variable "score" contains the data projected onto the principal components
% "coeff" gives the principal component directions

%% 3D PCA scatter plot with proper JET colormap

%% 3D PCA scatter with DARK JET colormap (paper style)

figure;
set(gcf,'Color','w');

% --- Prepare hardness mapping ---
hardnessLevels = unique(hardness);     % your concentration values
nLevels = numel(hardnessLevels);

% Map hardness values → indices
[~, hIdx] = ismember(hardness, hardnessLevels);

% --- Main scatter plot ---
scatter3(score(:,1), score(:,2), score(:,3), ...
         25, hIdx, 'filled');
grid on;
view(-80,10);
hold on;

% --- Projection onto PCA1–PCA2 plane ---
projection_plane = min(score(:,3)) - 2;
scatter3(score(:,1), score(:,2), ...
         projection_plane * ones(size(score,1),1), ...
         15, hIdx, 'filled', 'MarkerFaceAlpha', 0.25);

% --- Darkened JET colormap (paper-like) ---
cmap = jet(nLevels);        % jet colors matched to hardness levels
darkFactor = 0.75;          % adjust 0.65–0.85 if needed
cmap = cmap * darkFactor;
colormap(cmap);
caxis([1 nLevels]);

% --- Colorbar with hardness labels ---
cb = colorbar;
cb.Ticks = 1:nLevels;
cb.TickLabels = arrayfun(@(x) sprintf('%.1f', x), hardnessLevels, ...
                         'UniformOutput', false);
cb.Label.String = 'Hardness (%)';
cb.Label.FontWeight = 'bold';

% --- Axis labels ---
xlabel(sprintf('PC1 (%.1f%%)', explained(1)), ...
       'FontWeight','bold','FontSize',14);
ylabel(sprintf('PC2 (%.1f%%)', explained(2)), ...
       'FontWeight','bold','FontSize',14);
zlabel(sprintf('PC3 (%.1f%%)', explained(3)), ...
       'FontWeight','bold','FontSize',14);

set(gca,'FontSize',12,'LineWidth',1.2);
box on;
hold off;


%% 4. Plot the Cumulative Explained Variance

% Create a new figure for the cumulative explained variance plot
figure;
set(gcf, 'Color', 'w');  % Set a white background

% Plot the cumulative explained variance
cumulativeExplained = cumsum(explained);
plot(cumulativeExplained, 'o-', 'LineWidth', 1.5);
xlabel('Number of Principal Components','FontWeight', 'bold', 'FontSize', 14);
ylabel('Cumulative Explained Variance (%)','FontWeight', 'bold', 'FontSize', 14);
%title('Cumulative Explained Variance by Principal Components');
grid on;

% Annotate each point with the percentage explained
for i = 1:length(explained)
    text(i, cumulativeExplained(i), sprintf('%.1f%%', explained(i)), ...
        'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right');
end

%% Display Summary of Statistics

% Number of metrics (features)
numMetrics = size(metrics, 2);

% Number of samples in the dataset after outlier removal
numTotalSamples = size(metrics, 1);

% Display summary statistics
fprintf('Number of metrics (features): %d\n', numMetrics);
fprintf('Number of total samples: %d\n', numTotalSamples);
% fprintf('Number of rejected outliers (3 sigma): %d\n', num_outliers);

%% Weighted PCA Score per Concentration and Error Bar Plot

% --- Step 1: compute weighted PCA score per sample ---
%% Weighted PCA score using top N PCs (user-specified)
N = 5;  % <-- USER can change this number

% Take only the first N PCs
score_topN = score(:, 1:N);          % [numSamples x N]
explained_topN = explained(1:N);     % % variance explained for top N PCs

% Normalize weights so they sum to 1
weights = explained_topN / sum(explained_topN);

% Compute weighted PCA scalar for each sample
pcaScalar = score_topN * weights;    % [numSamples x 1]

% --- Step 2: map samples to unique concentrations (hardness) ---
[uniqueHardness, ~, idx] = unique(hardness);  % idx = mapping of samples to concentrations

% --- Step 3: compute mean and standard deviation per concentration ---
meanPCA = accumarray(idx, pcaScalar, [], @mean);
stdPCA  = accumarray(idx, pcaScalar, [], @std);

% Ensure all vectors are columns
uniqueHardness = uniqueHardness(:);
meanPCA = meanPCA(:);
stdPCA  = stdPCA(:);

% --- Step 4: plot mean ± std error bars ---
figure;
errorbar(uniqueHardness, meanPCA, stdPCA, 'o-', ...
    'LineWidth', 1.5, 'MarkerSize', 8, 'MarkerFaceColor', [0 0.447 0.741]);

xlabel('Concentration (%)', 'FontWeight','bold','FontSize',12);
ylabel('Weighted PCA Score', 'FontWeight','bold','FontSize',12);
title('Weighted PCA Score vs Concentration', 'FontWeight','bold', 'FontSize',14);
grid off;
box off;



