function [Ships,leghandle] = plotdailyAIS(dnum,GPS, label, ploton)
% % % code to plot all the ships' GPS on a given experiment day
% Emma Ozanich, 12/14/2017


% date to plot
%dnum = datenum(2017,1,jd);

Ships = struct();
table = {};

%for dd = 1:length(dnum)
for ii = 1:length(label.name)
    if length(dnum)>1
        I = find(GPS.(label.name{ii}).dnum >= dnum(1) & GPS.(label.name{ii}).dnum <=dnum(end));
%I = find(floor(GPS.(label.name{ii}).dnum) >= dnum(1) & floor(GPS.(label.name{ii}).dnum <=dnum(end)));
    else
        I = find(floor(GPS.(label.name{ii}).dnum) == dnum);
    end
    if ~isempty(I)
       Ships(:).(label.name{ii}).lat = GPS.(label.name{ii}).lat(I);
       Ships(:).(label.name{ii}).lon = GPS.(label.name{ii}).lon(I);
       Ships(:).(label.name{ii}).dnum = GPS.(label.name{ii}).dnum(I);         
       
        % for creating a table later
        table = [table; {label.name{ii},datestr(Ships.(label.name{ii}).dnum(1),'HH:MM:SS'),...
            datestr(Ships.(label.name{ii}).dnum(end),'HH:MM:SS')}]; 
    end
    
end 
    
if ploton
    % for now, (optionally) plot the bathymetry. Bathymetry data is from
    % NOAA coastal relief model at https://maps.ngdc.noaa.gov/viewers/wcs-client/
    load('SCE17_Bathymetry');
    figure();
    surf(abs(bathylon),bathylat,Bathymetry);
    cb = colorbar;
    shading flat;
    hold on; hold on;
    view(2);
    xlim([70 71.6]);
    ylim([40 41.7]);
    caxis([-100 0]);
    for ii = 1:length(cb.Ticks)
       cb.TickLabels{ii} = abs(str2num(cb.TickLabels{ii})); 
    end
    ylabel(cb,'Bathymetry (m)');
    
    ships = fieldnames(Ships);
    colors = jet(length(ships));
    view(2);
    xlim([70 71.6]);
    ylim([40 41.7]);
    caxis([-100 0]);
    for ii = 1:length(cb.Ticks)
       cb.TickLabels{ii} = abs(str2num(cb.TickLabels{ii})); 
    end
    ylabel(cb,'Bathymetry (m)');
    
    ships = fieldnames(Ships);
    colors = jet(length(ships));
    
    for mm =  1:length(ships)
        p(mm) = plot(abs(Ships.(ships{mm}).lon),Ships.(ships{mm}).lat, 'color',colors(mm,:),'linewidth',2);
        hold on;
    end
    
    if length(dnum)==1
        title(['Ship paths on ' datestr(dnum,'mmm dd, yyyy')]);
    else
        title(['Ship paths on ' datestr(dnum(1),'mmm dd, yyyy') '-' datestr(dnum(end),'mmm dd, yyyy')]);
    end
    xlabel('Longitude (\circ W)');
    ylabel('Latitude (\circ N)');
  %  legend(p,ships);
    
    T = cell2table(table, 'VariableNames',{'ShipName','start_time','end_time'});
  %  T1 = cell2table(table(1:floor(length(table)/2),:), 'VariableNames',{'ShipName','start_time','end_time'});
  %  T2 = cell2table(table((floor(length(table)/2)+1):end,:),'VariableNames',{'ShipName','start_time','end_time'});
    figure();
     uitable('Data',T{:,:},'ColumnName',T.Properties.VariableNames,...
    'RowName',T.Properties.RowNames,'Units', 'Normalized', 'Position',[0, 0, 1, 1]);
  %  uitable('Data',T1{:,:},'ColumnName',T1.Properties.VariableNames,...
  %  'RowName',T1.Properties.RowNames,'Units', 'Normalized', 'Position',[0, 0, 1, 1]);

   % figure(3);
   % uitable('Data',T2{:,:},'ColumnName',T2.Properties.VariableNames,...
   % 'RowName',T2.Properties.RowNames,'Units', 'Normalized', 'Position',[0, 0, 1, 1]);
   
   
 %  figure(1);
   leghandle = legend(p,T{:,1});
end

end



