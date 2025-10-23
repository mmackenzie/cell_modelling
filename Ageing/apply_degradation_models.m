function [SOH_traj, Q_loss_calendar, Q_loss_cycling, time_axis, cycle_axis] = apply_degradation_models(model_params, cal_hist, cyc_hist, SOC_edges, T_edges)

    R = 8.314; % J/(mol*K)

    % Extract model parameters
    p_cal = model_params.calendar.params; % [k_cal, Ea]
    p_cyc = model_params.cycling.params;  % [k_cyc, Ea]

    % Initialize
    SOH = 100;
    SOH_traj = SOH;
    time_axis = 0; % days
    cycle_axis = 0; % cycles

    Q_loss_calendar = 0;
    Q_loss_cycling = 0;
    Q_loss_total = 0;

    % Split histograms into days
    n_years = 30;
    n_months = 12;
    cal_hist_monthly = cal_hist / n_months;
    cyc_hist_monthly = cyc_hist / n_months;

    % Keep track of cumulative time & cycles (for cumulative equations)
    total_days = 0;
    total_cycles = 0;

    for y = 1:n_years
        for m = 1:n_months
            %% --- Calendar ageing ---
            for iSOC = 1:size(cal_hist_monthly, 1)
                for iT = 1:size(cal_hist_monthly, 2)
                    dt = cal_hist_monthly(iSOC, iT); % days in this bin (for this month)
                    if dt > 0
                        T_mid = mean(T_edges(iT:iT+1));
    
                        % cumulative time for this bin
                        t_prev = f_cal_x(p_cal, Q_loss_total, T_mid, R); 
                        t_new = t_prev + dt;
    
                        % cumulative loss - previous loss
                        Q_new = f_cal(p_cal, t_new, T_mid, R);
                        Q_prev = f_cal(p_cal, t_prev, T_mid, R);
                        Q_loss_calendar = Q_loss_calendar + (Q_new - Q_prev);
                        Q_loss_total = Q_loss_total + (Q_new - Q_prev);
                    end
                end
            end
    
            %% --- Cycling ageing ---
            for iCrate = 1:size(cyc_hist_monthly, 1)
                for iT = 1:size(cyc_hist_monthly, 2)
                    dN = cyc_hist_monthly(iCrate, iT); % cycles in this bin (for this month)
                    if dN > 0
                        T_mid = mean(T_edges(iT:iT+1));
        
                        % cumulative cycles for this bin
                        N_prev = f_cyc_x(p_cal, Q_loss_total, T_mid, R); 
                        N_new = N_prev + dN;
                        total_cycles = total_cycles + dN;
        
                        Q_new = f_cyc(p_cyc, N_new, T_mid, R);
                        Q_prev = f_cyc(p_cyc, N_prev, T_mid, R);
                        Q_loss_cycling = Q_loss_cycling + (Q_new - Q_prev);
                        Q_loss_total = Q_loss_total + (Q_new - Q_prev);
                    end
                end
            end
    
            %% --- Update totals ---
            SOH = 100 - Q_loss_total;
            SOH_traj(end+1) = SOH;
            total_days = total_days + 365 / n_months;
            time_axis(end+1) = total_days;
            cycle_axis(end+1) = total_cycles;
    
            if SOH <= 70
                break
            end
        end
        if SOH <= 70
            break
        end
    end
end

%% --- Submodels ---
% Calendar ageing model: cumulative Q_loss fraction at time t
function Q_loss = f_cal(p, t_days, T_degC, R)
    Q_loss = p(1) .* exp(-p(2) ./ (R * (T_degC + 273.15))) .* t_days .^ 0.6; 
end

% Cycling ageing model: cumulative Q_loss fraction at N cycles
function Q_loss = f_cyc(p, N, T_degC, R)
    Q_loss = p(1) .* exp(-p(2) ./ (R * (T_degC + 273.15))) .* N .^ 0.9; 
end

% Calendar ageing model: time at cumulative Q_loss (solve for x)
function t_days = f_cal_x(p, Q_loss, T_degC, R)
    t_days = (Q_loss / (p(1) .* exp(-p(2) / (R * (T_degC + 273.15))))) .^ (1 / 0.6);
end

% Cycling ageing model: cumulative Q_loss fraction at N cycles
function N = f_cyc_x(p, Q_loss, T_degC, R)
    N = (Q_loss / (p(1) .* exp(-p(2) / (R * (T_degC + 273.15))))) .^ (1 / 0.9);
end
