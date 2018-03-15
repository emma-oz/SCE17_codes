%{/
clear;
close all;

pathtosioread = ''; %where's the sioread function?
pathtodata = '../../project/SCE17/acoustic/SCE17_VLA2_sio/';
load('InterpShips_SCE17.mat');
addpath(genpath(pathtosioread));
savepath = '';

ships = fieldnames(Ships);

% % % select which ships tracks to load (using GPS) % % %
index = [];
xlims = [];
for ii = 1:length(ships)
   if ~sum(Ships.(ships{ii}).dtime >= datenum(2017,1,82,19,0,0)) % limitations of acoustics data
      continue; 
   else
       posind = find(Ships.(ships{ii}).dtime >= datenum(2017,1,82,19,0,0));
       Ships.(ships{ii}).range = Ships.(ships{ii}).range(posind);
       Ships.(ships{ii}).azimuth = Ships.(ships{ii}).azimuth(posind);
       Ships.(ships{ii}).dtime = Ships.(ships{ii}).dtime(posind);
       postind = find(Ships.(ships{ii}).dnum >= datenum(2017,1,82,19,0,0));
       Ships.(ships{ii}).lat = Ships.(ships{ii}).lat(postind);
       Ships.(ships{ii}).lon = Ships.(ships{ii}).lon(postind);
       Ships.(ships{ii}).R = Ships.(ships{ii}).R(postind);
       Ships.(ships{ii}).A = Ships.(ships{ii}).A(postind);
       Ships.(ships{ii}).dnum = Ships.(ships{ii}).dnum(postind);
   end
       
   plot(Ships.(ships{ii}).dtime, Ships.(ships{ii}).range);
   hold on;
   scatter(Ships.(ships{ii}).dnum, Ships.(ships{ii}).R,'filled');
   ylabel('Range (km)');
   xlabel('Date, Time');
   datetick('keeplimits');
   title(['Ship name: ' ships{ii}]);
   legend('Interpolated range','Raw range');
   s = input('Do you want to use this ship track?  (Y/N)','s');
   if strcmp(s,'Y')
      index = [index; ii]; 
      s = input('Do you want to use the whole time? (Y/N)','s');
      if strcmp(s,'N')
          disp('Select two points on the plot: starting point and ending point.');
          dg = ginput(2);
          xlim([dg(1,1) dg(2,1)]);
          s = input('Does that look better? (Y/N)','s');
          if strcmp(s,'N')
              disp('Ok, try again...');
              dg = ginput(2);
              disp('Heres what you get:');
              xlim([dg(1,1) dg(2,1)]);
              pause(2);
              disp('Moving on to next ship.');
          end
          [~,I1] = min(abs(dg(1,1) - Ships.(ships{ii}).dtime));
          [~,I2] = min(abs(dg(2,1) - Ships.(ships{ii}).dtime));
          xlims = [xlims; I1,I2];
      else
         xlims = [xlims; 1, length(Ships.(ships{ii}).dtime)]; 
      end
   elseif strcmp(s,'N')
       s = input('Are you done? (Y/N)','s');
       if strcmp(s,'Y')
           disp('Thanks, closing program...');
           break;
       end
   end
   clf;
   clc;
end
%}
%%
% % % load the tracks from Velella acoustic data VLA2 % % %
ii = 4;
dnum_start = Ships.(ships{index(ii)}).dtime(xlims(ii,1));
dnum_end = Ships.(ships{index(ii)}).dtime(xlims(ii,2));
jd = floor(dnum_start-datenum(2017,1,1)+1);

% create a time string for extracting data file names
if floor(dnum_end-datenum(2017,1,1)+1) ~= jd
    if minute(dnum_start)+1 == 60
        ds = datestr(datenum(datenum(2017,1,jd,hour(dnum_start)+1,0,0):minutes(1):datenum(2017,1,floor(dnum_end-datenum(2017,1,1)+1),hour(dnum_end),minute(dnum_end),0)));
    else
        ds = datestr(datenum(datenum(2017,1,jd,hour(dnum_start),minute(dnum_start)+1,0):minutes(1):datenum(2017,1,floor(dnum_end-datenum(2017,1,1)+1),hour(dnum_end),minute(dnum_end),0))); 
    end
else
    if minute(dnum_start)+1 == 60
        ds = datestr(datenum(datenum(2017,1,jd,hour(dnum_start)+1,0,0):minutes(1):datenum(2017,1,jd,hour(dnum_end),minute(dnum_end),0)));
    else
        ds = datestr(datenum(datenum(2017,1,jd,hour(dnum_start),minute(dnum_start)+1,0):minutes(1):datenum(2017,1,jd,hour(dnum_end),minute(dnum_end),0))); 
    end  
end

% load and process the data
fs = 25000; % sampling rate
N = 16; % # of hydrophones
nfft = fs;
snapshot_avg = 1; % # snapshots to average, in seconds
F1 = 50; % bottom frequency
F2 = 200; % top frequency 
df = floor(3 / (fs/nfft)); % desired freq. spacing, in bins

f = [0:fs/nfft:(fs/2-fs/nfft),-fs/2:fs/nfft:-fs/nfft];
f_ind = find(f>=F1 & f<=F2);
f_ind = f_ind(1:df:end);

S = size(ds,1); % number of minutes
L = (60*fs/nfft-snapshot_avg+1);
%D = zeros(S*60*fs/nfft,N,length(f_ind)); % initialize data matrix
output = zeros(S*L, N*(N+1)*length(f_ind)); % initialize feature matrix

tic;
for dd = 1:S
    tic;
    hrs = ds(dd,13:14);
    mins = ds(dd,16:17);

    name = ['RAVA02.170' num2str(jd) hrs mins '00.000.sio'];
    %ssh2_struct = ssh2_config('velella.ucsd.edu',username,password,22);
    %x = scp_get(ssh2_struct,name,'','../../project/SCE17/acoustic/SCE17_VLA2_sio/');
    x = sioread([pathtodata name],1,0,0);
    delete('RAVA02*');
    % process data
    d = process_data(x,nfft,N,f_ind);
   % D([1:(60*fs/nfft)]+(dd-1)*60*fs/nfft,:,:) = d; % dimensions: samples x sensors x frequencies
    
    % create input feature matrix
    output([1:L] + (dd-1)*L,:) = generate_features(d,snapshot_avg,nfft,fs);
    %output{dd} = generate_features(d,snapshot_avg,nfft,fs);
    toc
end
toc

% save
save([savepath 'input_' ships{ii} '_VLA2'],'-ascii',output);

function d = process_data(x,nfft,N,f_ind)
    M = floor(size(x,1)/nfft);
    win = hanning(nfft);
    Y = reshape(x,[M,N,nfft]);
    win = reshape(win.',[1,1,nfft]);
    win = repmat(win,[M,N,1]);
    X = fft(Y.*win,[],3);
    d = X(:,:,f_ind);
end

function features = generate_features(d,snap_avg,nfft,fs)
    snap_avg = floor(snap_avg*nfft/fs); % convert to bins
    csdm = zeros(size(d,1),size(d,2),size(d,2),size(d,3));
    csdm_avg = zeros(size(d,1)-snap_avg, size(d,2),size(d,2),size(d,3));
    for tt = 1:size(d,1)
        for ff = 1:size(d,3)
            dat = squeeze(d(tt,:,ff)).';
            dat = dat./norm(dat);
            csdm(tt,:,:,ff) = dat*dat';
        end
    end
    
    % snapshot averaging and feature creation
    features = zeros(size(d,1)-snap_avg+1,(size(d,2)+1)*size(d,2)*size(d,3));
    for tt = 1:(size(d,1)-snap_avg+1)
        csdm_avg(tt,:,:,:) = mean(csdm(tt:(tt+snap_avg-1),:,:,:),1); 
        feat = [];
        for ff = 1:size(d,3)
            for rr = 1:size(d,2)
                feat = [feat,squeeze(csdm_avg(tt,rr,rr:end,ff)).'];
            end
        end
        feat = [real(feat), imag(feat)];
        feat = feat./max(abs(feat(:)));
        features(tt,:) = feat;
    end
    
    
end

