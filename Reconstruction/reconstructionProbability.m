% Reconstruction with probability alone does not provide sensible results
% as it makes a hard decision on the origin of a pixel without considering
% general coherence of the reconstruction.

clear;
close all;

%% Initializations

radiusList = [1 3 5 10 15 20];
siteList = ["milan/" "eiffel/" "sphinx/" "taj_mahal/"];

% for site = siteList
site = 'eiffel/';
img1 = 'img1';
img2 = 'img3';

% Loading Relevant Images
srcImg = imread(strcat('../exports/',site,img1,'/SourceImage0.bmp'));
exemplar1 = imread(strcat('../exports/',site,img1,'/TargetImage0.bmp'));
exemplar2 = imread(strcat('../exports/',site,img2,'/TargetImage0.bmp'));

% Setting ROI
iroi = [330 700 260 480]; %milan
iroi = [390 680 380 550]; %eifel
% iroi = [440 650 230 410]; % sphinx
x_l = 330; x_r = 700; y_u = 260; y_d = 480;
x_l = 390; x_r = 680; y_u = 380; y_d = 550;
% x_l = 440; x_r = 650; y_u = 230; y_d = 410;
% iroi = [440 570 185 300]; %taj
% x_l = 440; x_r = 570; y_u = 185; y_d = 300;

% Color Correction Matrices
colorCorr1 = csvread(strcat('../exports/',site,img1,'/color4.csv'));
colorCorr1 = reshapeColor(colorCorr1, iroi);

colorCorr2 = csvread(strcat('../exports/',site,img2,'/color4.csv'));
colorCorr2 = reshapeColor(colorCorr2, iroi);

% Probability Matrices
normalP1 = csvread(strcat('../exports/',site,img1,'/normal_prob4.csv'));
normalP1 = normalP1(1:end-1);
normalP1 = reshapeProb(normalP1,iroi);

normalP2 = csvread(strcat('../exports/',site,img2,'/normal_prob4.csv'));
normalP2 = normalP2(1:end-1);
normalP2 = reshapeProb(normalP2,iroi);

pMat1 = csvread(strcat('../exports/',site,img1,'/pmat4.csv'));
pMat2 = csvread(strcat('../exports/',site,img2,'/pmat4.csv'));

useP1 = normalP1 >= normalP2;
useP2 = normalP2 > normalP1;

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


%% Simple probability-based reconstruction by patches

fromEx1 = zeros(size(radiusList));
fromEx2 = zeros(size(radiusList));
i = 1;

for radius = radiusList
    src_roi = srcImg(y_u:y_d-1,x_l:x_r-1,:);
    
    width = x_r - x_l;
    height = y_d - y_u;
    
    from1 = 0;
    from2 = 0;
    
    for x=radius+1:radius*2:width-radius
        for y = radius+1:radius*2:height-radius
            %check if next iteration will be possible i.e. within limits
            if y+2*radius > height
                upperLimy = height-y;
            else
                upperLimy = min(radius,height-y);
            end
            
            if x+2*radius > width
                upperLimx = width-x;
            else
                upperLimx = min(radius,width-x);
            end
            %end of checking next iteration is within limits
            
            fromSrc = (fromSrc1(y,x) == 1 || fromSrc1(y,x) == 1);
            
            if ~fromSrc && useP1(y,x)
                src_roi(y-radius:y+upperLimy,x-radius:x+upperLimx,:) = colorCorr1(y-radius:y+upperLimy,x-radius:x+upperLimx,:);
                from1 = from1+1;
            elseif ~fromSrc && useP2(y,x)
                src_roi(y-radius:y+upperLimy,x-radius:x+upperLimx,:) = colorCorr2(y-radius:y+upperLimy,x-radius:x+upperLimx,:);
                from2 = from2+1;
            end
        end
    end
    
    fromEx1(i) = from1/(from1+from2);
    fromEx2(i) = from2/(from1+from2);
    i= i+1;
    
    srcImg(y_u:y_d-1,x_l:x_r-1,:) = src_roi;
    
    figure;
    imshow(srcImg);
%     outputName = sprintf('../../report/testing/reconstruction/reconstruction_prob_%s_%d',site(1:end-1),radius);
%     print(outputName,'-depsc');
%     print(outputName,'-djpeg');
end
% end

% plot(radiusList,fromEx1);
% hold on;
% plot(radiusList,fromEx2);
% title('Proportion of patches taken from each exemplar');
% xlabel('Patch Radius (pixels)')
% ylabel('Proportion of patches taken')
% legend('Exemplar1','Exemplar2')
% outputName = sprintf('../../report/testing/reconstruction/reconstruction_proportion_%s',site(1:end-1));
% print(outputName,'-depsc');
% print(outputName,'-djpeg');