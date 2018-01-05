function varargout=xxxfil(FI,domain,field,cmd,varargin)
%   Domains                 = XXXFIL(FI,[],'domains')
%   DataProps               = XXXFIL(FI,Domain)
%   Size                    = XXXFIL(FI,Domain,DataFld,'size')
%   Times                   = XXXFIL(FI,Domain,DataFld,'times',T)
%   StNames                 = XXXFIL(FI,Domain,DataFld,'stations')
%   SubFields               = XXXFIL(FI,Domain,DataFld,'subfields')
%   [Data      ,NewFI]      = XXXFIL(FI,Domain,DataFld,'data',subf,t,station,m,n,k)
%   [Data      ,NewFI]      = XXXFIL(FI,Domain,DataFld,'celldata',subf,t,station,m,n,k)
%   [Data      ,NewFI]      = XXXFIL(FI,Domain,DataFld,'griddata',subf,t,station,m,n,k)
%   [Data      ,NewFI]      = XXXFIL(FI,Domain,DataFld,'gridcelldata',subf,t,station,m,n,k)
%                             XXXFIL(FI,[],'options',OptionsFigure,'initialize')
%   [NewFI     ,cmdargs]    = XXXFIL(FI,[],'options',OptionsFigure,OptionsCommand, ...)
%   [hNew      ,NewFI]      = XXXFIL(FI,Domain,DataFld,'plot',Parent,Ops,hOld,subf,t,station,m,n,k)

function varargout=xxxfil(cmd,FI,varargin)
%   [......]                = XXXFIL('register'    )
%   NewFI                   = XXXFIL('open'        ,FileName)
%   Domains                 = XXXFIL('domains'     ,FI)        %--> FI.Dimensions: all dimensions in the file (Name & Size & Type: geo/time)
%   DataProps               = XXXFIL('fields'      ,FI,Domain) %--> DataProps
%   Grids                   = XXXFIL('grid'        ,FI)
%   Times                   = XXXFIL('times'       ,FI,Domain,DataFld,T)
%   [Data      ,NewFI]      = XXXFIL('data'        ,FI,Domain,DataFld,subf,t,station,m,n,k)
%   [Data      ,NewFI]      = XXXFIL('celldata'    ,FI,Domain,DataFld,subf,t,station,m,n,k)
%   [Data      ,NewFI]      = XXXFIL('griddata'    ,FI,Domain,DataFld,subf,t,station,m,n,k)
%   [Data      ,NewFI]      = XXXFIL('gridcelldata',FI,Domain,DataFld,subf,t,station,m,n,k)
%                             XXXFIL('options'     ,FI,OptionsFigure,'initialize')
%   [NewFI     ,cmdargs]    = XXXFIL('options'     ,FI,OptionsFigure,OptionsCommand, ...)
%   [hNew      ,NewFI]      = XXXFIL('plot'        ,FI,Domain,DataFld,Parent,Ops,hOld,subf,t,station,m,n,k)
