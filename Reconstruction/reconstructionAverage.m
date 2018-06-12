clear;
close all;

%% Initializations

site = 'eiffel/';
img1 = 'img1';
img2 = 'img3';

% Loading Relevant Images
srcImg = imread(strcat('../exports/',site,img1,'/SourceImage0.bmp'));
exemplar1 = imread(strcat('../exports/',site,img1,'/TargetImage0.bmp'));
exemplar2 = imread(strcat('../exports/',site,img2,'/TargetImage0.bmp'));
completion = imread(strcat('../exports/',site,img2,'/CompletedImage1.bmp'));

% Setting ROI (uncomment as needed)
% iroi = [330 700 260 480]; %milan
% x_l = 330; x_r = 700; y_u = 260; y_d = 480;
iroi = [390 680 380 550]; %eiffel
x_l = 390; x_r = 680; y_u = 380; y_d = 550;
% iroi = [440 650 230 410]; %sphinx
% x_l = 440; x_r = 650; y_u = 230; y_d = 410;
% iroi = [440 570 185 300]; %taj
% x_l = 440; x_r = 570; y_u = 185; y_d = 300;

% Color Correction Matrices
colorCorr1 = csvread(strcat('../exports/',site,img1,'/color4.csv'));
colorCorr1 = reshapeColor(colorCorr1, iroi);

colorCorr2 = csvread(strcat('../exports/',site,img2,'/color4.csv'));
colorCorr2 = reshapeColor(colorCorr2, iroi);

pMat1 = csvread(strcat('../exports/',site,img1,'/pmat4.csv'));
pMat2 = csvread(strcat('../exports/',site,img2,'/pmat4.csv'));

%% Obtain final, color-corrected reconstructions

recon1 = srcImg;
fromSrc1 = ones(size(srcImg,1),size(srcImg,2));

for x=x_l:x_r-1
    for y=y_u:y_d-1
        if pMat1(y,x) < 0.8*255
            recon1(y,x,:) = colorCorr1(y-y_u+1,x-x_l+1,:);
            fromSrc1(y,x) = 0;
        end
    end
end

colorCorr1 = recon1(y_u:y_d-1,x_l:x_r-1,:);
fromSrc1 = fromSrc1(y_u:y_d-1,x_l:x_r-1);

recon2 = srcImg;
fromSrc2 = ones(size(srcImg,1),size(srcImg,2));

for x=x_l:x_r-1
    for y=y_u:y_d-1
        if pMat2(y,x) < 0.8*255
            recon2(y,x,:) = colorCorr2(y-y_u+1,x-x_l+1,:);
            fromSrc2(y,x) = 0;
        end
    end
end

colorCorr2 = recon2(y_u:y_d-1,x_l:x_r-1,:);
fromSrc2 = fromSrc2(y_u:y_d-1,x_l:x_r-1);
% figure;
% imshowpair(recon1,recon2,'montage');
tic
(recon1/2+recon2/2);p
toc
figure;
imshow((recon1/2+recon2/2))

print(strcat('../../report/recon/',site(1:end-1),'_average'),'-djpeg')
print(strcat('../../report/recon/',site(1:end-1),'_average'),'-depsc')