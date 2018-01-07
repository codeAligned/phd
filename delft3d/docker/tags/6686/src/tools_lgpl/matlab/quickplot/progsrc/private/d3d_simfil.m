function varargout=d3d_simfil(FI,idom,field,cmd,varargin)
%D3D_SIMFIL QP support for Delft3D simulation configuration files.
%   Domains                 = XXXFIL(FI,[],'domains')
%   DataProps               = XXXFIL(FI,Domain)
%   Size                    = XXXFIL(FI,Domain,DataFld,'size')
%   Times                   = XXXFIL(FI,Domain,DataFld,'times',T)
%   StNames                 = XXXFIL(FI,Domain,DataFld,'stations')
%   SubFields               = XXXFIL(FI,Domain,DataFld,'subfields')
%   [TZshift   ,TZstr  ]    = XXXFIL(FI,Domain,DataFld,'timezone')
%   [Data      ,NewFI]      = XXXFIL(FI,Domain,DataFld,'data',subf,t,station,m,n,k)
%   [Data      ,NewFI]      = XXXFIL(FI,Domain,DataFld,'celldata',subf,t,station,m,n,k)
%   [Data      ,NewFI]      = XXXFIL(FI,Domain,DataFld,'griddata',subf,t,station,m,n,k)
%   [Data      ,NewFI]      = XXXFIL(FI,Domain,DataFld,'gridcelldata',subf,t,station,m,n,k)
%                             XXXFIL(FI,[],'options',OptionsFigure,'initialize')
%   [NewFI     ,cmdargs]    = XXXFIL(FI,[],'options',OptionsFigure,OptionsCommand, ...)
%
%   The DataFld can only be either an element of the DataProps structure.

%----- LGPL --------------------------------------------------------------------
%                                                                               
%   Copyright (C) 2011-2016 Stichting Deltares.                                     
%                                                                               
%   This library is free software; you can redistribute it and/or                
%   modify it under the terms of the GNU Lesser General Public                   
%   License as published by the Free Software Foundation version 2.1.                         
%                                                                               
%   This library is distributed in the hope that it will be useful,              
%   but WITHOUT ANY WARRANTY; without even the implied warranty of               
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU            
%   Lesser General Public License for more details.                              
%                                                                               
%   You should have received a copy of the GNU Lesser General Public             
%   License along with this library; if not, see <http://www.gnu.org/licenses/>. 
%                                                                               
%   contact: delft3d.support@deltares.nl                                         
%   Stichting Deltares                                                           
%   P.O. Box 177                                                                 
%   2600 MH Delft, The Netherlands                                               
%                                                                               
%   All indications and logos of, and references to, "Delft3D" and "Deltares"    
%   are registered trademarks of Stichting Deltares, and remain the property of  
%   Stichting Deltares. All rights reserved.                                     
%                                                                               
%-------------------------------------------------------------------------------
%   http://www.deltaressystems.com
%   $HeadURL: https://svn.oss.deltares.nl/repos/delft3d/tags/6686/src/tools_lgpl/matlab/quickplot/progsrc/private/d3d_simfil.m $
%   $Id: d3d_simfil.m 6624 2016-10-03 11:33:09Z jagers $

%========================= GENERAL CODE =======================================
T_=1; ST_=2; M_=3; N_=4; K_=5;

if nargin<2
    error('Not enough input arguments')
end

if nargin==2
    varargout={infile(FI,idom)};
    return
elseif ischar(field)
    switch field
        case 'options'
            [varargout{1:2}]=options(FI,cmd,varargin{:});
        case 'domains'
            varargout={domains(FI)};
        case 'dimensions'
            varargout={dimensions(FI)};
        case 'locations'
            varargout={locations(FI)};
        case 'quantities'
            varargout={quantities(FI)};
        case 'getparams'
            varargout={[]};
        case 'data'
            [varargout{1:2}]=getdata(FI,cmd,varargin{:});
    end
    return
else
    Props=field;
end

cmd=lower(cmd);
switch cmd
    case 'size'
        varargout={getsize(FI,idom,Props)};
        return
    case 'times'
        varargout={readtim(FI,idom,Props,varargin{:})};
        return
    case 'timezone'
        [varargout{1:2}]=gettimezone(FI,idom,Props);
        return
    case 'stations'
        varargout={readsts(FI,Props,0)};
        return
    case 'subfields'
        varargout={getsubfields(FI,Props,varargin{:})};
        return
    otherwise
        [XYRead,DataRead,DataInCell]=gridcelldata(cmd);
end

DimFlag=Props.DimFlag;

% initialize and read indices ...
idx={[] [] 0 0 0};
fidx=find(DimFlag);
subf=getsubfields(FI,Props);
if isempty(subf)    
    idx_subf = [];
    idx(fidx(1:length(varargin))) = varargin;
else
    idx_subf = varargin{1};
    idx(fidx(1:(length(varargin)-1))) = varargin(2:end);
end

sz = getsize(FI,idom,Props);
allidx=zeros(size(sz));
for i=1:length(sz)
    if DimFlag(i)
        if isempty(idx{i}) || isequal(idx{i},0) || isequal(idx{i},1:sz(i))
            idx{i}=1:sz(i);
            allidx(i)=1;
        end
    end
end

switch FI.FileType(9:end)
    case 'D-Flow1D'
        Name = Props.Name;
        if strcmp(Name,'water level boundary points') || ...
                strcmp(Name,'discharge boundary points') || ...
                strncmp(Name,'boundary points',15)
            Name = 'boundary points';
        elseif length(Name)>20 && strcmp(Name(end-19:end),'cross section points')
            Name = 'cross section points';
        elseif strncmp(Name,'structure points',16)
            Name = 'structure points';
        end
        switch Name
            case 'network'
                if ~isfield(FI,'ntwXY')
                    G = inifile('geti',FI.ntw,'Branch','geometry');
                    for i = length(G):-1:1
                        XY{i} = geom2xy(G{i});
                    end
                    FI.ntwXY = XY;
                end
                Ans.XY = FI.ntwXY(idx{M_});
            case 'nodes'
                X = inifile('geti',FI.ntw,'Node','x');
                Y = inifile('geti',FI.ntw,'Node','y');
                Ans.X = [X{idx{M_}}];
                Ans.Y = [Y{idx{M_}}];
                Ans.Val = inifile('geti',FI.ntw,'Node','id');
                Ans.Val = Ans.Val(idx{M_});
            case 'xyz cross section lines'
                % only xyz cross section definitions seem to have xCoors
                % and yCoors, so just request those.
                %
                %CT = inifile('geti',FI.crsLoc,'CrossSection','type');
                %CT = find(strcmp(CT,Props.varid));
                %iM = CT(idx{M_});
                %
                %CD = inifile('geti',FI.crsLoc,'CrossSection','definition');
                %CD = CD(iM);
                %
                %CDi = inifile('geti',FI.crsDef,'Definition','id');
                % the length of CDx and CDy will be shorter than CDi since
                % every cross section has an id, but not every cross
                % section has x/yCoors. Need to use the second output
                % argument of inifile('get' to figure out which coordinates
                % belong to which id.
                CDx = inifile('geti',FI.crsDef,'Definition','xCoors');
                CDy = inifile('geti',FI.crsDef,'Definition','yCoors');
                %
                %[isDef,iDef] = ismember(CD,CDi);
                %CDx = CDx(iDef);
                %CDy = CDy(iDef);
                for i = 1:length(CDx)
                    CDx{i} = [CDx{i}' CDy{i}'];
                end
                %
                Ans.XY = CDx;
            case 'cross section points'
                csId = inifile('geti',FI.crsLoc,'CrossSection','id');
                CT = inifile('geti',FI.crsLoc,'CrossSection','type');
                CT = find(strcmp(CT,Props.varid));
                iM = CT(idx{M_});
                %
                FI = check_crsXY(FI);
                %
                Ans.X = FI.crsXY(iM,1);
                Ans.Y = FI.crsXY(iM,2);
                Ans.Val = csId(iM);
            case 'lateral discharges'
                lId = inifile('geti',FI.latLoc,'LateralDischarge','id');
                FI = check_latXY(FI);
                %
                Ans.X = FI.latXY(idx{M_},1);
                Ans.Y = FI.latXY(idx{M_},2);
                Ans.Val = lId(idx{M_});
            case 'grid points'
                FI = check_gpXY(FI);
                Ans.X = FI.gpXY(idx{M_},1);
                Ans.Y = FI.gpXY(idx{M_},2);
                Ans.Val = FI.gpId(idx{M_});
            case 'boundary points'
                F=inifile('geti',FI.bndLoc,'Boundary','type');
                BT = [F{:}];
                BT = find(BT==Props.varid);
                %
                F=inifile('geti',FI.bndLoc,'Boundary','nodeId');
                BI = F(BT(idx{M_}));
                %
                NI = inifile('geti',FI.ntw,'Node','id');
                ni = find(ismember(NI,BI));
                ni = ni(idx{M_});
                x = inifile('geti',FI.ntw,'Node','x');
                y = inifile('geti',FI.ntw,'Node','y');
                Ans.X   = [x{ni}]';
                Ans.Y   = [y{ni}]';
                Ans.Val = NI(ni);
            case 'structure points'
                sId = inifile('geti',FI.strucLoc,'Structure','id');
                ST = inifile('geti',FI.strucLoc,'Structure','type');
                ST = find(strcmp(ST,Props.varid));
                iM = ST(idx{M_});
                %
                FI = check_strucXY(FI);
                %
                Ans.X = FI.strucXY(iM,1);
                Ans.Y = FI.strucXY(iM,2);
                Ans.Val = sId(iM);
            otherwise
                switch Props.varid{1}
                    case 'calcpnt'
                        FI = check_gpXY(FI);
                        % first N1 points are internal nodes
                        X = inifile('geti',FI.ntw,'Node','x');
                        Y = inifile('geti',FI.ntw,'Node','y');
                        N = inifile('geti',FI.ntw,'Node','id');
                        nodXY = [cat(1,X{:}) cat(1,Y{:})];
                        % next N2 points are the internal nodes of the branches
                        igpXY = FI.gpXY(FI.gpInternal,:);
                        % final N3 points are the boundary nodes
                        B = inifile('geti',FI.bndLoc,'Boundary','nodeId');
                        NisB = ismember(N,B);
                        bndXY = nodXY(NisB,:);
                        nodXY = nodXY(~NisB,:);
                        %
                        Ans.X = cat(1,nodXY(:,1),igpXY(:,1),bndXY(:,1));
                        Ans.Y = cat(1,nodXY(:,2),igpXY(:,2),bndXY(:,2));
                        [time,data] = delwaq('read',FI.(Props.varid{1}),Props.varid{2},idx{M_},idx{T_});
                        Ans.Time = time;
                        Ans.Val = permute(data,[3 2 1]);
                    case 'qlat'
                        FI = check_latXY(FI);
                        Ans.X = FI.latXY(:,1);
                        Ans.Y = FI.latXY(:,2);
                        %
                        [time,data] = delwaq('read',FI.(Props.varid{1}),Props.varid{2},idx{M_},idx{T_});
                        Ans.Time = time;
                        Ans.Val = permute(data,[3 2 1]);
                    case 'qwb'
                        [time,data] = delwaq('read',FI.(Props.varid{1}),Props.varid{2},idx_subf,idx{T_});
                        Ans.Time = time;
                        Ans.Val = permute(data,[3 2 1]);
                    case {'reachseg','rsegsub'}
                        FI = check_reachXY(FI);
                        Ans.X = FI.reachXY(:,1);
                        Ans.Y = FI.reachXY(:,2);
                        %
                        [time,data] = delwaq('read',FI.(Props.varid{1}),Props.varid{2},idx{M_},idx{T_});
                        Ans.Time = time;
                        Ans.Val = permute(data,[3 2 1]);
                    case 'struc'
                        FI = check_strucXY(FI);
                        Ans.X = FI.strucXY(:,1);
                        Ans.Y = FI.strucXY(:,2);
                        %
                        [time,data] = delwaq('read',FI.(Props.varid{1}),Props.varid{2},idx{M_},idx{T_});
                        Ans.Time = time;
                        Ans.Val = permute(data,[3 2 1]);
                    otherwise
                        % only for debug purposes ...
                end
        end
    case 'D-Flow2D3D'
        switch Props.Name
            case 'grid'
                nM = length(idx{M_});
                nN = length(idx{N_});
                Ans.X = NaN(nM,nN);
                Ans.Y = NaN(nM,nN);
                if idx{M_}(end)==sz(M_)
                    idx{M_}(end) = [];
                    nM = nM-1;
                end
                if idx{N_}(end)==sz(N_)
                    idx{N_}(end) = [];
                    nN = nN-1;
                end
                Ans.X(1:nM,1:nN) = FI.grd.X(idx{M_},idx{N_});
                Ans.Y(1:nM,1:nN) = FI.grd.Y(idx{M_},idx{N_});
            otherwise
                Ans = [];
        end
    case 'D-Flow FM'
        switch Props.Name
            case 'mesh'
                Ans = netcdffil(FI.mesh.nc_file,idom,FI.mesh.quant,'grid',idx{M_});
            otherwise
                Ans = [];
        end
    case 'D-Wave'
        switch Props.Name
            case 'grid'
                Ans.X = FI.domain(idom).grd.X(idx{M_},idx{N_});
                Ans.Y = FI.domain(idom).grd.Y(idx{M_},idx{N_});
            otherwise
                Ans = [];
        end
end

varargout={Ans FI};
% -----------------------------------------------------------------------------


function XY = geom2xy(G)
p = strfind(G,'(');
GeomType = G(1:p-1);
if strcmp(GeomType,'LINESTRING')
    xy = sscanf(G(p+1:end),'%f');
    switch length(xy)
        case 2
            XY = sscanf(G(p+1:end),'%f %f,',[2 inf]);
            XY = XY';
        case 3
            XY = sscanf(G(p+1:end),'%f %f %f,',[3 inf]);
            XY = XY(1:2,:)';
    end
else
    error('Geometry type "%s" not yet supported.',GeomType)
end

% -----------------------------------------------------------------------------
function Out=domains(FI)
switch FI.FileType
    case 'Delft3D D-Wave'
        Out = {FI.domain.name};
    otherwise
        Out = {};
end
% -----------------------------------------------------------------------------


% -----------------------------------------------------------------------------
function Out=infile(FI,idom)
T_=1; ST_=2; M_=3; N_=4; K_=5;
%======================== SPECIFIC CODE =======================================
PropNames={'Name'                   'Units' 'Geom' 'Coords' 'DimFlag' 'DataInCell' 'NVal' 'SubFld' 'MNK' 'varid'  'DimName' 'hasCoords' 'VectorDef' 'ClosedPoly' 'UseGrid'};
DataProps={'-------'                ''      ''     ''      [0 0 0 0 0]  0           0      []       0     []          {}          0         0          0          0};
Out=cell2struct(DataProps,PropNames,2);
switch FI.FileType
    case 'Delft3D D-Flow1D'
        F=inifile('geti',FI.bndLoc,'Boundary','type');
        BT=[F{:}];
        uBT=unique(BT);
        nBT=length(uBT);
        %
        ST=inifile('geti',FI.strucLoc,'Structure','type');
        uST=unique(ST);
        nST=length(uST);
        %
        % CrossSection types have been copied from their definition records
        % to the location record in MDF.
        CT=inifile('geti',FI.crsLoc,'CrossSection','type');
        uCT=unique(CT);
        nCT=length(uCT);
        hasCxyz = any(strcmp('xyz',uCT));
        %
        try
            LAT=inifile('geti',FI.latLoc,'LateralDischarge','id');
            hasLAT=1;
        catch
            hasLAT=0;
        end
        %
        nFLD = 0;
        flds = {'calcpnt','qlat','qwb','reachseg','rsegsub','struc'};
        for i = 1:length(flds)
            if isfield(FI,flds{i})
                nFLD = nFLD+1+length(FI.(flds{i}).SubsName);
            end
        end
        %
        Out(2:5+nCT+hasCxyz+1+nBT+hasLAT+1+nST+1+nFLD) = Out(1);
        Out(2).Name = 'network';
        Out(2).Geom = 'POLYL';
        Out(2).Coords = 'xy';
        Out(2).DimFlag(M_) = 1;
        %
        Out(3).Name = 'nodes';
        Out(3).Geom = 'PNT';
        Out(3).Coords = 'xy';
        Out(3).NVal = 4;
        Out(3).DimFlag(M_) = 1;
        %
        Out(4).Name = 'grid points';
        Out(4).Geom = 'PNT';
        Out(4).Coords = 'xy';
        Out(4).NVal = 4;
        Out(4).DimFlag(M_) = 1;
        nFLD = 4;
        %
        nFLD = nFLD+1; % skip one for separator
        for i = 1:nCT
            Out(nFLD+i).Name = [uCT{i} ' cross section points'];
            Out(nFLD+i).Geom = 'PNT';
            Out(nFLD+i).Coords = 'xy';
            Out(nFLD+i).NVal = 4;
            Out(nFLD+i).DimFlag(M_) = 1;
            Out(nFLD+i).varid = uCT{i};
        end
        nFLD = nFLD+nCT;
        if hasCxyz
            nFLD = nFLD+1;
            Out(nFLD).Name = 'xyz cross section lines';
            Out(nFLD).Geom = 'POLYL';
            Out(nFLD).Coords = 'xy';
            Out(nFLD).DimFlag(M_) = 1;
            Out(nFLD).varid = uCT{i};
        end
        %
        nFLD = nFLD+1; % skip one for separator
        for i = 1:nBT
            switch uBT(i)
                case 1
                    Name = 'water level boundary points';
                case 2
                    Name = 'discharge boundary points';
                otherwise
                    Name = sprintf('boundary points - type %i',uBT(i));
            end
            Out(nFLD+i).Name = Name;
            Out(nFLD+i).Geom = 'PNT';
            Out(nFLD+i).Coords = 'xy';
            Out(nFLD+i).NVal = 4;
            Out(nFLD+i).DimFlag(M_) = 1;
            Out(nFLD+i).varid = uBT(i);
        end
        nFLD = nFLD+nBT;
        if hasLAT
            Out(nFLD+1).Name = 'lateral discharges';
            Out(nFLD+1).Geom = 'PNT';
            Out(nFLD+i).Coords = 'xy';
            Out(nFLD+1).NVal = 4;
            Out(nFLD+1).DimFlag(M_) = 1;
            nFLD = nFLD+1;
        end
        %
        nFLD = nFLD+1; % skip one for separator
        for i = 1:nST
            switch uST{i}
                case 'universalWeir'
                    Name = 'universal weir';
                otherwise
                    Name = uST{i};
            end
            Out(nFLD+i).Name = ['structure points - ' Name];
            Out(nFLD+i).Geom = 'PNT';
            Out(nFLD+i).Coords = 'xy';
            Out(nFLD+i).NVal = 4;
            Out(nFLD+i).DimFlag(M_) = 1;
            Out(nFLD+i).varid = uST{i};
        end
        nFLD = nFLD+nST;
        %
        for i = 1:length(flds)
            if isfield(FI,flds{i})
                FI_fld = FI.(flds{i});
                nFLD = nFLD+1; % skip one for separator
                for j = 1:length(FI_fld.SubsName)
                    nFLD = nFLD+1;
                    Out(nFLD).Name  = FI_fld.SubsName{j};
                    Out(nFLD).Geom  = 'PNT';
                    Out(nFLD).Coords = 'xy';
                    Out(nFLD).NVal  = 1;
                    if strcmp(flds{i},'qwb')
                        Out(nFLD).SubFld = FI_fld.SegmentName;
                        Out(nFLD).DimFlag(T_) = 1;
                    else
                        Out(nFLD).DimFlag([T_ M_]) = 1;
                    end
                    Out(nFLD).varid = {flds{i} j};
                end
            end
        end
    case 'Delft3D D-Flow2D3D'
        Out(1).Name = 'grid';
        Out(1).Geom = 'sQUAD';
        Out(1).Coords = 'xy';
        Out(1).DimFlag([M_ N_]) = 1;
    case 'Delft3D D-Flow FM'
        Out(1).Name = 'mesh';
        Out(1).Geom = 'UGRID-NODE';
        Out(1).Coords = 'xy';
        Out(1).DimFlag(M_) = 6;
    case 'Delft3D D-Wave'
        Out(1).Name = 'grid';
        Out(1).Geom = 'sQUAD';
        Out(1).Coords = 'xy';
        Out(1).DimFlag([M_ N_]) = 1;
    otherwise
        Out(:,1) = [];
end
% -----------------------------------------------------------------------------

% -----------------------------------------------------------------------------
function subf=getsubfields(FI,Props,f)
if iscell(Props.SubFld)
    subf=Props.SubFld;
    if nargin>2 && f~=0
        subf=subf(f);
    end
else
    subf={};
end
% -----------------------------------------------------------------------------

% -----------------------------------------------------------------------------
function sz=getsize(FI,idom,Props)
T_=1; ST_=2; M_=3; N_=4; K_=5;
%======================== SPECIFIC CODE =======================================
ndims = length(Props.DimFlag);
sz = zeros(1,ndims);
switch FI.FileType
    case 'Delft3D D-Flow1D'
        switch Props.Name
            case 'network'
                F=inifile('chapters',FI.ntw);
                sz(M_) = sum(strcmp(F,'Branch'));
            case 'nodes'
                F=inifile('chapters',FI.ntw);
                sz(M_) = sum(strcmp(F,'Node'));
            case 'grid points'
                F=inifile('geti',FI.ntw,'Branch','gridPointsCount');
                sz(M_) = sum([F{:}]);
            case 'lateral discharges';
                F=inifile('geti',FI.latLoc,'LateralDischarge','id');
                if iscell(F)
                    sz(M_) = length(F);
                else
                    sz(M_) = 1;
                end
            otherwise
                if strcmp(Props.Name,'xyz cross section lines') || ...
                        ~isempty(strfind(Props.Name,'cross section points'))
                    CT=inifile('geti',FI.crsLoc,'CrossSection','type');
                    sz(M_)=sum(strcmp(Props.varid,CT));
                elseif ~isempty(strfind(Props.Name,'boundary points'))
                    F=inifile('geti',FI.bndLoc,'Boundary','type');
                    BT = [F{:}];
                    sz(M_) = sum(BT==Props.varid);
                elseif strncmp(Props.Name,'structure points',16)
                    ST=inifile('geti',FI.strucLoc,'Structure','type');
                    sz(M_)=sum(strcmp(Props.varid,ST));
                elseif ~iscell(Props.varid)
                    % for development purposes only ...
                elseif strcmp(Props.varid{1},'qwb')
                    sz(T_) = FI.(Props.varid{1}).NTimes;
                else
                    sz(T_) = FI.(Props.varid{1}).NTimes;
                    sz(M_) = FI.(Props.varid{1}).NumSegm;
                end
        end
    case 'Delft3D D-Flow2D3D'
        MNK = inifile('geti',FI.mdf,'*','MNKmax');
        sz([M_ N_]) = MNK(1:2);
    case 'Delft3D D-Flow FM'
        grdSz = netcdffil(FI.mesh.nc_file,idom,FI.mesh.quant,'size');
        sz(M_) = grdSz(M_);
    case 'Delft3D D-Wave'
        grdSz = size(FI.domain(idom).grd.X);
        sz([M_ N_]) = grdSz;
    otherwise
        % no generic default dimension code
end
% -----------------------------------------------------------------------------

% -----------------------------------------------------------------------------
function xy = branch_idchain2xy(NTWini,bId,bCh)
nPnt = length(bId);
xy = NaN(nPnt,2);
%
[uBId,ia,ic] = unique(bId);
G = inifile('geti',NTWini,'Branch','geometry');
GId = inifile('geti',NTWini,'Branch','id');
for i = 1:length(uBId)
    Branch = uBId(i);
    iBranch = ustrcmpi(Branch,GId);
    if iBranch>0
        XY   = geom2xy(G{iBranch});
        d    = pathdistance(XY(:,1),XY(:,2));
        iOut = ic==i;
        cCS  = [bCh{iOut}];
        xyCS = interp1(d,XY,cCS);
        xy(iOut,:) = xyCS;
    end
end
% -----------------------------------------------------------------------------

% -----------------------------------------------------------------------------
function FI = check_gpXY(FI)
if ~isfield(FI,'gpXY')
    gpCnt = inifile('geti',FI.ntw,'Branch','gridPointsCount');
    gpX = inifile('geti',FI.ntw,'Branch','gridPointX');
    gpY = inifile('geti',FI.ntw,'Branch','gridPointY');
    gpI = inifile('geti',FI.ntw,'Branch','gridPointIds');
    gpCnt = [gpCnt{:}];
    nGP   = sum(gpCnt);
    FI.gpXY       = zeros(nGP,2);
    FI.gpInternal = true(nGP,1);
    FI.gpId       = cell(nGP,1);
    oM = 0;
    for i = 1:length(gpCnt)
        nPnt = gpCnt(i);
        iM   = oM + (1:nPnt);
        oM   = oM + nPnt;
        %
        FI.gpInternal(iM(1))   = false;
        FI.gpInternal(iM(end)) = false;
        FI.gpXY(iM,:) = [gpX{i}(:) gpY{i}(:)];
        FI.gpId(iM)   = multiline(gpI{i},';','cell');
    end
end
% -----------------------------------------------------------------------------

% -----------------------------------------------------------------------------
function FI = check_reachXY(FI)
if ~isfield(FI,'reachXY')
    reachCnt = inifile('geti',FI.ntw,'Branch','gridPointsCount');
    brId = inifile('geti',FI.ntw,'Branch','id');
    gpO = inifile('geti',FI.ntw,'Branch','gridPointOffsets');
    reachCnt = [reachCnt{:}]-1;
    nReach   = sum(reachCnt);
    FI.reachXY = zeros(nReach,2);
    oM = 0;
    for i = 1:length(reachCnt)
        nSeg = reachCnt(i);
        iM   = oM + (1:nSeg);
        oM   = oM + nSeg;
        %
        segO = (gpO{i}(1:end-1)+gpO{i}(2:end))/2;
        FI.reachXY(iM,:) = branch_idchain2xy(FI.ntw,repmat(brId(i),1,nSeg),num2cell(segO));
    end
end
% -----------------------------------------------------------------------------

% -----------------------------------------------------------------------------
function FI = check_latXY(FI)
if ~isfield(FI,'latXY')
    bId = inifile('geti',FI.latLoc,'LateralDischarge','branchid');
    bCh = inifile('geti',FI.latLoc,'LateralDischarge','chainage');
    FI.latXY = branch_idchain2xy(FI.ntw,bId,bCh);
end
% -----------------------------------------------------------------------------

% -----------------------------------------------------------------------------
function FI = check_crsXY(FI)
if ~isfield(FI,'crsXY')
    bId = inifile('geti',FI.crsLoc,'CrossSection','branchid');
    bCh = inifile('geti',FI.crsLoc,'CrossSection','chainage');
    FI.crsXY = branch_idchain2xy(FI.ntw,bId,bCh);
end
% -----------------------------------------------------------------------------

% -----------------------------------------------------------------------------
function FI = check_strucXY(FI)
if ~isfield(FI,'strucXY')
    bId = inifile('geti',FI.strucLoc,'Structure','branchid');
    bCh = inifile('geti',FI.strucLoc,'Structure','chainage');
    FI.strucXY = branch_idchain2xy(FI.ntw,bId,bCh);
end
% -----------------------------------------------------------------------------

% -----------------------------------------------------------------------------
function [NewFI,cmdargs]=options(FI,mfig,cmd,varargin)
NewFI=FI;
cmd=lower(cmd);
cmdargs={};
switch cmd
    case 'initialize'
        OK=optfig(mfig);
    case 'loaddata'
        [p,f,e]=fileparts(FI.md1d.FileName);
        % assume that md1d file is located in ...\FileWriters and that the
        % associated model output files are located in ...\work, so
        % relative to the md1d file in: ..\work.
        p = absfullfile(p,'..','work');
        d = dir(fullfile(p,'*.his'));
        for i = 1:length(d)
            [fp,f,e] = fileparts(d(i).name);
            NewFI.(f) = delwaq('open',fullfile(p,d(i).name));
        end
    otherwise

end
% -----------------------------------------------------------------------------

% -----------------------------------------------------------------------------
function OK=optfig(h0)
Inactive=get(0,'defaultuicontrolbackground');
FigPos=get(h0,'position');
FigPos(3:4) = getappdata(h0,'DefaultFileOptionsSize');
set(h0,'position',FigPos)

voffset=FigPos(4)-30;
width=FigPos(3)-20;
h2 = uicontrol('Parent',h0, ...
    'Style','pushbutton', ...
    'BackgroundColor',Inactive, ...
    'Callback','d3d_qp fileoptions loaddata', ...
    'Horizontalalignment','left', ...
    'Position',[11 voffset width 18], ...
    'String','Load Data', ...
    'Tag','loaddata');
OK=1;
