clear;
close all;

%% Initializations

radiusList = [3 5 10 15 20];

img1 = 'img1';

keySet = {'milan/','eiffel/','sphinx/','taj_mahal/'};
valueSet = {[330 700 260 480], [390 680 380 550], [440 650 230 410], [440 570 185 300]};
roi = containers.Map(keySet,valueSet);

valueSet = {'img5', 'img3', 'img2', 'img2'};
img = containers.Map(keySet,valueSet);
siteList = ["milan/","eiffel/","sphinx/","taj_mahal/"];

for site=siteList
    
    site = char(site);
    img2 = img(site);
    
    % Loading Relevant Images
    srcImg = imread(strcat('../exports/',site,img1,'/SourceImage0.bmp'));
    exemplar1 = imread(strcat('../exports/',site,img1,'/TargetImage0.bmp'));
    exemplar2 = imread(strcat('../exports/',site,img2,'/TargetImage0.bmp'));
    completion = imread(strcat('../exports/',site,img2,'/CompletedImage1.bmp'));

    iroi = roi(site);
    x_l = iroi(1); x_r = iroi(2); y_u = iroi(3); y_d = iroi(4);
    
    % Interpolated Nearest Neighbour Fields;
    
    ANN1 = csvread(strcat('../exports/',site,img1,'/annCplt4.csv'));
    
    ANN1_x = ANN1(:,1:4:end);
    ANN1_y = ANN1(:,2:4:end);
    ANN1_s = ANN1(:,3:4:end);
    ANN1_r = ANN1(:,4:4:end);
    
    ANN2 = csvread(strcat('../exports/',site,img2,'/annCplt4.csv'));
    
    ANN2_x = ANN2(:,1:4:end);
    ANN2_y = ANN2(:,2:4:end);
    ANN2_s = ANN2(:,3:4:end);
    ANN2_r = ANN2(:,4:4:end);
    
    ANN12 = csvread(strcat('../exports/',site,img1,'_',img2,'/ann4.csv'));
    
    ANN12_x = ANN12(:,1:4:end);
    ANN12_y = ANN12(:,2:4:end);
    ANN12_s = ANN12(:,3:4:end);
    ANN12_r = ANN12(:,4:4:end);
    
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
    
    %% Color correction of nearest neighbour
    
    x_offset = x_l - 1;
    y_offset = y_u - 1;
    
    height = y_d - y_u; width = x_r - x_l;
    
    colorCorr = zeros(height*width, 3);
    i=1;
    
    for x = x_l:x_r-1
        for y = y_u:y_d-1
            
            x_ = round(ANN1_x(y,x))+1;
            y_ = round(ANN1_y(y,x))+1;
            x_new = round(ANN12_x(y_,x_))+1;
            y_new = round(ANN12_y(y_,x_))+1;
            
            colorCorr(i,:) = exemplar2(y_new,x_new,:)+1;
            i=i+1;
        end
    end
    
    colorCorr = colorCorrection(site, img2, iroi, colorCorr);
    
    %% Reconstruction (ADD MORE DIRECTIONS OF PROPAGATION)
    
    originalSrc = srcImg;
    prop1 = zeros(length(radiusList),1);
    prop = zeros(length(radiusList),1);
    i = 1;
    % patch properties
    
    for radius=radiusList
        srcImg = originalSrc;
        srcImg(y_u:y_d-1,x_l:x_r-1,:) = 0;
        fprintf('Site: %s, Radius: %d... \n',site(1:end-1),radius);
        width = x_r - x_l;
        height = y_d - y_u;
        
        proportion1 = 0;
        proportion = 0;
        for x=x_l+radius:radius*2:x_r-1
            for y = y_u+radius:radius*2:y_d-1
                %check if next iteration will be possible i.e. within limits
                if y+2*radius > y_d-1
                    upperLimy = y_d-y;
                else
                    upperLimy = min(radius,y_d-1-y);
                end
                
                if x+2*radius > x_r-1
                    upperLimx = x_r-x;
                else
                    upperLimx = min(radius,x_r-1-x);
                end
                
                x_right = x+upperLimx; x_left = x - radius;
                y_down = y + upperLimy; y_up = y - radius;
                
                [Gy, Gx] = imgradientxy(rgb2gray(srcImg),'sobel');
                Gy = -Gy;
                [Gmag, Gdir] = imgradient(Gy,Gx);
                
                [from1,usePatch] = selectPatch(colorCorr,colorCorr1,Gy,Gx,srcImg,[x_left x_right y_up y_down], iroi, 'isophotes');
                if from1
                    proportion1 = proportion1+1;
                else
                    proportion = proportion + 1;
                end
                srcImg(y_up:y_down-1,x_left:x_right-1,:) = usePatch(y_up:y_down-1,x_left:x_right-1,:);
                %         imshow(srcImg)
            end
        end
        prop1(i) = proportion1/(proportion+proportion1);
        prop(i) = proportion/(proportion+proportion1);
        i = i + 1;
        
        imwrite(srcImg, sprintf('../../report/testing/reconstruction/multiPatchReconstruction_%s_%d.png',site(1:end-1),radius))
        imwrite(srcImg, sprintf('../../report/testing/reconstruction/multiPatchReconstruction_%s_%d.jpg',site(1:end-1),radius))
    end
    figure;
    plot(radiusList, prop1); hold on;
    plot(radiusList, prop);hold off;
    title(sprintf('Proportion of patches taken from each intermediate reconstruction for %s source',site(1:end-1)))
    xlabel('Patch Radius')
    ylabel('Proportion of patches')
    legend('Exempar 1', 'Alignment')
    print(sprintf('../../report/testing/reconstruction/multiPatchReconstruction_proportion_%s',site(1:end-1)),'-depsc');
end