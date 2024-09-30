%function ans = annotate_cine(filename)

%select the filename of the avi or mp4 you want to load here:
filename = "example/example.mp4";
filename_char = convertStringsToChars(filename); %convert it to characters



outputname = filename_char(1:end-4) + "_out.mp4";
output_image_name_base = filename_char(1:end-4) + "_frame_";
v = VideoReader(filename); %create videoreader object to read in frames from selected video

%the filename of the chd header needs to have the dot removed and then be
%appended with .chd.
chd_filename = regexprep(filename,'[.]','') + '.chd';

%import the video's metadata (FPS, exposure, etc) using my custom read_chd func
C = read_chd(chd_filename);

numOfFramesUsed = 1;


for fi = 1:100:(C.ImageCount)
    frame = im2double(read(v,fi));
    [rows columns numberOfColorBands] = size(frame);
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




