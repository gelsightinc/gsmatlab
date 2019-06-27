function [dtv,dtol] = grranova(scores, nuser, ntrial, varargin)
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

    % The number of DF for appraisers*parts
    ndf_apart = (nuser-1)*(npart-1);
    if nuser <= 1 || npart <= 1
        ndf_apart = 0;
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
    totalvr = sum(ssqx) - sum(sumx).^2 / (npart*ntotaltrials);
    appss   = sum(sumx.^2)/(npart*ntrial) - sum(sumx).^2 / (npart*ntotaltrials);
    partss  = sum(sum(scores,2).^2)/(nuser*ntrial)- sum(sumx).^2 / (npart*ntotaltrials);
    apartss = sum(partsq)/ntrial - sum(sum(scores,2).^2)/(nuser*ntrial) - sum(sumx.^2)/(npart*ntrial) + sum(sumx).^2 / (npart*ntotaltrials); 
    if ndf_apart == 0
        apartss = 0;
    end
    gagess  = totalvr - (appss + partss + apartss);

    appms   = appss / (nuser-1);
    partms  = partss / (npart-1);
    apartms = apartss / ((nuser-1)*(npart-1));
    if ndf_apart == 0
        apartms = 0;
    end
    gagems = gagess / (nuser*npart*(ntrial-1));
    totalms = (gagess + apartss)/(ndf_apart + nuser*npart*(ntrial-1)); 
    if ndf_apart == 0
        totalms = apartms;
    end

    % This version doesn't use f-distribution test

    repeatsg = sqrt( gagems );
    reprodsg = sqrt((appms - apartms)/( npart * ntrial ));
    apartsg  = sqrt((apartms - gagems)/ntrial);
    gagesg   = sqrt(repeatsg^2 + reprodsg^2 + apartsg^2);
    partsg   = sqrt( (partms - apartms)/(nuser * ntrial) );

    totalsg = sqrt( repeatsg^2 + reprodsg^2 + apartsg^2 + partsg^2 );


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
		fprintf('Number of distinct components :  %5.2f\n',ndc);
		fprintf('Gage R&R, percent tol         :  %5.2f%%\n',GRR*sg*100/tol);
	end

    grr = GRR/TV*100;
    pt = GRR*sg*100/tol;

    % Results - percent total variation
    dtv.Repeatability    = EV/TV*100;
    dtv.Reproducibility  = AV/TV*100;
    dtv.AppraiserPart    = XV/TV*100;
    dtv.GRR              = GRR/TV*100;

    % Results - percent tolerance
    dtol.Repeatability   = sg*EV/tol*100;
    dtol.Reproducibility = sg*AV/tol*100;
    dtol.AppraiserPart   = sg*XV/tol*100;
    dtol.GRR             = sg*GRR/tol*100;
    dtol.Parts           = sg*PV/tol*100;
    dtol.Parts           = sg*PV/tol*100;

end

%
% scores is a matrix that is nparts x (nusers * nrepeats)
%
function [grr,pt] = grranova_old(scores, nuser, ntrial, varargin)

	settings.sigma     = 6;
	settings.tolerance = 1;

	insettings = parseSettings(varargin);
	settings   = mergeSettings(settings, insettings);

	[npart,ntotaltrials] = size(scores);

	if nuser*ntrial ~= ntotaltrials
		error('Incorrect number of users and trials')
	end


	avgx = zeros(nuser,1);
	rngx = zeros(nuser,1);
	for ux = 1 : nuser
		cst = (ux-1)*ntrial + 1;
		ced = ux * ntrial;

		userscores = scores(:,cst:ced);

		avg = mean(userscores,2);
		rng = max(userscores,[],2) - min(userscores,[],2);

		avgx(ux) = mean(avg);
		rngx(ux) = mean(rng);
	end

	rbar = sum(rngx)/nuser;
	xdif = max(avgx) - min(avgx);


	% Page 120
	% K1 depends upon the number of trials used in the gage study and is equal to the inverse of 
	% d2star which is obtained from Appendix C. d2star is dependent on the number of trials
	% (m) and the number of parts times the number of appraisers (g) (assumed to
	% be greater than 15 for calculating the value of K1)

	k1 = 1/d2table(npart*nuser,ntrial);

	% Equipment variation
	EV = rbar * k1;


	% Page 120
	% K2 depends upon the number of appraisers used in the gage study and is the inverse of d2star
	% which is obtained from Appendix C. d2star is dependent on the number of appraisers (m) 
	% and g = 1, since there is only one range calculation.

	k2 = 1/d2table(1,nuser);

	% Appraiser variation
	AV2 = max((xdif * k2)^2 - (EV^2 / (npart * ntrial)), 0);
	AV = sqrt( AV2 ); 


	GRR = sqrt(EV^2 + AV^2);

	% Page 120
	% K3 depends upon the number of parts used in the gage study and is the inverse of d2star
	% which is obtained from Appendix C. d2star is dependent on the number of parts (m) and (g). 
	% In this situation g = 1 since there is only one range calculation.
	k3 = 1/d2table(1,npart);


	% Part variation
	% Rp is range of part averages
	partavg = mean(scores,2);
	Rp = max(partavg) - min(partavg);
	PV = Rp * k3;

	% Total variation
	TV = sqrt(GRR^2 + PV^2);
	
	% ndc
	ndc = sqrt(2)*PV/GRR;

	% GRR as percent of tolerance
	sg  = settings.sigma;
	tol = settings.tolerance;
	
	grr = GRR/TV*100;
    pt  = GRR*sg*100/tol;
	
    fprintf('Tolerance                     :  %6.3f\n',tol);
    fprintf('Min score                     :  %6.3f\n',min(scores(:)));
    fprintf('Max score                     :  %6.3f\n',max(scores(:)));
	fprintf('Repeatability (Equip. Var.)   :  %5.2f%%\n',EV/TV*100);
	fprintf('Reproducibility (User Var.)   :  %5.2f%%\n',AV/TV*100);
	fprintf('User x Part                   :  %5.2f%%\n',AV/TV*100);
	fprintf('Gage R&R                      :  %5.2f%%\n',GRR/TV*100);
	fprintf('Part variation                :  %5.2f%%\n',PV/TV*100);
	fprintf('Number of distinct components :  %5.2f\n',ndc);
	fprintf('Gage R&R, percent tol         :  %5.2f%%\n',GRR*sg*100/tol);
    keyboard

end



%d2table
%
%	
%
% -Usage-
%	v = d2table(k, n)
%
% -Inputs-
%	k     Number of subgroups, number of samples
%	n     Subgroup size, size of samples
%
% -Outputs-
%	v
%
% Last Modified: 09/02/2014
function v = d2table(k, n)



	[d2p,d2] = d2vals();

	[nk,nn] = size(d2p);

	if n > nn || n < 2
		error('n outside range');
	end

	if k <= nk && n <= nn
		v = d2p(k,n);
	elseif k > nk && n <= nn
		v = d2(n);
	end


end

%
% http://www.micquality.com/reference_tables/d2_tables.htm
%
function [d2prime,d2] = d2vals()

	d2prime = zeros(15,15);

	d2prime(1 ,2:15) = [1.414 1.912 2.239 2.481 2.673 2.830 2.963 3.078 3.179 3.269 3.350 3.424 3.491 3.553];
	d2prime(2 ,2:15) = [1.279 1.805 2.151 2.405 2.604 2.768 2.906 3.025 3.129 3.221 3.305 3.380 3.449 3.513];
	d2prime(3 ,2:15) = [1.231 1.769 2.120 2.379 2.581 2.747 2.886 3.006 3.112 3.205 3.289 3.366 3.435 3.499];
	d2prime(4 ,2:15) = [1.206 1.750 2.105 2.366 2.570 2.736 2.877 2.997 3.103 3.197 3.282 3.358 3.428 3.492];
	d2prime(5 ,2:15) = [1.191 1.739 2.096 2.358 2.563 2.730 2.871 2.992 3.098 3.192 3.277 3.354 3.424 3.488];
	d2prime(6 ,2:15) = [1.181 1.731 2.090 2.353 2.558 2.726 2.867 2.988 3.095 3.189 3.274 3.351 3.421 3.486];
	d2prime(7 ,2:15) = [1.173 1.726 2.085 2.349 2.555 2.723 2.864 2.986 3.092 3.187 3.272 3.349 3.419 3.484];
	d2prime(8 ,2:15) = [1.168 1.721 2.082 2.346 2.552 2.720 2.862 2.984 3.090 3.185 3.270 3.347 3.417 3.482];
	d2prime(9 ,2:15) = [1.164 1.718 2.080 2.344 2.550 2.719 2.860 2.982 3.089 3.184 3.269 3.346 3.416 3.481];
	d2prime(10,2:15) = [1.160 1.716 2.077 2.342 2.549 2.717 2.859 2.981 3.088 3.183 3.268 3.345 3.415 3.480];
	d2prime(11,2:15) = [1.157 1.714 2.076 2.340 2.547 2.716 2.858 2.980 3.087 3.182 3.267 3.344 3.415 3.479];
	d2prime(12,2:15) = [1.155 1.712 2.074 2.344 2.546 2.715 2.857 2.979 3.086 3.181 3.266 3.343 3.414 3.479];
	d2prime(13,2:15) = [1.153 1.710 2.073 2.338 2.545 2.714 2.856 2.978 3.085 3.180 3.266 3.343 3.413 3.478];
	d2prime(14,2:15) = [1.151 1.709 2.072 2.337 2.545 2.714 2.856 2.978 3.085 3.180 3.265 3.342 3.413 3.478];
	d2prime(15,2:15) = [1.150 1.708 2.071 2.337 2.544 2.713 2.855 2.977 3.084 3.179 3.265 3.342 3.412 3.477];

	d2 = [1 1.128 1.693 2.059 2.326 2.534 2.704 2.847 2.970 3.078 3.173 3.259 3.336 3.407 3.472];


end
