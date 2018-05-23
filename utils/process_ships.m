
% reset
clear;
close all;
warning off;

% % define paths % %
pathtosioread = '';
pathtodata = '../../project/SCE17/acoustic/SCE17_VLA2_sio/';
load('InterpShips_SCE17.mat');
addpath(genpath(pathtosioread));

savepath = '';
process_method = 'time';

% % define parameters % %
fs = 25000; % sampling rate
N = 16; % # of hydrophones

% % load data % %
ships = fieldnames(Ships);
load('preloaded');

files = dir('ranges/input_*');
ind = [];
xlm = [];
for jj = 1:length(index)
   S{jj} = ships{index(jj)}; 
end
for ii = 1:length(files)
    I = strmatch(files(ii).name(8:(end-9)),S);
    ind = [ind, index(I)];
    xlm = [xlm; xlims(I,:)];
end

% % delimit data % %
index = ind;
xlims = xlm;

%% Save as frequency-domain pressures % %
if strcmp(process_method,'frequency')
nfft = fs;
snapshot_avg = 1; % # snapshots to average, in seconds
F1 = 50; % bottom frequency
F2 = 200; % top frequency 
df = floor(3 / (fs/nfft)); % desired freq. spacing, in bins
f = [0:fs/nfft:(fs/2-fs/nfft),-fs/2:fs/nfft:-fs/nfft];
f_ind = find(f>=F1 & f<=F2);
f_ind = f_ind(1:df:end);
for ii = 1:length(index) % loop over selected ships
    clear output outclc
    disp(['Ship: ' ships{index(ii)}]);
    [~,Imin] = min(abs(Ships.(ships{index(ii)}).dtime(xlims(ii,1)) - ...
        Ships.(ships{index(ii)}).dnum));
    [~,Imax] = min(abs(Ships.(ships{index(ii)}).dtime(xlims(ii,2)) - ...
        Ships.(ships{index(ii)}).dnum));
    raw_xlims(ii,:) = [Imin, Imax];
    

    % create a time string for extracting data file names
    dnum_start = Ships.(ships{index(ii)}).dtime(xlims(ii,1));
    dnum_end = Ships.(ships{index(ii)}).dtime(xlims(ii,2));
    jd = floor(dnum_start-datenum(2017,1,1)+1);
    if floor(dnum_end-datenum(2017,1,1)+1) ~= jd
        ds = datestr(datenum(datenum(2017,1,jd,hour(dnum_start),minute(dnum_start),0):minutes(1):datenum(2017,1,floor(dnum_end-datenum(2017,1,1)+1),hour(dnum_end),minute(dnum_end),0))); 
    else
        ds = datestr(datenum(datenum(2017,1,jd,hour(dnum_start),minute(dnum_start),0):minutes(1):datenum(2017,1,jd,hour(dnum_end),minute(dnum_end),0))); 
    end
    
    % update and delimit label vectors
    range = [floor(Ships.(ships{index(ii)}).range(xlims(ii,1):xlims(ii,2))*100)/100;...
    Ships.(ships{index(ii)}).dtime(xlims(ii,1):xlims(ii,2))]; % delimit range and time vectors

    % load and process data
    tic;
    disp('Processing....')
    S = size(ds,1); % number of minutes
    L = (60*fs/nfft-snapshot_avg+1); % number of segments, after averaging
    parfor dd = 1:S
        hrs = ds(dd,13:14);
        mins = ds(dd,16:17);
        name = ['RAVA02.170' num2str(jd) hrs mins '00.000.sio'];
        
        % check if file exists in acoustic folder
        if exist([pathtodata name], 'file')==2
           x = sioread([pathtodata name],1,0,0);
        else
            disp('Sorry, this file does not exist.');
            pause(2);
            continue;
        end

        % account for partial records
        if dd==1
            xstr = datestr(dnum_start);
            secs = str2double(xstr(19:20));
            if secs~=0
                x = x(floor(secs*fs):end,:);
            end
        elseif dd==S
            xstr = datestr(dnum_end);
            secs = str2double(xstr(19:20));
            if secs~=0
                x = x(1:(end-floor((60-secs-1)*fs)),:);
            end
        end
       
        % process data
        d = process_data(x,nfft,N,f_ind);
        for ii = 1:16
            output{dd}(:,:,ii) = squeeze(d(:,:,ii)).'; % dimensions: samples x frequencies x sensors
        end
    end
    disp(['     ' num2str(toc,'%.1f') ' s.']);
    
    % save, if any files found
    out = [];
    disp('Saving....');
    if exist('output')
        
        % concatenate all time data into a matrix
        for dd = 1:S
            out = [out; output{dd}];
        end    

        % name according to N/S orientation (re VLA2)
        %{/
        if ~sum(Ships.(ships{index(ii)}).lat(raw_xlims(ii,1):raw_xlims(ii,2))>VLA2(2))
            orien = 'S';
        elseif ~sum(Ships.(ships{index(ii)}).lat(raw_xlims(ii,1):raw_xlims(ii,2))<VLA2(2))
            orien = 'N';
        else
            disp('Warning: ship may cross VLA 2 latitutde. Saving as S.');
            orien = 'S';
        end
        
        % save files 
        save([savepath '' orien ships{index(ii)} '_VLA2'],'out');
        save([savepath 'range_' orien ships{index(ii)} '_VLA2'],'range');
        %}
        
    else 
       clc;
       continue;
    end     
    disp(['     ' num2str(toc,'%.1f') ' s.']);
    pause(1);
    clc;
end
end
%% Save as time-domain pressures
if strcmp(process_method,'time')
down_sample = 50;
for ii = 1:length(index) % loop over selected ships
    clear output outclc
    disp(['Ship: ' ships{index(ii)}]);
    [~,Imin] = min(abs(Ships.(ships{index(ii)}).dtime(xlims(ii,1)) - ...
        Ships.(ships{index(ii)}).dnum));
    [~,Imax] = min(abs(Ships.(ships{index(ii)}).dtime(xlims(ii,2)) - ...
        Ships.(ships{index(ii)}).dnum));
    raw_xlims(ii,:) = [Imin, Imax];
    

    % create a time string for extracting data file names
    dnum_start = Ships.(ships{index(ii)}).dtime(xlims(ii,1));
    dnum_end = Ships.(ships{index(ii)}).dtime(xlims(ii,2));
    jd = floor(dnum_start-datenum(2017,1,1)+1);
    if floor(dnum_end-datenum(2017,1,1)+1) ~= jd
        ds = datestr(datenum(datenum(2017,1,jd,hour(dnum_start),minute(dnum_start),0):minutes(1):datenum(2017,1,floor(dnum_end-datenum(2017,1,1)+1),hour(dnum_end),minute(dnum_end),0))); 
    else
        ds = datestr(datenum(datenum(2017,1,jd,hour(dnum_start),minute(dnum_start),0):minutes(1):datenum(2017,1,jd,hour(dnum_end),minute(dnum_end),0))); 
    end
    
    % update and delimit label vectors
    range = [floor(Ships.(ships{index(ii)}).range(xlims(ii,1):xlims(ii,2))*100)/100;...
    Ships.(ships{index(ii)}).dtime(xlims(ii,1):xlims(ii,2))]; % delimit range and time vectors

    % load and process data
    tic;
    disp('Processing....')
    S = size(ds,1); % number of minutes
    parfor dd = 1:S
        hrs = ds(dd,13:14);
        mins = ds(dd,16:17);
        name = ['RAVA02.170' num2str(jd) hrs mins '00.000.sio'];
        
        % check if file exists in acoustic folder
        if exist([pathtodata name], 'file')==2
           x = sioread([pathtodata name],1,0,0);
        else
            disp('Sorry, this file does not exist.');
            pause(2);
            continue;
        end

        % account for partial records
        if dd==1
            xstr = datestr(dnum_start);
            secs = str2double(xstr(19:20));
            if secs~=0
                x = x(floor(secs*fs):end,:);
            end
        elseif dd==S
            xstr = datestr(dnum_end);
            secs = str2double(xstr(19:20));
            if secs~=0
                x = x(1:(end-floor((60-secs-1)*fs)),:);
            end
        end
       
        % process data
        x = downsample(x, down_sample);
        output{dd} = x; % dimensions: samples x sensors
    end
    disp(['     ' num2str(toc,'%.1f') ' s.']);
    
    % save, if any files found
    out = [];
    disp('Saving....');
    if exist('output')
           
        % concatenate all time data into a matrix
        for dd = 1:S
            out = [out; output{dd}];
        end    
        
        % interpolate the range vector to the time vector
        xinterp = linspace(1,length(range),(fs/down_sample)*length(range));
        disp(['Length difference between range and date vector is ' num2str(length(xinterp)-size(out,1))]);
        out = out(1:(fs/down_sample)*length(range),:);
        time = range(2,:);
        range = interp1(1:length(range),range(1,:),xinterp,'linear');
        

        % name according to N/S orientation (re VLA2)
        %{/
        if ~sum(Ships.(ships{index(ii)}).lat(raw_xlims(ii,1):raw_xlims(ii,2))>VLA2(2))
            orien = 'S';
        elseif ~sum(Ships.(ships{index(ii)}).lat(raw_xlims(ii,1):raw_xlims(ii,2))<VLA2(2))
            orien = 'N';
        else
            disp('Warning: ship may cross VLA 2 latitutde. Saving as S.');
            orien = 'S';
        end
        
        % save files 
        save([savepath '' orien ships{index(ii)} '_VLA2'],'out');
        save([savepath 'range_' orien ships{index(ii)} '_VLA2'],'range','time');
        %}
        
    else 
       clc;
       continue;
    end     
    disp(['     ' num2str(toc,'%.1f') ' s.']);
    pause(1);
    clc;
end
end

%% functions % % %
function d = process_data(x,nfft,N,f_ind)
    M = floor(size(x,1)/nfft);
    win = hanning(nfft);
    Y = reshape(x(1:M*nfft,:),[nfft,M,N]);
    win = repmat(win,[1,M,N]);
    X = fft(Y.*win,[],1);
    d = 2*X(f_ind,:,:)./nfft;
end


