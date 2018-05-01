
% reset
clear;
close all;
warning off;

SELECT_SHIPS = True; % set True if you want to select new ship paths, False otherwise

% % define paths % %
pathtosioread = '';
pathtodata = '../../project/SCE17/acoustic/SCE17_VLA2_sio/';
load('InterpShips_SCE17.mat');
addpath(genpath(pathtosioread));
savepath = '';

% % % data selection % % %
ships = fieldnames(Ships);
if SELECT_SHIPS
    index = [];
    xlims = [];
    for ii = 1:length(ships)

        % don't run if outside hydrophone recording period
       if ~sum(Ships.(ships{ii}).dtime >= datenum(2017,1,82,19,0,0)) || ...
        ~sum(Ships.(ships{ii}).dtime <=datenum(2017,1,92,19,0,0)) 
          continue; 

       else
           % delimit raw data
           rawbin = (Ships.(ships{ii}).dnum >= datenum(2017,1,82,19,0,0)) & ...
               (Ships.(ships{ii}).dnum <=datenum(2017,1,92,19,0,0));     
           Ships.(ships{ii}).lat = Ships.(ships{ii}).lat(rawbin);
           Ships.(ships{ii}).lon = Ships.(ships{ii}).lon(rawbin);

           % delimit interpolated data
           interpbin = ((Ships.(ships{ii}).dtime >= datenum(2017,1,82,19,0,0)) & ...
                (Ships.(ships{ii}).dtime <=datenum(2017,1,92,19,0,0)));
           Ships.(ships{ii}).range = Ships.(ships{ii}).range(interpbin);
           Ships.(ships{ii}).azimuth = Ships.(ships{ii}).azimuth(interpbin);
           Ships.(ships{ii}).dtime = Ships.(ships{ii}).dtime(interpbin);      
       end

       % % plotting for GUI ship track selection % %
       [ind, xl, xlr] = select_ships(Ships.(ships{ii}), ships{ii}, rawbin, ii);
       clf; clc;
       if isempty(ind); break; end % end the loop if user is done 
       index = [index; ind];
       xlims = [xlims; xl]; % interpolated endpoints
       raw_xlims = [raw_xlims; xlr]; % raw data endpoints

    end
    close all;
    clc;
    save('preloaded','index','xlims')
    
else
    load('preloaded');      
end

% % % data loading & processing % % %

% % define parameters
fs = 25000; % sampling rate
N = 16; % # of hydrophones
nfft = fs;
snapshot_avg = 1; % # snapshots to average, in seconds
F1 = 50; % bottom frequency
F2 = 200; % top frequency 
df = floor(1 / (fs/nfft)); % desired freq. spacing, in bins
f = [0:fs/nfft:(fs/2-fs/nfft),-fs/2:fs/nfft:-fs/nfft];
f_ind = find(f>=F1 & f<=F2);
f_ind = f_ind(1:df:end);

for ii = 1:length(index) % loop over selected ships
    clear output out
    disp(['Ship: ' ships{index(ii)}]);

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
        %D{dd} = d; % dimensions: samples x frequencies x sensors
    
        % create input feature matrix
        output{dd} = generate_features(d,snapshot_avg,nfft,fs);
        %output{dd} = abs(d(:,:));
    end
    disp(['     ' num2str(toc,'%.1f') ' s.']);
    
    % save, if any files found
    out = [];
    disp('Saving....');
    if exist('output')
        for dd = 1:S
            out = [out; output{dd}];
        end        
        
        % name according to N/S orientation (re VLA2)
        if ~sum(Ships.(ships{index(ii)}).lat(raw_xlims(ii,1):raw_xlims(ii,2))>VLA2(2))
            orien = 'S';
        elseif ~sum(Ships.(ships{index(ii)}).lat(raw_xlims(ii,1):raw_xlims(ii,2))<VLA2(2))
            orien = 'N';
        else
            disp('Warning: ship may cross VLA 2 latitutde. Saving as S.');
            orien = 'S';
        end
        
        save([savepath 'input_' orien ships{index(ii)} '_VLA2'],'out');
        save([savepath 'range_' orien ships{index(ii)} '_VLA2'],'range');
        
    else 
       pause(1);
       clc;
       continue;
    end     
    disp(['     ' num2str(toc,'%.1f') ' s.']);
    pause(1);
    clc;
end

% % % functions % % %

function [index, x_lims, raw_xlims] = select_ships(ship, shipname, raw_index, ii)
   plot(ship.dtime, ship.range);
   hold on;
   scatter(ship.dnum(raw_index), ship.(raw_index),'filled');
   ylabel('Range (km)');
   xlabel('Date, Time');
   datetick('keeplimits');
   title(['Ship name: ' shipname]);
   legend('Interpolated range','Raw range');
   s = input('Do you want to use this ship track?  (Y/N)','s');
   
   if strcmp(s,'Y')
      index = ii; 
      s = input('Do you want to use the whole time? (Y/N)','s');
      if strcmp(s,'N')
          disp('Select two points on the plot: starting point and ending point.');
          dg = ginput(2);
          xlim([dg(1,1) dg(2,1)]);
          datetick('keeplimits');
          s = input('Does that look better? (Y/N)','s');
          if strcmp(s,'N')
              disp('Ok, select two more endpoints please...');
              dg = ginput(2);
              disp('Displaying your final selection.');
              xlim([dg(1,1) dg(2,1)]);
              datetick('keeplimits');
              pause(2);
              disp('Moving on to next ship.');
          end
          [~,I1] = min(abs(dg(1,1) - ship.dtime));
          [~,I2] = min(abs(dg(2,1) - ship.dtime));
          x_lims = [I1, I2];
          
          [~,Ia] = min(abs(dg(1,1) - ship.dnum));
          [~,Ib] = min(abs(dg(2,1) - ship.dnum));
          raw_xlims = [Ia, Ib];
      else
         x_lims = [1, length(ship.dtime)]; 
      end
   elseif strcmp(s,'N')
       s = input('Are you done? (Y/N)','s');
       if strcmp(s,'Y')
           index = [];
           x_lims = 0;
           disp('Thanks, closing program...');
           pause(1);
       end
   end
end

function d = process_data(x,nfft,N,f_ind)
    M = floor(size(x,1)/nfft);
    win = hanning(nfft);
    Y = reshape(x(1:M*nfft,:),[nfft,M,N]);
    win = repmat(win,[1,M,N]);
    X = fft(Y.*win,[],1);
    d = 2*X(f_ind,:,:)./nfft;
end

function features = generate_features(d,snap_avg,nfft,fs)
    snap_avg = floor(snap_avg*nfft/fs); % convert to bins
    csdm = zeros(size(d,2),size(d,3),size(d,3),size(d,1));
    csdm_avg = zeros(size(d,2)-snap_avg+1, size(d,3),size(d,3),size(d,1));
    for tt = 1:size(d,2)
        for ff = 1:size(d,1)
            dat = squeeze(d(ff,tt,:));
            dat = dat./norm(dat);
            csdm(tt,:,:,ff) = dat*dat';
        end
    end
    
    % snapshot averaging and feature creation
    features = zeros(size(d,2)-snap_avg+1,(size(d,3)+1)*size(d,3)*size(d,1));
    for tt = 1:(size(d,2)-snap_avg+1)
        csdm_avg(tt,:,:,:) = mean(csdm(tt:(tt+snap_avg-1),:,:,:),1); 
        feat = [];
        for ff = 1:size(d,1)
            for rr = 1:size(d,3)
                feat = [feat,squeeze(csdm_avg(tt,rr,rr:end,ff)).'];
            end
        end
        feat = [real(feat), imag(feat)];
        feat = feat./max(abs(feat(:)));
        features(tt,:) = feat;
    end
    
    
end

