%parser for filenames

extension = ".cine";

directory = "F:\files\";

files = dir(directory + "*" + extension);


parameter_name_list = ["FPS" "EXP" "EDR" "FOCUS" "LENS" "OPT" "PF" "SUB" "DROP" "E" "EA" "F" "W" "WENV"];
number_of_parameters = size(parameter_name_list,2);
number_of_files = size(files,1);
vartype = repmat({'string'},1,number_of_parameters);
vartype = [{'string'}, {'double'} , {'datetime'} , {'string'} vartype];
T = table('Size',[number_of_files number_of_parameters+4],'VariableTypes',vartype, 'VariableNames',["Filename" "Video" "Date" "Description" parameter_name_list]);

for i = 1:number_of_files
    filename = files(i).name;

    %select the filename of the avi or mp4 you want to load here:

    filename_char = convertStringsToChars(filename); %convert it to characters


    filename_base = filename;
    filename = filename(1:end-strlength(extension)) + " "; %remove the extension and add a space on the end to aid parsing
    filename = convertStringsToChars(filename);
    [startIndex,endIndex] = regexp(filename,"^([\S]+)"); %returns the starting and ending indices of all matches.
    date = datetime(filename(startIndex:endIndex),'InputFormat','yyyy-MM-dd');
    T(i,"Date") = {date};
    %strip the date
    filename=filename(endIndex+2:end);
    
    %find the video number
    [startIndex,endIndex] = regexp(filename,"vid\s*(-?\d+(?:\.\d+)?)");
    vidnumberstring = filename(startIndex:endIndex);
    filename=filename(endIndex+2:end);
    vidnumber = str2double(vidnumberstring(4:end));
    T(i,"Video") = {vidnumber};
        
    for p = parameter_name_list
        [filename, paramval] = strip_parse(filename,p);
        paramval = convertCharsToStrings(paramval);
        T(i,p) = {paramval};
    end
    description = filename;
    T(i,"Description") = {description};
    T(i,"Filename") = {filename_base};
end

%now we have most of the data ingested, let's do some sanitising.

%parse FPS, get decimation, and calculate post decimation FPS

%parse E field values RMS

electric = T{:,"E"};
electric = strrep(electric,'VRMS','');
electric = str2double(electric);
T = addvars(T,electric,'After','E','NewVariableNames','AFG Voltage/VRMS');
%parse E field after amp
electricamp = T{:,"EA"};
electricamp = strrep(electricamp,'VPP','');
doubledup = contains(electricamp,"x2");
electricamp = strrep(electricamp,"x2","");
electricamp = str2double(electricamp);
electricampfinal = doubledup.*electricamp + electricamp;

T = addvars(T,electricamp, doubledup, electricampfinal,'After','EA','NewVariableNames',{'Voltage At Amplifier/VPP' 'Voltage Doubled?' 'Voltage At Sample'});
T= removevars(T,{'E'});
T= removevars(T,{'EA'});

%parse frequency

frequencies = T{:,"F"};
frequencies = strrep(frequencies,'MHz','000000');
frequencies = strrep(frequencies,'kHz','000');
frequencies = strrep(frequencies,'Hz','');
frequencies = str2double(frequencies);
T = addvars(T,frequencies,'After','F','NewVariableNames','Frequency/Hz');
T= removevars(T,{'F'});

%parse exposure

exposure = T{:,"EXP"};
exposure = str2double(exposure);
T = addvars(T,exposure,'After','EXP','NewVariableNames','Exposure/ms');
T= removevars(T,{'EXP'});


%EDR

exposure = T{:,"EDR"};
exposure = str2double(exposure);
T = addvars(T,exposure,'After','EDR','NewVariableNames','EDR/ms');
T= removevars(T,{'EDR'});

%FPS and Decimation

fps = T{:,"FPS"};
decimated = contains(fps,"D");

base_fps_double = zeros(size(fps,1),1);


decimation_factor = ones(size(fps,1),1);

for i=1:size(fps,1)

    this_fps = convertStringsToChars(string(fps(i)));
    [startIndex,endIndex] = regexp(this_fps,"[^\d]*(\d+)");
    [startIndex2,endIndex2] = regexp(this_fps,"[\D]*[\d]+[\D]+([\d]+)");
    base_fps = this_fps(startIndex:endIndex);
    base_fps_double(i) = str2double(base_fps);
    if decimated(i)
        
        decimation = this_fps(endIndex+2:endIndex2);
        decimation_factor(i) = str2double(decimation);
    end
end

final_fps = base_fps_double./decimation_factor;

T = addvars(T,base_fps_double, decimation_factor, final_fps,'After','FPS','NewVariableNames',{'Recorded FPS' 'Decimation' 'Saved FPS'});
T= removevars(T,{'FPS'});


T = renamevars(T,["PF","SUB", "FOCUS", "DROP", "W", "WENV", "OPT", "LENS"],["Photofluor Setting","Substrate", "Focal Plane", "Droplet", "Carrier Waveform", "Modulation Envelope", "Optics", "Lens"]);

T = sortrows(T, "Video");


writetable(T,"data.xlsx",'Sheet',1)



function [remaining_filename,parameter_value] = strip_parse(filename, parameter_name)
    [startIndex,endIndex] = regexp(filename,"(?<=" + parameter_name + "-)(.*)");
    filenameshortened = filename(startIndex:endIndex);
    
    [startIndex2,endIndex2] = regexp(filenameshortened,"^([\S]+)");
    parameter_value = filenameshortened(startIndex2:endIndex2);
    %texttoremove = filename(startIndex-strlength(parameter_name)-1:startIndex+endIndex2)
    filename(startIndex-strlength(parameter_name)-1:startIndex+endIndex2) = [];
    remaining_filename = filename;
end
