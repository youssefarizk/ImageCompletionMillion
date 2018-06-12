close all;
clear;

addpath('../assets/');

%% Initializations

fileName = '../exports/sphinx/img2/ann4.csv';
showImage = true;
numAngles = 90;
numScales = 256;
startScale = 0.33; endScale = 3.00;

a = log(startScale); b = log(endScale);

scaleTbl = exp(a + (b-a)*1.0*[0:numScales-1]/numScales);

ANN = csvread(fileName);

%separating into 4 degrees of freedom
ANN_x = ANN(:,1:4:end);
ANN_y = ANN(:,2:4:end);
ANN_s = round(ANN(:,3:4:end)); %rounding the values
ANN_r = ANN(:,4:4:end);

[img_y, img_x] = size(ANN_x);

%% Data Visualization

tmp_x = ANN_x/img_x * 256; %R
tmp_y = ANN_y/img_y * 256; %G
tmp_s = zeros(img_y, img_x); %B
for i = 1:img_y
    tmp_s(i,:) = scaleTbl(ANN_s(i,:)+1)/endScale * 256;
end

imRange = [1 256];

%ROI
x_l = 440; x_r = 650; y_u = 230; y_d = 410;

rectRange = [x_l y_u (x_r-x_l) (y_d-y_u)];
rgbImage = cat(3,tmp_x,tmp_y,tmp_s);
rgbImage = double(rgbImage)/256;
if showImage
    figure;
    subplot(2,2,1);
    imshow(tmp_x,imRange);
    subplot(2,2,2);
    imshow(tmp_y,imRange);
    subplot(2,2,3);
    imshow(tmp_s,imRange);
    subplot(2,2,4);
    imshow(rgbImage);hold on;rectangle('Position',rectRange);
    
            figure;
            imshow(rgbImage);
            rect = rectangle('Position',rectRange);
            print('../../report/testing/nnf_bad','-depsc');
end

%% NNF Gradient

leftDiff_x = ANN_x(y_u:y_d,x_l-1) - ANN_x(y_u:y_d,x_l+1);
rightDiff_x = ANN_x(y_u:y_d,x_r+1) - ANN_x(y_u:y_d,x_r-1);
upDiff_x = ANN_x(y_u-1,x_l:x_r) - ANN_x(y_u+1,x_l:x_r);
downDiff_x = ANN_x(y_d+1,x_l:x_r) - ANN_x(y_d-1,x_l:x_r);

diffSum_x = sum(abs(leftDiff_x)) + sum(abs(rightDiff_x)) + sum(abs(upDiff_x)) + sum(abs(downDiff_x));
diffSum_x = diffSum_x/(2 * (y_d-y_u + x_r-x_l));
diffSum_x = diffSum_x/img_x;

leftDiff_y = ANN_y(y_u:y_d,x_l-1) - ANN_y(y_u:y_d,x_l+1);
rightDiff_y = ANN_y(y_u:y_d,x_r+1) - ANN_y(y_u:y_d,x_r-1);
upDiff_y = ANN_y(y_u-1,x_l:x_r) - ANN_y(y_u+1,x_l:x_r);
downDiff_y = ANN_y(y_d+1,x_l:x_r) - ANN_y(y_d-1,x_l:x_r);

diffSum_y = sum(abs(leftDiff_y)) + sum(abs(rightDiff_y)) + sum(abs(upDiff_y)) + sum(abs(downDiff_y));
diffSum_y = diffSum_y/(2 * (y_d-y_u + x_r-x_l));
diffSum_y = diffSum_y/img_y;

leftDiff_s = ANN_s(y_u:y_d,x_l-1) - ANN_s(y_u:y_d,x_l+1);
rightDiff_s = ANN_s(y_u:y_d,x_r+1) - ANN_s(y_u:y_d,x_r-1);
upDiff_s = ANN_s(y_u-1,x_l:x_r) - ANN_s(y_u+1,x_l:x_r);
downDiff_s = ANN_s(y_d+1,x_l:x_r) - ANN_s(y_d-1,x_l:x_r);

diffSum_s = sum(abs(leftDiff_s)) + sum(abs(rightDiff_s)) + sum(abs(upDiff_s)) + sum(abs(downDiff_s));
diffSum_s = diffSum_s/(2 * (y_d-y_u + x_r-x_l));
diffSum_s = diffSum_s/numScales;

leftDiff_r = ANN_r(y_u:y_d,x_l-1) - ANN_r(y_u:y_d,x_l+1);
rightDiff_r = ANN_r(y_u:y_d,x_r+1) - ANN_r(y_u:y_d,x_r-1);
upDiff_r = ANN_r(y_u-1,x_l:x_r) - ANN_r(y_u+1,x_l:x_r);
downDiff_r = ANN_r(y_d+1,x_l:x_r) - ANN_r(y_d-1,x_l:x_r);

diffSum_r = sum(abs(leftDiff_r)) + sum(abs(rightDiff_r)) + sum(abs(upDiff_r)) + sum(abs(downDiff_r));
diffSum_r = diffSum_r/(2 * (y_d-y_u + x_r-x_l));
diffSum_r = diffSum_r/numAngles;

% Displaying Normalized Results

disp(fileName);fprintf('\n');
fprintf('diffSum_x: %0.5f\n', diffSum_x);
fprintf('diffSum_y: %0.5f\n', diffSum_y);
fprintf('diffSum_s: %0.5f\n', diffSum_s);
fprintf('diffSum_r: %0.5f\n', diffSum_r);

fprintf('\n');

fprintf('diffSum_r: %0.5f\n', (diffSum_x+diffSum_y+diffSum_s+diffSum_r)/4);

%% NNF Noise

threshList = 1.0:0.05:1.5;
rslt = zeros(4,length(threshList));
idx = 1;

for thresh = threshList
    
    tmp_x = ANN_x(y_u:y_d,x_l:x_r);
    tmp_y = ANN_y(y_u:y_d,x_l:x_r);
    tmp_s = ANN_s(y_u:y_d,x_l:x_r);
    tmp_r = ANN_r(y_u:y_d,x_l:x_r);
    
    [x_,y_,s,r] = findClusters(tmp_x,tmp_y,tmp_s,tmp_r,thresh); % boundary point count
    rslt(:,idx) = [x_,y_,s,r]';
    idx = idx + 1;
    
end

% Displaying Normalized Results

fprintf('x_: %0.5f\n', x_);
fprintf('y_: %0.5f\n', y_);
fprintf('s: %0.5f\n', s);
fprintf('r: %0.5f\n', r);
fprintf('\n');

fprintf('Average: %0.5f\n', (x_+y_+s_+r_)/4);

