%function ans = annotate_cine(filename)

%select the filename of the avi or mp4 you want to load here:
filename = "example/example.mp4";
filename_char = convertStringsToChars(filename); %convert it to characters

%DECIMATION - if you want to remove every X frames, set this to X. for
%example decimate = 2 will only process every other frame
decimate = 100;

outputname = filename_char(1:end-4) + "_out.mp4";
output_image_name_base = filename_char(1:end-4) + "_frame_";
v = VideoReader(filename); %create videoreader object to read in frames from selected video

%the filename of the chd header needs to have the dot removed and then be
%appended with .chd.
chd_filename = regexprep(filename,'[.]','') + '.chd';

%import the video's metadata (FPS, exposure, etc) using my custom read_chd func
C = read_chd(chd_filename);

%make and open a VideoWriter object to render the output to file
vw = VideoWriter(outputname,'MPEG-4');
open(vw);




%CROPPING - this happens before anything else

crop_enable = true; %set to true to enable cropping

crop_rect = [30.5100   53.5100  430.9800  427.9800]; %rectangle defining the crop window



%SCALEBAR

scalebar_enable = true;
scalebar_length_um = 100; %length of the desired scalebar in microns
pixels_per_um = 1; %number of pixels in the video that corresponds to a micron. may be an int or a float

scalebar_colour = [255,255,255];

scalebar_text_gap = 10;

scalebar_init_x = 10;
scalebar_init_y = 200;

scalebar_thickness = 10; %in pixels
scalebar_length = scalebar_length_um*pixels_per_um;
scalebar_fontsize = 25;

%TIMESTAMP

timestamp_enable = true;
timestamp_colour = "yellow";
timestamp_fontsize = 30;


for fi = 1:decimate:(C.ImageCount)
    disp(fi)
    frame = read(v,fi);
    if crop_enable
        frame = imcrop(frame,crop_rect);
    end

    if scalebar_enable
        
        for i = 1:size(frame,1)
            for j=1:size(frame,2)
                if (j>= scalebar_init_x) && (j< scalebar_init_x+scalebar_length) && (i>=scalebar_init_y) && (i<scalebar_init_y+scalebar_thickness)
                    frame(i,j,:) = scalebar_colour;

                end
            end
        end
        frame = insertText(frame,[scalebar_init_x scalebar_init_y-scalebar_text_gap-scalebar_thickness ],int2str(scalebar_length_um)+"μm",'BoxColor',scalebar_colour,'FontSize',scalebar_fontsize,"AnchorPoint", "LeftBottom");
    end
    if timestamp_enable
        time_ms = 1000* fi/C.FrameRate16;
        frame = insertText(frame,[0 0],int2str(time_ms)+"ms",'BoxColor',timestamp_colour,'FontSize', timestamp_fontsize);
    end
    imshow(frame)









    drawnow
    writeVideo(vw,frame)
    imwrite(frame, output_image_name_base+int2str(fi)+".jpg")
end



close(vw)

