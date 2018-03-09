% % reads in .xls files that Dave Ensberg saved (must re-save .csv as .xls
% formatted)
% Emma Ozanich, 12/14/2017

clear;clc
jds = 80:93; % days to load

label.name = {};
label.ID = [];
GPS = struct(); % for saving ship GPS
tick = 1;

for ii = 1:length(jds)
    tic
    disp(['Reading AIS data from "SCE17_J0' num2str(jds(ii)) '_AISonly"   ' num2str(ii)]);
    [~,~,raw{ii}] = xlsread(['SCE17_J0' num2str(jds(ii)) '_AISonly']);
    raw{ii} = raw{ii}(3:end,:); % remove headers
    
    if ii == 14
        % remove a bad row from this day
        raw{ii}(1385,:) = [];
    end

    % % % find names of ship
    for jj = 1:length(raw{ii})
        ID = raw{ii}{jj,8}; % define ship ID
        
        if ~sum(label.ID == ID) && (ID~=0) % if the ID is nonzero and is not present in the dictionary
            if ~isempty(strtrim(raw{ii}{jj,19})) % if a ship name is given
                % add ship to dictionary
                name = strtrim(raw{ii}{jj,19}); % find ship name
                name = name(~isspace(name)); % remove white space
                if contains(name,'-') || contains(name,'@') || contains(name,'/') || contains(name,'\')
                    % remove troublesome characters from names
                   name = strrep(name,'-','');
                   name = strrep(name,'@','');
                   name = strrep(name,'/','');
                   name = strrep(name,'\','');
                end    
            
                label.name = [label.name, name];
                label.ID = [label.ID, raw{ii}{jj,8}];
            end
        end
    end
    
    % name unnamed ships
    for jj = 1:length(raw{ii})
        ID = raw{ii}{jj,8}; % define ship ID

        if ~sum(label.ID == ID) && (ID~=0) % if the ID is nonzero and is not present in the dictionary
            if isempty(strtrim(raw{ii}{jj,19})) % if a ship name is NOT given
                % add ship to dictionary
                name = ['Unnamed' num2str(tick)];
                label.name = [label.name, name];
                label.ID = [label.ID, raw{ii}{jj,8}];
                tick = tick+1;
            end
        end
    end
    
    % assign gps and date values to each ships    
    for jj = 1:length(raw{ii})
        ID = raw{ii}{jj,8};
        if (sum(label.ID==ID) == 1)  && (raw{ii}{jj,9} ~=0)% ID is present in dictionary and lat/lon are available

            I = find(label.ID == ID);

            if strmatch(label.name{I}, fieldnames(GPS)) % if the ship field was previously defined
                % add lat,lon, and datenum to ship field
                GPS.(label.name{I}).lat = [GPS.(label.name{I}).lat, raw{ii}{jj,9}];
                GPS.(label.name{I}).lon = [GPS.(label.name{I}).lon, raw{ii}{jj,10}];
                GPS.(label.name{I}).dnum = [GPS.(label.name{I}).dnum, datenum(raw{ii}{jj,11},...
                    raw{ii}{jj,12},raw{ii}{jj,13},raw{ii}{jj,14},raw{ii}{jj,15},raw{ii}{jj,16})];
            else
                % define the ship field
                GPS(:).(label.name{I}).lat = raw{ii}{jj,9};
                GPS(:).(label.name{I}).lon = raw{ii}{jj,10};
                GPS(:).(label.name{I}).dnum = datenum(raw{ii}{jj,11},...
                    raw{ii}{jj,12},raw{ii}{jj,13},raw{ii}{jj,14},raw{ii}{jj,15},raw{ii}{jj,16});
            end 
        end
    end

    disp(['       ' num2str(toc) ' seconds.']);

end


save('SCE17_AllShips','GPS','label');


%% Plot the ships' trajectories daily
load('SCE17_AllShips');
ploton = 1; % plot ship paths
dnum = [datenum(2017,1,84)];%,datenum(2017,1,79,4,20,59)];
[Ships,L] = plotdailyAIS(dnum,GPS,label,ploton);

VLA1 = [70+35.827/60,40+28.207/60]; % location of VLA1 at deployment
VLA2 = [70+31.679/60,40+26.557/60]; % location of VLA2 at deployment
hold on;
load('../../SCE2017_FFI/Flatlon.mat');
s1 = scatter(VLA1(1),VLA1(2),100,'kx');
s2 = scatter(VLA2(1), VLA2(2),100, 'rx');
s3 = scatter(-PAlon(1),PAlat(1),75,'yo','filled');

L.String{end} = 'FFI HLA';
L.String{end-1} = 'SIO VLA 2';
L.String{end-2} = 'SIO VLA 1';

xlim([70.4 70.8]);
ylim([40.4 40.7]);
% % % % COMPUTE AZIMUTH AND RANGE COVERAGE FOR A GIVEN DAY % % % %

return;
%% Compute and save the azimuth labels
names = {'YMUNANIMITY'};%,'BRITISHSERENITY','MAERSKSINGAPORE','Unnamed5'};
HLA = [70.4557,40.4983];

for jj = 1:length(names)
    clear range thetas label D
    d1 = datestr(Ships.(names{jj}).dnum(1));
    d2 = datestr(Ships.(names{jj}).dnum(end));
    l1 = datenum(2017,3,25,str2num(d1(13:14)),round((str2num(d1(16:17)) - mod(str2num(d1(16:17)),30))),0);
    r2 = round((str2num(d2(16:17)) - mod(str2num(d2(16:17)),30)))+30;
    l2 = datenum(2017,3,25,str2num(d2(13:14)),r2,0);

    gpi = find(Ships.(names{jj}).dnum >= l1 & Ships.(names{jj}).dnum <=l2);
    kk=0;
    while kk < length(Ships.(names{jj}).dnum)
        kk = kk+1;
        % remove weird GPS points
        if kk>1 & (Ships.(names{jj}).dnum(gpi(kk)) < Ships.(names{jj}).dnum(gpi(kk-1)))
            Ships.(names{jj}).dnum(gpi(kk))  = [];
            gpi = find(Ships.(names{jj}).dnum >= l1 & Ships.(names{jj}).dnum <=l2);
        end
         [range(kk),thetas(kk)] = ...
         distance(VLA2(2), VLA2(1), Ships.(names{jj}).lat(gpi(kk)),...
            -Ships.(names{jj}).lon(gpi(kk)),[6378.273 0.0034],'degrees');
    end
    
   % thetas(thetas>=90 & thetas<=270) =  180 -thetas(thetas>=90 & thetas<=270);
   % thetas(thetas>=270) = thetas(thetas>=270) - 360;
    
%    load(['HLA_Mar23_' names{jj} '.mat']);
    l1 = datenum(2017,3,25,9,30,0);
    l2 = datenum(2017,3,25,10,0,0);
    dlin = linspace(l1, l2, 1800);%size(D,1));
    %
    [~,I] = unique(Ships.(names{jj}).dnum(gpi));
    %
    label = interp1(Ships.(names{jj}).dnum(gpi(I)), range(I), dlin,'spline','extrap');
    label = [label,interp1(Ships.(names{jj}).dnum(gpi(I)), thetas(I), dlin,'spline','extrap')];
    
    figure(3);
    p(jj) = plot(dlin,label(length(label)/2+1:end),'linewidth',2);
    hold on;
    s(jj) = scatter(Ships.(names{jj}).dnum(gpi), thetas,'filled');
    
    figure(4);
    p(jj) = plot(1:length(label)/2,label(1:length(label)/2),'linewidth',2);
    hold on;
    %s(jj) = scatter(Ships.(names{jj}).dnum(gpi), range,'filled');
    
    save(['label_VLA_Mar25_' names{jj} '.txt'],'-ascii','label');
end

