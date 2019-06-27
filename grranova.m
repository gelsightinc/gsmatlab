function [dtv,dtol,ndc] = grranova(scores, nuser, ntrial, varargin)
%GRRANOVA Do a Gage R&R Analysis of Variance on a set of measurements.
%   [DTV,DTOL] = grranova(M, NUSER, NTRIAL) performs a gage repeatability and
%   reproducibility study on the measurements in the data matrix M. The size 
%   of the matrix M is NPARTS x (NUSERS * NTRIAL).
%
%   The DTV struct contains the GRR data as a percent of total variation (TV). 
%   The DTOL struct contains the GRR data as a percent of tolerance (TOL). The
%   structs each have the following fields:
%
%   Repeatability    The repeatbility score as a percent TV or TOL
%   Reproducibility  The reproducibilty score as a percent of TV or TOL
%   AppraiserPart    The appraiser x part variation as a percent TV or TOL
%   GRR              The Gage R&R as a percent TV or TOL
%   Parts            The part variation as a percent TV or TOL 
%
%   [DTV,DTOL,NDC] = grranova(M, NUSER, NTRIAL) returns the number of 
%   distinct categories.
%
%   study with tolerance TOL. The default tolerance is 1.
%   [DTV,DTOL] = grranova(M, NUSER, NTRIAL, 'Tolerance', TOL) performs a GRR
%   study with tolerance TOL. The default tolerance is 1.
%
%   [DTV,DTOL] = grranova(M, NUSER, NTRIAL, 'Sigmas', S) performs a GRR
%   study with process distribution width of S sigmas. Typical values are 5.15
%   or 6. The default value is 6 sigmas.
%
%   [DTV,DTOL] = grranova(M, NUSER, NTRIAL, 'Verbose', true) prints a GRR
%   report to the console.
%
    p = inputParser;
    p.addOptional('sigmas',    6);
    p.addOptional('tolerance', 1);
    p.addOptional('verbose', false);
    p.parse(varargin{:});
    settings = p.Results;

    [npart,ntotaltrials] = size(scores);

    if nuser*ntrial ~= ntotaltrials
        error('Incorrect number of users and trials')
    end

    % Degrees of freedom
    ndf_app = max(0, nuser-1);                                        % Cell F-G, 29
    ndf_part = max(0, npart-1);                                       % Cell F-G, 30
    % The number of DF for appraisers*parts
    ndf_apart = (nuser-1)*(npart-1);                                  % Cell F-G, 31
    if nuser <= 1 || npart <= 1
        ndf_apart = 0;
    end
    ndf_gage = nuser*npart*(ntrial-1);                                % Cell F-G, 32
    if ntrial <= 1
        ndf_gage = 0;
    end

    %
    ssqx = zeros(nuser,1);
    sumx = zeros(nuser,1);
    partsq = zeros(nuser,1);
    for ux = 1 : nuser
        cst = (ux-1)*ntrial + 1;
        ced = ux * ntrial;

        userscores = scores(:,cst:ced);
        ptsq       = sum(userscores,2).^2;

        ssqx(ux)   = sum(userscores(:).^2);
        sumx(ux)   = sum(userscores(:));
        partsq(ux) = sum(ptsq);
    end
    
    appss   = sum(sumx.^2)/(npart*ntrial) ...                         % Cell H-I, 29
              - sum(sumx).^2 / (npart*ntotaltrials);
    partss  = sum(sum(scores,2).^2)/(nuser*ntrial) ...                % Cell H-I, 30
              - sum(sumx).^2 / (npart*ntotaltrials);
    apartss = sum(partsq)/ntrial ...                                  % Cell H-I, 31
              - sum(sum(scores,2).^2)/(nuser*ntrial) ...   
              - sum(sumx.^2)/(npart*ntrial) ...
              + sum(sumx).^2 / (npart*ntotaltrials); 
    totalvr = sum(ssqx) - sum(sumx).^2 / (npart*ntotaltrials);        % Cell H-I, 33

    if ndf_apart == 0
        apartss = 0;
    end
    gagess  = totalvr - (appss + partss + apartss);                   % Cell H-I, 32

    appms   = appss / (nuser-1);                                      % Cell J-K, 29
    partms  = partss / (npart-1);                                     % Cell J-K, 30
    apartms = apartss / ((nuser-1)*(npart-1));                        % Cell J-K, 31
    if ndf_apart == 0
        apartms = 0;
    end
    gagems = gagess / (nuser*npart*(ntrial-1));                       % Cell J-K, 32
    totalms = (gagess + apartss)/(ndf_apart + nuser*npart*(ntrial-1));% Cell J-K, 33
    if ndf_apart == 0
        totalms = apartms;
    end

    % F-distribution test
    apartf   = 0;
    apartpbf = 0;
    if apartss > 0
        apartf   = apartms / gagems;                                   % Cell L-M, 31
        apartpbf = 1-fdistribution(apartf, ndf_apart, ndf_gage); 
    end

    repeatvr = totalms;                                               % Cell P, 37
    reprodvr = max(0.0, (appms-totalms)/(npart*ntrial));              % Cell P, 38
    apartvr  = 0.0;                                                   % Cell P, 39
    partvr   = (partms-totalms)/(nuser*ntrial);                       % Cell P, 41
    if apartpbf <= 0.05
        repeatvr = gagems;                                            % Cell P, 37
        reprodvr = max(0.0, (appms-apartms)/(npart*ntrial));          % Cell P, 38
        apartvr  = (apartms - gagems)/ntrial;                         % Cell P, 39
        partvr = (partms-apartms)/(nuser*ntrial);                     % Cell P, 41
    end

    if apartms <= 0 || (partms-totalms) < 0 || (partms - apartms) < 0
        partvr = 0;
    end


    repeatsg = sqrt(repeatvr);                                        % Cell F-G, 37
    reprodsg = sqrt(reprodvr);                                        % Cell F-G, 38
    apartsg  = sqrt(apartvr);                                         % Cell F-G, 39
    gagesg   = sqrt(repeatvr + reprodvr + apartvr);                   % Cell F-G, 40
    partsg   = sqrt(partvr);                                          % Cell F-G, 41

    totalsg = sqrt( repeatvr + reprodvr + apartvr + partvr );         % Cell F-G, 42

    EV = repeatsg;
    AV = reprodsg;
    XV = apartsg;
    TV = totalsg;
    PV = partsg;
    GRR = gagesg;

    tol = settings.tolerance;
    ndc = max(floor( PV/GRR * sqrt(2) ),1);
    sg = settings.sigmas;
    
    if nargout == 0 || settings.verbose
        fprintf('Tolerance                     :  %6.3f\n',tol);
        fprintf('Min score                     :  %6.3f\n',min(scores(:)));
        fprintf('Max score                     :  %6.3f\n',max(scores(:)));
        fprintf('Repeatability (Equip. Var.)   :  %5.2f%%\n',EV/TV*100);
        fprintf('Reproducibility (User Var.)   :  %5.2f%%\n',AV/TV*100);
        fprintf('User x Part                   :  %5.2f%%\n',XV/TV*100);
        fprintf('Gage R&R                      :  %5.2f%%\n',GRR/TV*100);
        fprintf('Part variation                :  %5.2f%%\n',PV/TV*100);
        fprintf('Number of distinct categories :  %5.2f\n',ndc);
        fprintf('Gage R&R, percent tol         :  %5.2f%%\n',GRR*sg*100/tol);
    end

    grr = GRR/TV*100;
    pt = GRR*sg*100/tol;

    % Results - percent total variation
    dtv.Repeatability    = EV/TV*100;
    dtv.Reproducibility  = AV/TV*100;
    dtv.AppraiserPart    = XV/TV*100;
    dtv.GRR              = GRR/TV*100;
    dtv.Parts            = PV/TV*100;

    % Results - percent tolerance
    dtol.Repeatability   = sg*EV/tol*100;
    dtol.Reproducibility = sg*AV/tol*100;
    dtol.AppraiserPart   = sg*XV/tol*100;
    dtol.GRR             = sg*GRR/tol*100;
    dtol.Parts           = sg*PV/tol*100;

end


%
% F distribution
%
function val = fdistribution(f, v1, v2)
    av = v1 / 2.0;
    bv = v2 / 2.0;
    gv = av*f;

    val = 0.0;

    if f > 0.0
        val = betadistribution( gv / (bv + gv), av, bv);
    end

end


function bv = betadistribution(x, a, b) 

    bv = 0.0;

    % Both shape parameters are strictly greater than 1. 
    if a > 1.0 && b > 1.0
        if x <= (a - 1.0) / ( a + b - 2.0 )
            bv = betafraction(x, a, b);
        else
            bv = 1.0 - betafraction( 1.0 - x, b, a );
        end 
        return;
    end
  
    % Both shape parameters are strictly less than 1. 
    if a < 1.0 && b < 1.0
        bv = (a * betadistribution(xx, aa + 1.0, bb) + ...
                  b * betadistribution(xx, aa, bb + 1.0) ) / (a + b); 
        return;
    end
   
    % One of the shape parameters exactly equals 1. 
    if a == 1.0
        bv = 1.0 - ((1.0 - x)^b) / ( b * betafunction(a,b) );
        return;
    end

    if b == 1.0 
        bv = x^a  / ( a * betafunction(a,b) );
        return;
    end

    % Exactly one of the shape parameters is strictly less than 1.
    if a < 1.0 
        bv = betadistribution(xx, aa + 1.0, bb) + ...
             (x^a * (1.0 - x)^b) / ( a * betafunction(a,b) );
 
    % The remaining condition is b < 1.0 */
    else
        bv = betadistribution(xx, aa, bb + 1.0) - ...
             (x^a * (1.0 - x)^b) / ( b * betafunction(a,b) );
    end
end

%
%
%
function lnb = betafunction(a, b)

    % use a simpler expression for small values of a and b
    if (a + b) <= 171
        % If (a + b) <= Gamma_Function_Max_Arg() then simply return 
        %  gamma(a)*gamma(b) / gamma(a+b).                         

        %lnb = xGamma_Function(a) / (xGamma_Function(a + b) / xGamma_Function(b));
        lnb = gamma(a) / (gamma(a + b) / gamma(b));

    else
        % If (a + b) > Gamma_Function_Max_Arg() then simply return //
        %  exp(lngamma(a) + lngamma(b) - lngamma(a+b) ).           //

       lnbeta = gammaln(a) + gammaln(b) - gammaln(a + b);
       lnb = exp(lnbeta);
    end
end

%
%
%
function bcf = betafraction(x, a, b)

    Am1 = 1.0;
    A0 = 0.0;
    Bm1 = 0.0;
    B0 = 1.0;
    e = 1.0;
    Ap1 = A0 + e * Am1;
    Bp1 = B0 + e * Bm1;
    f_less = Ap1 / Bp1;
    f_greater = 0.0;
    aj = a;
    am = a;
    epsv = 10.0 * eps;
    j = 0;
    m = 0;
    k = 1;

    bcf = 0.0;
    if x == 0.0 
        return;
    end
   
    while  2.0 * abs(f_greater - f_less) > epsv * abs(f_greater + f_less) 
        Am1 = A0;
        A0 = Ap1;
        Bm1 = B0;
        B0 = Bp1;
        am = a + m;
        e = - am * (am + b) * x / ( (aj + 1.0) * aj );
        Ap1 = A0 + e * Am1;
        Bp1 = B0 + e * Bm1;
        k = mod(k + 1,4); 
        if k == 1
            f_less = Ap1/Bp1;
        elseif k == 3 
            f_greater = Ap1/Bp1;
        end
        if  abs(Bp1) > 1.0 
            Am1 = A0 / Bp1;
            A0 = Ap1 / Bp1;
            Bm1 = B0 / Bp1;
            B0 = 1.0;
        else 
            Am1 = A0;
            A0 = Ap1;
            Bm1 = B0;
            B0 = Bp1;
        end
        m = m + 1;
        j = j + 2;
        aj = a + j;
        e = m * ( b - m ) * x / ( ( aj - 1.0) * aj  );
        Ap1 = A0 + e * Am1;
        Bp1 = B0 + e * Bm1;
        k = mod(k + 1, 4);
        if k == 1
            f_less = Ap1/Bp1;
        elseif k == 3
            f_greater = Ap1/Bp1;
        end
    end
    bcf = exp( a * log(x) + b * log(1.0 - x) + log(Ap1 / Bp1) ) / ( a * betafunction(a,b) );
end

