close all;
clear all;

% Read in the synthetic dataset
% dim = 2;
% eps = 1.0;

% dim = 5;
% eps = 4.5;

% dim = 10;
%eps = 7.2;

% dim = 20;
%eps = 11;

% dim = 30;
% eps = 13.5;

% dim = 50;
% eps = 18;

% dim = 100;
% eps = 24;

load(sprintf('%d-dim-syntheticData.mat', dim));

X = Xs(:, :, 1);
X = X;

%% find eps
%{
[id_nns, D] = knnsearch(X, X, 'K', 10);

figure(1);
histogram(D(:, 10));
title(sprintf('Distance to 10th NN, d = %d', dim));
xlabel('distance');                  
ylabel('num of points');
print('-f1', sprintf('part2-synData/dim%d_dis2NN_hist', dim), '-dpng');
close all;
%}

%%
% find DSCAN outliers' ids
[clustLabel, varType] = dbscan(X, 10, eps);

% compute hubness score of each point
id_nns = knnsearch(X, X, 'K', 10);

id_potential_hubs = unique(id_nns);
occurrences = [id_potential_hubs, histc(id_nns(:), id_potential_hubs)];

if size(id_potential_hubs, 1) ~= size(X, 1)
    printf('size is different !!!!!!\n')
end

% compute average and std of all the hubness scores
avg_hub = mean(occurrences(:, 2));
std_hub = std(occurrences(:, 2));

% find outlier's hubness score
outliers = [];
for i = 1:size(varType, 1)
    if varType(i) == -1
        outliers = [outliers, i];
    end
end

outliers_hub = occurrences(outliers, 2);
sum_smallerThanElse = sum(outliers_hub < (avg_hub - 2 * std_hub));

sprintf('%d outliers are detected from %d points.\n', size(outliers, 2), ...
    size(X, 1))
sprintf('%d outlier hubness satisfies the requirements.\n', sum_smallerThanElse)
