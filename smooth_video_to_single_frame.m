%function ans = annotate_cine(filename)

%select the filename of the avi or mp4 you want to load here:
filename = "example/example.mp4";
filename_char = convertStringsToChars(filename); %convert it to characters

%extra decimation
decimation_factor = 100; %skip frames to speed up video - use with caution

outputname = filename_char(1:end-4) + "_out.mp4";
output_image_name_base = filename_char(1:end-4) + "_frame_";
v = VideoReader(filename); %create videoreader object to read in frames from selected video



numOfFramesUsed = 1;


for fi = 1:decimation_factor:(v.NumFrames)
    frame = im2double(read(v,fi));
    if fi == 1
        sumImage = frame;
    else
        sumImage = sumImage + frame;
    end
    numOfFramesUsed= numOfFramesUsed+1;
    



    
end
sumImage=sumImage/numOfFramesUsed;
imshow(im2uint8(sumImage));
imwrite(im2uint8(sumImage), output_image_name_base+"avg.jpg")




