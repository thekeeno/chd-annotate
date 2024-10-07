function [chd_filename] = video_filename_to_chd_filename(video_filename)


%the filename of the chd header needs to have the final dot removed and then be
%appended with .chd.
chd_filename = regexprep(video_filename,'\.(?=\w+$)','') + '.chd';


end