%% Version 1
% Last edited by Dev on Feb 10 2018

%%% This script aims to perform a time-varying simulation of the rocket
%%% burn to verify that performance matches expectations in the config file
%%% using Chapter 7 of Space Propulsion Analysis and Design (SPAD) and
%%% Rocket Propulsion Elements (RPE)

%This script follows Table 7.9 in SPAD almost exactly.
%It assumes a constant mdot_ox and circular port geometry

%#ok<*SAGROW>
%the line above hides the error message on vector lenth increasing with
%each step.



%% Run the config file:
engineConfig_Initial_2018

clear all;
clc;
close all;
%% import configuration parameters

load inputs.mat
load constants.mat
load targets.mat
load configfile.mat

D_port(1) = Dport_init;

mdot_ox = mdot_oxinit; %at the moment I assume we can supply this much mass flow rate, although we should really be putting in the value that adam baker gives us.

expansionRatio=A_exit/A_throat;

%% peform simulation

deltaT=0.01; %[s] timestep
qburnfin = 0; %parameter that determines whether the burn is completed or not (0 when not completed, 1 when completed)


t=0;
ti=1; %time index


%%

thresh = 1e-6; % [kg m^-2 s^-1]threshold difference in flow flux for iteratively solving fuel reg rate and mass flow rates.

while qburnfin == 0
    
    % 2. determine fuel regression rate & % 3. determine total mass flow rate
    
    G_ox(ti) = 4*mdot_ox/(pi*(D_port(ti))^2);
    
    G_prop(ti) = G_ox(ti); %as a starting point
    
    val(1) = G_prop(ti); %stored temporarily to check for convergence
    
    for loopind = 1:1000
        
        S(ti) = pi*D_port(ti)*Lp;
        
        rdot(ti) = a*G_prop(ti)^n*Lp^m;
        
        mdot_fuel(ti) = rdot(ti)*rho_f*S(ti);
        
        G_ox(ti) = 4*mdot_ox/(pi*(D_port(ti))^2);
        
        G_fuel(ti) = 4*mdot_fuel(ti)./(pi*(D_port(ti))^2); %#ok<*SAGROW>
        
        G_prop(ti) = G_ox(ti)+G_fuel(ti);
        
        val(loopind+1) = G_prop(ti);
        
        if abs(val(loopind)-val(loopind+1))<thresh
            break;
        end
        
    end
    
    mdot_prop(ti)=mdot_ox+mdot_fuel(ti); %[kg/s]
    
    % 4. determine thermochemistry
    
    OF(ti)=mdot_ox/mdot_fuel(ti);
    
    [T_flame(ti), gamma(ti), m_mol(ti), R(ti), c_star(ti)] = thermochem(OF,etac); % runs a script called thermochem to determine these numbers.
    
    T_stag(ti) = T_flame(ti); %Approximation! Need better formula for stagnation temp of flow
    
    
    % 5. determine eng perf
    
    P_cc(ti) = mdot_prop(ti)*c_star(ti)/A_throat; %assume there is no throat erosion for now - should be updated
    
    P_stag(ti) = P_cc(ti); %approximation! need to check if better formula exists.
    
    [M_exit(ti), Tratio(ti), Pratio(ti), rhoratio(ti), ~] = flowisentropic(gamma(ti), expansionRatio, 'sup');
    
    T_exit(ti) = T_stag(ti)*Tratio(ti);
    P_exit(ti) = P_stag(ti)*Pratio(ti);
    
    v_exit(ti) = M_exit(ti)*sqrt(gamma(ti)*R(ti)*T_exit(ti));
    
    F(ti) = lambda*(mdot_prop(ti)*v_exit(ti) + (P_exit(ti)-P_amb)*A_exit); %thrust
    
    Isp(ti) = F(ti)/(mdot_prop(ti)*g0);
    
    % 6. update geometry
    fuelweb(ti+1) = fuelweb(ti)-rdot(ti)*deltaT;
    
    D_port(ti+1) = D_port(ti)+2*rdot(ti)*deltaT;
    
    ti=ti+1; %increment the time index
    t=t+deltaT; %increment the time
    
    % 8. check if burn is completed, and go to next step
    
    %qburnfin = checkburnfin(); % a full function could be written to
    %perform this check properly.At the moment it just checks for burn
    %time completion.
    
    %Things to check:
    % (1) chamber pressure < ox tank pressure
    % (2) Choked flow
    % (3) fuel is not entirely eaten up
    
    if fuelweb(end)<=0 %using only condition 3 for now
        qburnfin=1;
    else
        qburnfin=0;
    end
    
end

fuelweb = fuelweb(1:end-1);
D_port = D_port(1:end-1);

%%
I_total_result = sum(F)*deltaT

t_burn_result = t

t_axis = 0:deltaT:t_burn_result;

F_init_result  = F(1)

Isp_avg = mean(Isp)

m_f_total = sum(mdot_fuel)*deltaT

m_ox_total = sum(mdot_ox)*deltaT;

m_prop_total = sum(mdot_prop)*deltaT

save sim_results.mat I_total_result F_init_result

%% plot results

qplot = 1;

if qplot == 1
    
    figure(1);
    
    subplot(3,4,1)
    plot(t_axis,F,[0],[0])
    title('F')

    subplot(3,4,2)
    plot(t_axis,c_star,[0],[0])
    title('c star')

    
    subplot(3,4,3)
    plot(t_axis,D_port,[0],[0])
    
    title('D port')
    
    subplot(3,4,4)
    plot(t_axis,G_ox,[0],[0])
    title('G ox')
    
    subplot(3,4,5)
    plot(t_axis,G_fuel,[0],[0])
    title('G fuel')
    
    subplot(3,4,6)
    plot(t_axis,G_prop,[0],[0])
    title('G prop')
    
    subplot(3,4,7)
    plot(t_axis,mdot_fuel,[0],[0])
    title('mdot fuel')
    
    subplot(3,4,8)
    plot(t_axis,Isp,[0],[0])
    title('Isp')
    
    subplot(3,4,9)
    plot(t_axis,M_exit,[0],[0])
    title('M exit')
    
    subplot(3,4,10)
    plot(t_axis,OF,[0],[0])
    title('OF')
    
    subplot(3,4,11)
    plot(t_axis,P_cc,[0],[0])
    title('P cc')
    
    subplot(3,4,12)
    plot(t_axis,P_exit,[0],[0])
    title('P exit')
    
end










