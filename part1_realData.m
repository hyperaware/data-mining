close all;
clear all;

%% run K-Means
%{
% Read in the synthetic dataset

% dim = 4;
% k = 3;
% dataset_name = 'iris';

% dim = 8;
% k = 8;
% dataset_name = 'abalone';

% dim = 32;
% k = 2;
% dataset_name = 'wpbc';

% dim = 60;
% k = 2;
% dataset_name = 'sonar';

dim = 100;
k = 2;
dataset_name = 'hill';

load(sprintf('%s_data.mat', dataset_name));

mat_dis2medoid_all = [];
mat_dis2strongestHub_all = [];
mat_avgIntraDis_all = [];
mat_count_iter = [];

% run on the same data 10 times
for m = 1:10
    
    X_trans = X(:, :);
    X = X_trans';
    
    L = [];
    L1 = 0;
    
    count_iter = 0;
    max_iter = 50;
    
    mat_dis2medoid = zeros(k, max_iter);
    mat_dis2strongestHub = zeros(k, max_iter);
    mat_avgIntraDis = zeros(k, max_iter);
    
    while length(unique(L)) ~= k
        
        % The k-means++ initialization.
        C = X(:, 1 + round(rand * (size(X, 2) - 1)));
        L = ones(1, size(X, 2));
        for i = 2:k
            % deduct each data point with the cluster C
            D = X-C(:,L);
            D = cumsum(sqrt(dot(D,D,1)));
            if D(end) == 0, C(:,i:k) = X(:,ones(1,k-i+1)); return; end
            C(:,i) = X(:,find(rand < D/D(end),1));
            [~,L] = max(bsxfun(@minus,2*real(C'*X),dot(C,C,1).'));
        end
        t = 0;
        % The k-means algorithm.
        
        while count_iter < 50 % start another iteration when the labels get updated
            L1 = L;
            % compute the new kernels C
            for i = 1:k, l = L==i; C(:,i) = sum(X(:,l),2)/sum(l); end
            % update the lable L of each instance in X
            [~,L] = max(bsxfun(@minus,2*real(C'*X),dot(C,C,1).'),[],1);
            
            % traverse each cluster and compute the distance to the medoid and
            % strongest hub
            for i = 1:k
                % find point in X belongs to this cluster k
                cluster = X(:, L == i)';
                centroid = C(:, i)';
                
                if size(cluster, 1) > 0
                    
                    % compute the average intraclass distance
                    dis_to_centroid = pdist2(cluster, centroid);
                    avg_intra_class_dis = sum(dis_to_centroid) / size(cluster, 1);
                    
                    % find the medoid and its distance to the centroid
                    dis_to_medoid = min(dis_to_centroid);
                    
                    % find the strongest hub and its distance to the centroid
                    id_nns = knnsearch(cluster, cluster, 'K', 10);
                    
                    id_potential_hubs = unique(id_nns);
                    occurrences = [id_potential_hubs, histc(id_nns(:), id_potential_hubs)];
                    
                    [~, I] = max(occurrences(:, 2));
                    id_strongest_hub = occurrences(I, 1);
                    
                    dis_strongest_hub = dis_to_centroid(id_strongest_hub);
                    
                    mat_dis2medoid(i, count_iter + 1) = dis_to_medoid;
                    mat_dis2strongestHub(i, count_iter + 1) = dis_strongest_hub;
                    mat_avgIntraDis(i, count_iter + 1) = avg_intra_class_dis;
                else
                    mat_dis2medoid(i, count_iter + 1) = 0.0;
                    mat_dis2strongestHub(i, count_iter + 1) = 0.0;
                    mat_avgIntraDis(i, count_iter + 1) = 0.0;
                end
                
            end
            
            count_iter = count_iter + 1;
            if count_iter >= max_iter
                break;
            end
        end
    end
    mat_dis2medoid_all = cat(3, mat_dis2medoid_all, mat_dis2medoid);
    mat_dis2strongestHub_all = cat(3, mat_dis2strongestHub_all, mat_dis2strongestHub);
    mat_avgIntraDis_all = cat(3, mat_avgIntraDis_all, mat_avgIntraDis);
    mat_count_iter = [mat_count_iter, count_iter];
end

save(sprintf('%d-dim-%s-realData-medoid-hub-dis.mat', dim, dataset_name), 'mat_dis2medoid_all', ...
    'mat_dis2strongestHub_all', 'mat_avgIntraDis_all', 'mat_count_iter');
%}
%%
%%{
% dim = 4;
% k = 3;
% dataset_name = 'iris';

% dim = 8;
% k = 8;
% dataset_name = 'abalone';

% dim = 32;
% k = 2;
% dataset_name = 'wpbc';

% dim = 60;
% k = 2;
% dataset_name = 'sonar';

dim = 100;
k = 2;
dataset_name = 'hill';
load(sprintf('%d-dim-%s-realData-medoid-hub-dis.mat', dim, dataset_name));

num_runs = size(mat_count_iter, 2);
count_iter = mat_count_iter(1);
% scale dis by intracluster distance
min_dis2medoid_overIntraDis = zeros(num_runs, count_iter);
min_dis2strongestHub_overIntraDis = zeros(num_runs, count_iter);
max_dis2medoid_overIntraDis = zeros(num_runs, count_iter);
max_dis2strongestHub_overIntraDis = zeros(num_runs, count_iter);

for run_index = 1:num_runs
    %run_index = 1; % each model has 10 runs
    count_iter = mat_count_iter(run_index);
    mat_avgIntraDis = mat_avgIntraDis_all(:, : , run_index);
    mat_dis2medoid = mat_dis2medoid_all(:, :, run_index);
    mat_dis2strongestHub = mat_dis2strongestHub_all(:, :, run_index);
    
    [min_dis2medoid, min_index] = min(mat_dis2medoid(:, 1:count_iter));
    [max_dis2medoid, max_index] = max(mat_dis2medoid(:, 1:count_iter));
    %[min_dis2strongestHub
    
    for i = 1:count_iter
        min_avgIntraDis = mat_avgIntraDis(min_index(i), i);
        max_avgIntraDis = mat_avgIntraDis(max_index(i), i);
        
        min_dis2strongestHub = mat_dis2strongestHub(min_index(i), i);
        max_dis2strongestHub = mat_dis2strongestHub(max_index(i), i);
        
        min_dis2medoid_overIntraDis(run_index, i) = min_dis2medoid(i) / (min_avgIntraDis + eps);
        min_dis2strongestHub_overIntraDis(run_index, i) = min_dis2strongestHub / (min_avgIntraDis + eps);
        max_dis2medoid_overIntraDis(run_index, i) = max_dis2medoid(i) / (max_avgIntraDis + eps);
        max_dis2strongestHub_overIntraDis(run_index, i) = max_dis2strongestHub / (max_avgIntraDis + eps);
    end
end

avg_min_dis2medoid_overIntraDis = mean(min_dis2medoid_overIntraDis);
avg_min_dis2strongestHub_overIntraDis = mean(min_dis2strongestHub_overIntraDis);
avg_max_dis2medoid_overIntraDis = mean(max_dis2medoid_overIntraDis);
avg_max_dis2strongestHub_overIntraDis = mean(max_dis2strongestHub_overIntraDis);

%draw the minimal and maxmial images
figure(1);
hold on;
plot(avg_min_dis2medoid_overIntraDis, 'r--o');
plot(avg_min_dis2strongestHub_overIntraDis, 'b--*');
title(sprintf('Minimal Distance, d = %d', dim));             % add a title
xlabel('iteration');                  % label the horizontal axis
ylabel('distance');                    % label the vertical axis
%axis([0,51,0,2]);                                % set the axis range
grid on;                                           % add grid lines
legend('dis2medoid', 'dis2strongestHub');
print('-f1', sprintf('part1-realData/dim%d_%sDataset_min', dim, dataset_name), '-dpng');

figure(2);
hold on;
plot(avg_max_dis2medoid_overIntraDis, 'r--o');
plot(avg_max_dis2strongestHub_overIntraDis, 'b--*');
title(sprintf('Maximal Distance, d = %d', dim));             % add a title
xlabel('iteration');                  % label the horizontal axis
ylabel('distance');                    % label the vertical axis
%axis([0,51,0,2]);                                % set the axis range
grid on;                                           % add grid lines
legend('dis2medoid', 'dis2strongestHub');
print('-f2', sprintf('part1-realData/dim%d_%sDataset_max', dim, dataset_name), '-dpng');
close all;


%}

%{
figure(1);
hold on;
plot(min_dis2medoid_overIntraDis);
plot(min_dis2strongestHub_overIntraDis);
title(sprintf('Minimal Distances, d = %d', 2));             % add a title
xlabel('iteration');                  % label the horizontal axis
ylabel('distance');                    % label the vertical axis
axis([0,51,0,2]);                                % set the axis range
grid on;                                           % add grid lines
legend('dis2medoid', 'dis2strongestHub');

figure(2);
hold on;
plot(max_dis2medoid_overIntraDis);
plot(max_dis2strongestHub_overIntraDis);
title(sprintf('Maximal Distances, d = %d', 2));             % add a title
xlabel('iteration');                  % label the horizontal axis
ylabel('distance');                    % label the vertical axis
axis([0,51,0,2]);                                % set the axis range
grid on;                                           % add grid lines
legend('dis2medoid', 'dis2strongestHub');
%}































