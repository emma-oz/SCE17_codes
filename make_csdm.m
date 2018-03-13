clear; clc;

fselect = 1:3:150; % frequency indices, for freq = 75:1:350 Hz vector
path = '../../../Desktop/SCE17_VLA_range/data1/'; % path to data

files = dir([path,'VLA2*.mat']);

D = struct();
for fi=1:length(files)
    tic;
    fname = files(fi).name(1:end-4);
    data = load([path, fname]);
    D.(fname) = data.D;
    C = nan([size(D.(fname),2),size(D.(fname),2)]);
    features = nan([size(D.(fname),1),(size(D.(fname),2)+1)*(size(D.(fname),2))/2*2*length(fselect)]);
    for k = 1:size(D.(fname),1)
        ftick=0;
        tmp = [];
        for f = fselect
            C = D.(fname)(k,:,f).'*conj(D.(fname)(k,:,f));
            for r = 1:size(C,1)
                tmp = [tmp, C(r,r:end)];
            end
        end
        features(k,:) = [real(tmp),imag(tmp)];
    end
    
    save(['input_' fname '.txt'],'-ascii','features');
    toc
end

