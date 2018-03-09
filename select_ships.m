% selects ship paths for machine learning
% Emma Ozanich, 12/14/2017

 % % LOAD % %
load('SCE17_AllShips');
PLOT = true;
JD = 84; % not used currently
ploton = 1; % plot ship paths

VLA1 = [70+35.827/60,40+28.207/60]; % location of VLA1 at deployment
VLA2 = [70+31.679/60,40+26.557/60]; % location of VLA2 at deployment
load('../../SCE2017_FFI/Flatlon.mat');

 % % Find ships south of array % %
 Ships = struct();
 g = fieldnames(GPS);
 pictick = 1;
 for ii = 1:length(g)
     if sum(GPS.(g{ii}).lat < VLA2(2)) == length(GPS.(g{ii}).lat)
         Ships.(g{ii}) = GPS.(g{ii});
         
     % % Compute ranges and azimuths for south ships % %    
         [Ships.(g{ii}).range, Ships.(g{ii}).azimuth] = distance(VLA2(2), VLA2(1), Ships.(g{ii}).lat, -Ships.(g{ii}).lon,...
            [6378.273 0.0034],'degrees');
         Ships.(g{ii}).dtime = datenum(Ships.(g{ii}).dnum(1):seconds(1):Ships.(g{ii}).dnum(end));
         
         if PLOT
            figure(pictick);
            scatter(Ships.(g{ii}).dnum,Ships.(g{ii}).range);
         end
         
         % interpolate
         Ships.(g{ii}).range = interp1(Ships.(g{ii}).dnum, Ships.(g{ii}).range, Ships.(g{ii}).dtime,'linear');
         Ships.(g{ii}).azimuth = interp1(Ships.(g{ii}).dnum, Ships.(g{ii}).azimuth, Ships.(g{ii}).dtime,'linear');
         
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
         
     else
         disp('The ship traverses north of VLA2.');
     end  
 end