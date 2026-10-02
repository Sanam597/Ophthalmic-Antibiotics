% takes results from RODI_MainProcessing_062524.m and joins the 35 different experiments into one txt file with two additional columns specifying salt name and concentration
% 07/12/24

clear all
close all

% List of file names
fileNames = {
    'ciprofloxacinind.txt', 'cipronep-2.txt', 'moxifloxacin-3.txt', 'ocupolD-4.txt', 'ofloxacin-5.txt'
 };

% Initialize an empty table for combined data
combinedData = [];

% Loop through each file and process the data
for k = 1:length(fileNames)
    % Read the current file
    file = fileNames{k};
    data = readtable(file, 'Delimiter', '\t');
    
    % Remove the first-line header if not the first file
    if k > 1
        data = data(2:end, :);
    end
    
    % Exclude rows where 'Quality' column is zero
    data = data(data.Quality ~= 0, :); % This filters rows where 'Quality' column is not zero
    
    % Initialize new columns
    salt = cell(height(data), 1);
    conc = zeros(height(data), 1);
    
    % Process each row
    for i = 1:height(data)
        % Get the string from the first column of the table
        str = data{i, 1}{1};  % Access the first column and ensure it's treated as a string
        
        % Extract the salt name (all characters except the last two)
        salt{i} = str(1:end-2);  
        
        % Extract the last two characters and convert to double
        conc(i) = str2double(str(end-1:end));  
    end
    
    % Add new columns to the table
    data.salt = salt;
    data.conc = conc;
    
    % Rename the columns
    data.Properties.VariableNames{end-1} = 'salt';
    data.Properties.VariableNames{end} = 'conc';
    
    % Rearrange the columns
    data = data(:, [1, 2, end-1, end, 3:end-2]);
    
    % Concatenate with the combined data
    combinedData = [combinedData; data];
end

% Optionally, write the modified table to a new file
writetable(combinedData, 'allData_Unscored_022025.txt', 'Delimiter', '\t');
