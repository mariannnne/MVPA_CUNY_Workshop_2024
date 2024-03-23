%% 
% 
% 
%% 0. Getting started: add paths

% this requires CanlabCore: https://github.com/canlab/CanlabCore
% --- which requires SPM12 & Spider (but should be mirrored in there)

% example code for adding path to the CanlabCode library
% addpath(genpath('CanlabCore'));

% this is how i add path to my repos
addpath(genpath('/Users/marianne/code'));

%% 1. Load data

% data are from Wani Woo's SAS2015_PatRec
load('data.mat');

% check dat.Y
plot(dat.Y);
set(gcf, 'color', 'w');
set(gca, 'fontsize', 15);
for x = 5:5:145
    line([x,x], [0, 200], 'linestyle', '--', 'color', [.6 .6 .6]); 
end

% check dat.dat
imagesc(dat.dat);
ylabel('voxels');
xlabel('subject x conditions')
colorbar;


plot(dat);

%% 2. Run SVMs

% Prepare data for SVMs
wh_folds = repmat(reshape(repmat(1:30,2,1), 60, 1), 2, 1);

dat_svm = dat;
dat_svm.dat = [dat.dat(:,reshape(repmat(1:5, 30,1)', 150,1) <= 2) ...
    dat.dat(:,reshape(repmat(1:5, 30,1)', 150,1) >= 4)];
dat_svm.Y = [-ones(60,1); ones(60,1)];

% run linear SVMs with leave-one-subject-out CV
[~, svm.stats] = predict(dat_svm, 'algorithm_name', ...
        'cv_svm', 'nfolds', wh_folds, 'error_type', 'mcr');

% cross-validated distance from hyperplane 
svm.stats.dist_from_hyperplane_xval

% %accuracy = 76%
% fprintf('map has a %f accuracy',(1-svm.stats.cverr));

% plot the receiver operating characteristic
ROC = roc_plot(svm.stats.dist_from_hyperplane_xval,logical(svm.stats.Y>0),'plothistograms');
saveas(gcf, 'ROCplot.png');

% visualize the weight map
orthviews(svm.stats.weight_obj);
    
% % RBF kernel
% [~, svm.stats] = predict(dat_svm, 'algorithm_name', ...
%         'cv_svm', 'rbf', 2, 'nfolds', wh_folds, 'error_type', 'mcr');
% 
% ROC = roc_plot(svm.stats.dist_from_hyperplane_xval,logical(svm.stats.Y>0),'plothistograms');
% saveas(gcf, 'ROCplot-rbf.png');
% 
% % Slack variables, C = 3
% [~, svm.stats] = predict(dat_svm, 'algorithm_name', ...
%         'cv_svm', 'C', 3, 'nfolds', wh_folds, 'error_type', 'mcr');
% 
% ROC = roc_plot(svm.stats.dist_from_hyperplane_xval,logical(svm.stats.Y>0),'plothistograms');
% saveas(gcf, 'ROCplot-slack.png');
%% bootstrap the prediction to get significance estimates for the SVM weights
% should bootstrap ~10,000 samples... doing 500 for computational ease
[cverr, stats, optout] = predict(dat_svm, 'algorithm_name', 'cv_svm', 'nfolds', wh_folds,'bootsamples', 500);

%thresholds the image with FDR correction q < 0.05, cluster size k =1
obj = threshold(stats.weight_obj, .05, 'fdr')
orthviews(obj);

%%
close all;
% nice plots

cl=region(obj); % change image object format for plotting

table=cluster_table(cl, 0, 0,'writefile','clustertable');

o2=canlab_results_fmridisplay();
o2=addblobs(o2,cl,'splitcolor', {[0 0 1] [.3 0 .8] [.8 .3 0] [1 1 0]})
obj.fullpath=['PredictivePattern.nii'];


saveas(gcf, 'SVMweightmap_FDR05_K0.png');

