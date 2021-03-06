function [L,R] = labelgrid(DEM,varargin)

%LABELGRID landscape segmentation


p = inputParser;
p.FunctionName = 'labelgrid';
addParamValue(p,'minarea',1e6,@(x) isscalar(x));
addParamValue(p,'removeshortstreams',200,@(x) isscalar(x));
addParamValue(p,'seglength',2000);
addParamValue(p,'gradientcutoff',20,@(x) isscalar(x)); % gradient in [%]
parse(p,varargin{:});


FD = FLOWobj(DEM);
S  = STREAMobj(FD,'minarea',p.Results.minarea,'unit','map');
S  = removeshortstreams(S,p.Results.removeshortstreams);

G  = gradient8(DEM,'perc');

L  = (G>p.Results.gradientcutoff);
L.Z = medfilt2(L.Z,[11 11]);
L.Z = L.Z+1;
L.Z(isnan(DEM.Z)) = 0;


IX = streampoi(S,{'confl','outlet'},'ix');
D  = drainagebasins(FD,IX);
[~,~,ix] = unique([L.Z(:),D.Z(:)],'rows');
R  = GRIDobj(L);
R.Z = reshape(ix,R.size);

s  = streamorder(S);
% maximum stream order
maxs = max(s);

regioncounter = max(R)+1;
for r = 1:maxs
    Ss = modify(S,'streamorder',r);
    
    [label,ix] = labelreach(Ss,'seglength',p.Results.seglength);
    Ss = split(Ss,ix);
    
    Cs = STREAMobj2cell(Ss);
    for iter = 1:numel(Cs)
        I  = STREAMobj2GRIDobj(Cs{iter});
        I  = dilate(I,ones(3*r));
        L.Z(I.Z) = r+2;
        R.Z(I.Z) = regioncounter;
        regioncounter = regioncounter + 1;
    end
end

L.Z(isnan(DEM.Z)) = nan;
R.Z(isnan(DEM.Z)) = nan;
    

