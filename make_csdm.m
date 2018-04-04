clear; clc;

fselect = 1:151; % frequency indices, for freq = 75:1:350 Hz vector
path = '../../../Desktop/SCE17_source_tow/';%'../../../Desktop/SCE17_VLA_range/data1/'; % path to data

files = dir([path,'SCE17_simulation.mat']);

D = struct();
for fi=1:length(files)
    tic;
    fname = files(fi).name(1:end-4);
    data = load([path, fname]);
   % fname(18) = 'n';
   data.p = data.pm{1};
    D.(fname) = data.p;%m{1};
    C = nan([size(D.(fname),1),size(D.(fname),1)]);
    features = nan([size(D.(fname),2),(size(D.(fname),1)+1)*(size(D.(fname),1))/2*2*length(fselect)]);
    for k = 1:size(D.(fname),2)
        ftick=0;
        tmp = [];
        for f = fselect
            C = D.(fname)(:,k,f)*D.(fname)(:,k,f)';
            for r = 1:size(C,1)
                tmp = [tmp, C(r,r:end)];
            end
        end
        features(k,:) = [real(tmp),imag(tmp)];
    end
    
    save(['input_' fname],'features');
    toc
end

