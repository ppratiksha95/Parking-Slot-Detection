% Clean up.
clc;   % Clear the command window.
close all;   % Close all figures 
clearvars;   %Clears variables from the active workspace
workspace;   % Make sure the workspace panel is showing.
format long g;   % Sets the display format of numerical values; long g results in long, fixed-decimal format or scientific notation, whichever is more compact, with a total of 15 digits for double values, and 7 digits for single values.
format compact;   % Sets the line spacing format; Compact suppresses excess blank lines to show more output on a single screen.
fontSize = 10;

fprintf('Beginning to run %s.m ...\n', mfilename);   % Writes data to a text file or formats data and displays the results on the screen

%-----------------------------------------------------------------------------------------------------------------------------------
% Read in reference image with no cars (empty parking lot).

emptylot = 'C:\Users\Pratiksha Pradhan\Documents\ECE\DC\Empty Lot.jpg';

rgbEmptyImage = imread(emptylot);   % Reads the image from the file

%the number of rows and columns in our image. Image is a 3-D array. The third output is the number of color planes 3 
[rows, columns, numberOfColorChannels] = size(rgbEmptyImage);

% Display the test image full size.
figure(1);
imshow(rgbEmptyImage, []);   % Displays the grayscale image by scaling the display based on the range of pixel values in the image. It displays the minimum value in the image as black and the maximum value as white.
axis('on', 'image');   % Uses the same length for the data units along each axis and fit the axes box tightly around the data.
caption = sprintf('Reference Image : "%s"', emptylot);   % Formats data into string or character vector
title(caption, 'FontSize', fontSize, 'Interpreter', 'None');   % Set the Interpreter property as 'None' so that the text is displayed exactly as typed

%IMPIXELINFO(H) creates a pixel information tool in the figure specified by the handle H, where H is an image, axes, uipanel, or figure object. Axes, uipanel, or figure objects must contain at least one image object
%Use the impixelinfo function to create a Pixel Information tool. The Pixel Information tool displays information about the pixel in an image that the pointer is positioned over. If the figure contains multiple images, the tool displays pixel information for all the images. 


hp = impixelinfo(); % Creates a Pixel Information tool. Set up status line to see values when you mouse over the image.

%-----------------------------------------------------------------------------------------------------------------------------------
% Read in test image (image with cars parked on the parking lot).

withcars = 'C:\Users\Pratiksha Pradhan\Documents\ECE\DC\Parking Lot.jpg';

rgbTestImage = imread(withcars);
[rows, columns, numberOfColorChannels] = size(rgbTestImage);

% Display the original image full size.
figure(2);
imshow(rgbTestImage, []);
axis('on', 'image');
caption = sprintf('Test Image : "%s"', withcars);
title(caption, 'FontSize', fontSize, 'Interpreter', 'None');
hp = impixelinfo();   

% Set up figure properties:
% Enlarge figure to full screen.
hFig1 = gcf;   % Returns the current figure handle. You can use the figure handle to query and modify figure properties.
hFig1.Units = 'Normalized';   % The input positions fill the complete window
% hFig1.WindowState = 'maximized';   % Maximizes the figure while keeping the taskbar in view


%-----------------------------------------------------------------------------------------------------------------------------------
% Read in mask image that defines where the spaces are.
maskimage = 'C:\Users\Pratiksha Pradhan\Documents\ECE\DC\Masked Lot.png';

maskImage1 = imread(maskimage);
[rows, columns, numberOfColorChannels] = size(maskImage1);

figure(3);
imshow(maskImage1, []);
axis('on', 'image');
caption = sprintf('Masked Lot');
title(caption, 'FontSize', fontSize, 'Interpreter', 'None');
hp = impixelinfo(); % Set up status line to see values when you mouse over the image.

% Create a binary mask from seeing where the min value is 255.
mask = min(maskImage1, [], 3) == 255;

% Display the test image full size.
figure(4);
imshow(mask, []);
axis('on', 'image');
caption = sprintf('Mask Image : "%s"', maskimage);
title(caption, 'FontSize', fontSize, 'Interpreter', 'None');
hp = impixelinfo(); % Set up status line to see values when you mouse over the image.

%-----------------------------------------------------------------------------------------------------------------------------------
% Find the cars.
% First, get the absolute difference image.
diffImage = imabsdiff(rgbEmptyImage, rgbTestImage);

figure(5);
imshow(diffImage, []);
axis('on', 'image');
caption = sprintf('Difference Image');
title(caption, 'FontSize', fontSize, 'Interpreter', 'None');
hp = impixelinfo(); % Set up status line to see values when you mouse over the image.

% Convert to gray scale and mask it with the spaces mask.
diffImage = rgb2gray(diffImage);
diffImage(~mask) = 0;

% Get a histogram of the image so we can see where to threshold it at.
figure(6);
histogram(diffImage(diffImage>0));

% Display the gray scale image.
figure(7);
imshow(diffImage, []);
axis('on', 'image');
caption = sprintf('Gray Scale Difference Image');
title(caption, 'FontSize', fontSize, 'Interpreter', 'None');
hp = impixelinfo(); % Set up status line to see values when you mouse over the image.

% Threshold the image to find pixels that are substantially different from the background.
kThreshold = 40; % Determined by examining the histogram.
parkedCars = diffImage > kThreshold;


% Fill holes. Morphological reconstruction algorithm
parkedCars = imfill(parkedCars, 'holes');

% Get convex hull.
parkedCars = bwconvhull(parkedCars, 'objects');

% The 'convexArea' property corresponds to the area of the convex hull of the region. The convex hull of a region is the smallest region that satisfies two conditions: (1) it is convex (2) it contains the original region.
% The convex area is by definition greater than or equal to the area of the region. It can be used to compute a shape factor known either as "convexity" or "solidity", defined as the ratio of area over convex area. It can be obtained by using the 'solidity' parameter in regionprops function.
% The solidity can be used to discriminate or classify regions using shape criteria.

% Display the mask image.
figure(8);
imshow(parkedCars, []);
impixelinfo;
axis('on', 'image');
caption = sprintf('Parked Cars Binary Image with Threshold = %.1f', kThreshold);
title(caption, 'FontSize', fontSize, 'Interpreter', 'None');


%-----------------------------------------------------------------------------------------------------------------------------------
% Measure the percentage of white pixels within each rectangular mask.
props = regionprops(mask, parkedCars, 'MeanIntensity', 'Centroid', 'BoundingBox');
centroids = vertcat(props.Centroid);

%-----------------------------------------------------------------------------------------------------------------------------------

% Put yellow bounding boxes for each space (whether taken or available).
for k = 1 : length(props)
	rectangle('Position', props(k).BoundingBox, 'EdgeColor', 'y');
end


% Re-extract these vectors with the new order.
percentageFilled = [props.MeanIntensity]
%-----------------------------------------------------------------------------------------------------------------------------------


%-----------------------------------------------------------------------------------------------------------------------------------
% Place a red x on the image if the space is filled, and a green circle if the space is available to be parked on (it's empty).
% Go through each rectangle and say whether it's filled with a car or not.
% We'll say it's filled if 10% of the pixels are filled.
% hFig2 = figure;
% imshow(rgbTestImage);
% hFig2.WindowState = 'maximized';
% Give a name to the title bar.
% hFig2.Name = 'Image Processing';
figure(9);
imshow(rgbTestImage, []);
impixelinfo;
axis('on', 'image');
caption = sprintf('Image Processing', kThreshold);
title(caption, 'FontSize', fontSize, 'Interpreter', 'None');
hold on;
for k = 1 : length(props)
	x = centroids(k, 1);
	y = centroids(k, 2);
	blobLabel = sprintf('%d', k);
	if percentageFilled(k) > 0.10
		% It has a car in that rectangle.
		plot(x, y, 'rx', 'MarkerSize', 30, 'LineWidth', 4);
		% Put up the blob label.
		text(x, y+20, blobLabel, 'Color', 'r', 'FontSize', 15, 'FontWeight', 'bold');
	else
		% No car is parked there.  The space is available.
		plot(x, y, 'g.', 'MarkerSize', 40, 'LineWidth', 4);
		% Put up the blob label.
		text(x, y+20, blobLabel, 'Color', 'g', 'FontSize', 15, 'FontWeight', 'bold');
	end
	
end

title('Marked Spaces.  Green Spot = Available.  Red X = Taken.', 'FontSize', fontSize);

fprintf('Done running %s.m ...\n', mfilename);

