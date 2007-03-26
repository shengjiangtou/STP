function [aEQ, vEQ, pEQ, TEQ, Ts, VARS] = stp7_formulas(t, j, bNice, dir,ptarget,jmax,amax,vmax, a0,v0,p0)
% Generate formulars from given profile dt, j
% returns equations for a, v, p as well as variables T

if (nargin < 3) bNice = true; end
if (nargin < 4) dir = sym('dir','real'); end
if (nargin < 5) ptarget = sym('ptarget','real'); end
if (nargin < 6) jmax = sym('jmax','real'); end
if (nargin < 7) amax = sym('amax','real'); end
if (nargin < 8) vmax = sym('vmax','real'); end
if (nargin < 9) a0 = sym('a0','real'); end
if (nargin < 10) v0 = sym('v0','real'); end
if (nargin < 11) p0 = sym('p0','real'); end
N=length(t);

if (N == 7) % these things work only for "correct" 7-phases profiles
    if (sign(j(3)) ~= sign (j(5)))
        % double deceleration
        bDoubleDec = true;
    else
        % for normal profiles we combine phases 3 and 5, if t(4)=0
        bDoubleDec = false;
        if (t(4) == 0) t(5)=0; end
    end
end

% build system of equations covering continuous evolution of a and v
% a(i), v(i) and p(i) represent symbolic expressions denoting the reached
% acceleration, velocity and position *after* phase i
% Because MatLab can't handle zero indices (e.g. a(0)) we distinguish
% between i==1 and greater.
aEQ=[]; vEQ=[]; TEQ=[]; Ts=[]; VARS=[];
for i=1:N
    if (t(i) == 0) % as t(i) == 0, values do not change
        if (i == 1) 
            a(i) = a0;
            v(i) = v0;
            p(i) = p0;
        else
            if ((t(i-1) == 0) || (bNice == false))
                a(i) = a(i-1);
                v(i) = v(i-1);
            else % for a nicer display of formulars we reuse previously introduced vars
                a(i) = sym(sprintf('a%d',i-1));
                v(i) = sym(sprintf('v%d',i-1));
            end
            p(i) = p(i-1); 
        end
        % add equation: ti = 0
        TEQ = [TEQ sym(sprintf('t%d=0', i))];
        % add variable ti
        Ts = [Ts sym(sprintf('t%d', i))];
    else
        T = sym(sprintf('t%d', i), 'real');
        J = j(i);

        % new time variable t_i
        Ts = [Ts T];
        
        if (i == 1)
            A0 = a0; V0 = v0; P0 = p0;
        else
            A0 = a(i-1); V0 = v(i-1); P0 = p(i-1);
        end
        a(i) = A0 + J * T;
        v(i) = V0 + T * (A0 + 1/2 * J * T);
        p(i) = P0 + T * (V0 + T * (1/2 * A0 + 1/6 * J * T));
        % add equations
        if ((i ~= 7) && (bNice == true))
            aEQ = [aEQ sym(sprintf('a%d = %s', i, char(a(i))))];
            vEQ = [vEQ sym(sprintf('v%d = %s', i, char(v(i))))];
            VARS = [VARS sym(sprintf('a%d',i)) sym(sprintf('v%d',i))];
        end
    end
end

%%% add additional equations %%%
pEQ=addEQ ([], ptarget, p(N)); % reach target
% we end at zero speed and acceleration
aEQ = addEQ (aEQ, 0, a(7));
vEQ = addEQ (vEQ, 0, v(7));

% the following things work only for "correct" 7-phases profiles
if (N==7)
    if (bNice) 
        a1 = 'a1'; a5 = 'a5', a3 = 'a3';
    else
        a1 = a(1); a5 = a(5); a3 = a(3);
    end

    % if we have a cruise phase, a3 must be zero
    if (t(4) ~= 0) aEQ = addEQ (aEQ, a3, 0); end

    if (bDoubleDec) % double deceleration
        % add max limits for trapezoidal profiles
        if (t(2) ~= 0) aEQ = addEQ (aEQ, a1, -dir*amax); end
        if (t(6) ~= 0) aEQ = addEQ (aEQ, a5, -dir*amax); end    
        % first two phase are completely known:
        if (t(1) ~= 0) TEQ = addEQ (TEQ, 't1', t(1)); end
        if (t(2) ~= 0) TEQ = addEQ (TEQ, 't2', t(2)); end
    else % normal profile
        % add max limits for trapezoidal profiles (and remove corr. variable)
        if (t(2) ~= 0) aEQ = addEQ (aEQ, a1,  dir*amax); end
        if (t(6) ~= 0) aEQ = addEQ (aEQ, a5, -dir*amax); end
    end
end
return

function EQ = addEQ (EQ, lhs, rhs)
% Function to add a further equations to the set of equations EQ
% Both lhs and rhs can be symbols or strings
EQ = [EQ sym(strcat(char(sym(lhs)), '=', char(sym(rhs))))];
return