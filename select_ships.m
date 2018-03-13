% selects ship paths for machine learning
% this basically just interpolates the gps data to consistent time vector
% Emma Ozanich, 12/14/2017

 % % LOAD % %
load('SCE17_AllShips');
PLOT = false;
JD = 84; % not used currently
ploton = 1; % plot ship paths

VLA1 = [70+35.827/60,40+28.207/60]; % location of VLA1 at deployment
VLA2 = [70+31.679/60,40+26.557/60]; % location of VLA2 at deployment
load('Flatlon.mat');

 % % Find ships % %
 Ships = struct();
 g = fieldnames(GPS);
 pictick = 1;
 for ii = 1:length(g)
     tic;
   %  if sum(GPS.(g{ii}).lat < VLA2(2)) == length(GPS.(g{ii}).lat)
         Ships.(g{ii}) = GPS.(g{ii});
         
     % % Compute ranges and azimuths for south ships % %    
         [Ships.(g{ii}).range, Ships.(g{ii}).azimuth] = distance(VLA2(2), -VLA2(1), Ships.(g{ii}).lat, Ships.(g{ii}).lon,...
            [6378.273 0.0034],'degrees');
         Ships.(g{ii}).dtime = datenum(Ships.(g{ii}).dnum(1):seconds(1):Ships.(g{ii}).dnum(end));
         
         if PLOT
            figure(pictick);
            scatter(Ships.(g{ii}).dnum,Ships.(g{ii}).range);
         end
         
         % interpolate
         % remove non-unique points
         dunique = unique(Ships.(g{ii}).dnum);
         Ships.(g{ii}).R = Ships.(g{ii}).range;
         Ships.(g{ii}).A = Ships.(g{ii}).azimuth;
         if length(dunique)~=length(Ships.(g{ii}).dnum)
            for jj = 1:length(dunique)
                rng(jj) = mean(Ships.(g{ii}).range(Ships.(g{ii}).dnum == dunique(jj)));
                azz(jj) = mean(Ships.(g{ii}).azimuth(Ships.(g{ii}).dnum == dunique(jj)));
            end
            Ships.(g{ii}).R = rng;
            Ships.(g{ii}).A = azz;
            clear rng azz
         end
  
         
         Ships.(g{ii}).range = interp1(dunique, Ships.(g{ii}).R, Ships.(g{ii}).dtime,'linear');
         Ships.(g{ii}).azimuth = interp1(dunique, Ships.(g{ii}).A, Ships.(g{ii}).dtime,'linear');
         
         if PLOT
            hold on;
            plot(Ships.(g{ii}).dtime, Ships.(g{ii}).range);
            legend('GPS measurements','Interp. range points');
            datetick('keeplimits');
            
            dsr = datestr(Ships.(g{ii}).dnum);
            title(g{ii});
            xlabel(['Time (' dsr(1,4:6) ' ' dsr(1,1:2) ' 2017)']);
            ylabel('Range, receiver to ship (km)');

            pictick = pictick+1;
         end
         toc
    % else
     %    disp('The ship traverses north of VLA2.');
   %  end  
 end