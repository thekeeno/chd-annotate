function C = read_chd(varargin)
    if nargin == 1
        filename = varargin{1};
    elseif nargin == 0
        filename = "rubbed pi test 3mp4.chd";
    else
        error("Too many input arguments");
    end

    


    %some constants
    MAXLENDESCRIPTION_OLD=121;
    
    
    fileID = fopen(filename,"r");
    
    C(1).filename = filename;
    
    %verify if this is indeed a phantom cine file. If it it, the first two
    %bytes should read "CI"
    
    CI_check = [char(fread(fileID,1,"ubit8")),char(fread(fileID,1,"ubit8"))];
    if (CI_check ~= "CI")
        error("Not a valid phantom cine header file")
    end
    
    
    %read the rest of the header
    
    C.header_size = fread(fileID,1,"ubit16");
    C.compression = fread(fileID,1,"ubit16");
    C.verison = fread(fileID,1,"ubit16"); %expect this to be one
    C.FirstMovieImage = fread(fileID,1,"bit32");
    C.TotalImageCount = fread(fileID,1,"ubit32");
    C.FirstImageNo = fread(fileID,1,"bit32");
    C.ImageCount = fread(fileID,1,"ubit32");
    
    %other data offsets
    
    OffImageHeader = fread(fileID,1,"ubit32");
    OffSetup = fread(fileID,1,"ubit32");
    OffImageOffsets = fread(fileID,1,"ubit32");

    %trigger time - this is stored in a TIME64 format which is a bit odd
    %and does not work??
    
    ntp64 = fread(fileID,2,"uint32");
    TriggerTime = datetime(ntp64(1) + 1/ntp64(2), "ConvertFrom", "epochtime", "epoch", "1900-01-01"); %this is broken for now.
    
    
    %bitmapinfoheader - this contains data about the image size and color
    
    BITMAPINFOHEADER_array = ["uint32" "biSize"; "int32" "biWidth";
    "int32" "biHeight";
    "uint16" "biPlanes";
    "uint16" "biBitCount";
    "uint32" "biCompression";
    "uint32" "biSizeImage";
    "int32" "biXPelsPerMeter";
    "int32" "biYPelsPerMeter";
    "uint32" "biClrUsed";
    "uint32" "biClrImportant"];
    s = size(BITMAPINFOHEADER_array);
    s = s(1);
    
    for i = 1:s
        C = setfield(C,BITMAPINFOHEADER_array(i,2),fread(fileID,1,BITMAPINFOHEADER_array(i,1)));
    end
    
    %Camera SETUP info - this is inomcplete, but so far will give the frame
    %rate, and shutter time, which really is all we need.
    
    SETUP_struct = [
    "uint16" "FrameRate16";
    "uint16" "Shutter16";
    "uint16" "PostTrigger16";
    "uint16" "FrameDelay16";
    "uint16" "AspectRatio";
    "uint16" "Res7";
    "uint16" "Res8";
    "uint8" "Res9";
    "uint8" "Res10";
    "uint8" "Res11";
    "uint8" "TrigFrame";
    "int8" "Res12";    
    
    
    ];
    
    
    s = size(SETUP_struct, 1);
    for i = 1:s
        C=setfield(C,SETUP_struct(i,2),fread(fileID,1,SETUP_struct(i,1)));
    end


    C.DescriptionOld = [];
    for i = 1:MAXLENDESCRIPTION_OLD
        C.DescriptionOld = [C.DescriptionOld fread(fileID,1,"char")];
    end

    SETUP_struct_2 = [
    "uint16" "Mark";
    "uint16" "Length";
    "uint16" "Res13";
    "uint16" "SigOption";
    "int16" "BinChannels";
    "uint8" "SamplesPerImage";
    
    ];

    for i = 1:size(SETUP_struct_2, 1)
        C=setfield(C,SETUP_struct_2(i,2),fread(fileID,1,SETUP_struct_2(i,1)));
    end

    %there's more data in there, sure, but this is as far as I will go for
    %now.
    
    fclose(fileID); %close the file once we are done with it
end