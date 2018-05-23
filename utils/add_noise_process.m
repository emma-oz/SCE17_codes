
% load data
filepath = 'SCE17_source_tow/';
load([filepath 'SCE17_simulation_76.mat']);
p = squeeze(pm{1});
savepath = 'simulations/';

% sampling parameters
SNR = 15; % dB
frequency_index = 1:51; % from 50-200 Hz with 3 Hz bins (51 freqs)
n_freq = length(frequency_index);
range_index = 1:1000; % from 0 - 1.5km with 10m bins
p = p(:,1:1000,frequency_index);
root = [42,43]; % random seeds

% normalize data, define random noise level (rnl)
p = p./max(abs(p(:)));
rnl = 10^(-SNR/20)*norm(squeeze(p(:,end,end)));
processor = '1D'; % 1D avg case is not yet ready



switch processor
    % % for the cross-spectral method with 1D inputs (FNN or 1D CNN)
    case '1D'
    for n = 1:length(root)
        tic;
        out = [];
        parfor ii = 1:size(p,2)
            f_out = [];
            for ff = 1:size(p,3)
                rng(root(n));
                d = squeeze(p(:,ii,ff));
                d = d + rnl*(randn(size(p,1),1) + 1i*randn(size(p,1),1));
                d = d./norm(d);

                C = d*d';
                feat = triu(C).';
                feature = [real(feat(feat~=0)).',imag(feat(feat~=0)).'];
                f_out = [f_out, feature];
            end
            out(ii,:) = f_out;
        end
        save([savepath 'SCE17_sim_' num2str(SNR) 'dB_' num2str(root(n))],'out');
        toc
    end

    % % for the pressure method with 2D inputs (2D cnn)
    case '2D'
    for n = 1:length(root)
        tic;
        out = [];
        parfor ii = 1:size(p,2)
            f_out_real = [];
            f_out_imag = [];
            out = [];

            for ff = 1:size(p,3)
                rng(root(n));
                d = squeeze(p(:,ii,ff));
                d = d + rnl*(randn(size(p,1),1) + 1i*randn(size(p,1),1));

                f_out_real = [f_out_real ,real(d)];
                f_out_imag = [f_out_imag, imag(d)];
            end
            out(ii,:) = [f_out_real,f_out_imag];
        end
        out = reshape(out,[size(out,1),size(out,2),size(out,3)/2,2]);
       % out(:,:,:,1) = tmp(:,:,1:n_freq);
       % out(:,:,:,2) = tmp(:,:,(n_freq+1):end);
       save([savepath 'SCE17_sim_' num2str(SNR) 'dB_' num2str(root(n))],'out');
        toc
    end

    % % for the cross-spectral method with 1D inputs and snapshot averaging
    % NOT YET READY
    case '1D_avg'
        nsnap = 5; % s, snapshots to average

        for n = 1:length(root)
            csdm = 0;
            for ii = 1:size(p,2)
                rng(root(n));
                d = squeeze(p(:,ii,ff));
                d = d + rnl*(randn(size(p,1),1) + 1i*randn(size(p,1),1));
                d = d./norm(d);

                cdsm = d*d' + csdm;
                if mod(ii,nsnap)
                    csdm_avg
                end
            end
        end
        for n = 1:length(root)
            tic;
            out = [];
            parfor ii = 1:size(p,2)
                f_out = [];
                for ff = 1:size(p,3)
                    rng(root(n));
                    d = squeeze(p(:,ii,ff));
                    d = d + rnl*(randn(size(p,1),1) + 1i*randn(size(p,1),1));
                    d = d./norm(d);

                    C = d*d';


                    feat = triu(C).';
                    feature = [real(feat(feat~=0)).',imag(feat(feat~=0)).'];
                    f_out = [f_out,feature./max(abs(feature(:)))];

                end
                out(ii,:) = f_out;%[f_out_real,f_out_imag];
            end
           % all_out(:,:,:,1) = out(:,:,1:201);
           % all_out(:,:,:,2) = out(:,:,202:end);
           %all_out = out;
          % save(['simulations/SCE17_sim_' num2str(SNR) 'dB_' num2str(root(n))],'out');
           save(['SCE17_sim_' num2str(root(n))],'out');
           toc
        end
    
end



