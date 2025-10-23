classdef Plotting
    % Plotting class for visualisation of degradation models
    % Contains static methods for plotting fits, extrapolations,
    % and customer-facing SOH trajectories

    methods (Static)
        
        function plot_temperature_histograms(storage_hist, cycling_hist, temperature_bins)
            storage_per_temp = sum(storage_hist, 1);   % sum over SOC axis
            cycling_per_temp = sum(cycling_hist, 1);

            figure('Position', [100, 100, 400, 800]);
            subplot(2,1,1);
            bar(temperature_bins, storage_per_temp, 'FaceColor', [0.2 0.6 0.8]);
            xlabel('Temperature [°C]');
            ylabel('Days in storage');
            title('Storage histogram vs temperature');
            grid on;
            
            subplot(2,1,2);
            bar(temperature_bins, cycling_per_temp, 'FaceColor', [0.8 0.3 0.2]);
            xlabel('Temperature [°C]');
            ylabel('Cycles');
            title('Cycling histogram vs temperature');
            grid on;
        end

        function plot_3D_histograms(storage_hist, cycling_hist, temperature_bins, soc_bins, c_rate_bins)            
            figure('Position', [100, 100, 400, 800]);
            subplot(2,1,1)
            bar3(storage_hist);
            xlabel('Temperature [°C]');
            ylabel('SOC [%]');
            zlabel('Days in storage');
            title('Storage histogram (temperature and SOC)');
            colormap('turbo');
            
            xticks(1:numel(temperature_bins));
            xticklabels(temperature_bins);
            yticks(1:numel(soc_bins));
            yticklabels(soc_bins);
            
            subplot(2,1,2)
            bar3(cycling_hist)
            ylabel('C-rate [-]');
            xlabel('Temperature [°C]');
            zlabel('Cycles');
            title('Cycling histogram (temperature and C-rate)');
            colormap('turbo');

            xticks(1:numel(temperature_bins));
            xticklabels(temperature_bins);
            yticks(1:numel(c_rate_bins));
            yticklabels(c_rate_bins);
        end

        
        function plot_fit(Q_meas, Q_pred, title_str, rmse, R2)
            figure; hold on; grid on;
            scatter(Q_meas, Q_pred, 'filled');
            plot([0 100], [0 100], 'k--', 'LineWidth', 2)
            xlabel('Measured relative capacity (%)');
            ylabel('Predicted relative capacity (%)');
            title(sprintf('%s | RMSE=%.2f | R^2=%.2f', title_str, rmse, R2));
            if contains(title_str, 'Calendar')
                xlim([90 100]); ylim([90 100]);
            else
                xlim([80 100]); ylim([80 100]);
            end
        end

        function plot_calendar_extrapolation(storage_data, p_cal, f_cal)
            fnames = fieldnames(storage_data);
            t_extrap = (0:1:3*365)';
            figure; hold on;
            defaultColours = get(groot, 'defaultAxesColorOrder');
            colours = defaultColours(1:5, :);
            for i = 1:numel(fnames)
                d = storage_data.(fnames{i});
                plot(d.day / 365, d.relative_capacity, '*', 'Color', colours(i, :), ...
                    'DisplayName', sprintf('%d°C - measured', d.temperature), 'MarkerSize', 10)
                plot(t_extrap / 365, 100 - f_cal(p_cal, [t_extrap d.temperature*ones(size(t_extrap)) d.soc(1)*ones(size(t_extrap))]), ...
                    '--', 'Color', colours(i, :), 'DisplayName', sprintf('%d°C - estimated', d.temperature), 'LineWidth', 1.5)
            end
            xlabel('Years'); ylabel('Relative capacity (%)');
            title('Measured vs extrapolated storage data');
            grid on; ylim([70 100]);
            legend('Location', 'best');
        end

        function plot_cycling_extrapolation(cycling_data, p_cyc, f_cyc)
            fnames = fieldnames(cycling_data);
            N_extrap = (0:100:3000)';
            figure; hold on;
            defaultColours = get(groot, 'defaultAxesColorOrder');
            colours = defaultColours(1:5, :);
            for i = 1:numel(fnames)
                d = cycling_data.(fnames{i});
                plot(d.cycle, d.relative_capacity, '*', 'Color', colours(i, :), ...
                    'DisplayName', sprintf('%d°C - measured', d.temperature), 'MarkerSize', 10)
                plot(N_extrap, 100 - f_cyc(p_cyc, [N_extrap d.temperature * ones(size(N_extrap))]), ...
                    '--', 'Color', colours(i, :), 'DisplayName', sprintf('%d°C - estimated', d.temperature), 'LineWidth', 1.5)
            end
            xlabel('Cycles'); ylabel('Relative capacity (%)');
            title('Measured vs extrapolated cycling data');
            grid on; ylim([70 100]);
            legend('Location', 'best');
        end

        function plot_calendar_soc_dependency(p_cal, f_cal, SOC_ref)
            SOC_range = (0:10:100)';
            soc_multiplier = exp(p_cal(3) .* (SOC_range - SOC_ref));
            
            figure; plot(SOC_range, soc_multiplier, 'LineWidth', 2);
            xlabel('SOC (%)'); ylabel('SOC multiplier');
            title('Effect of SOC on calendar ageing');
            grid on;

            t_extrap = (0:30:5*365)'; % up to 5 years
            SOC_levels = [10, 30, 50, 70, 90, 100];
            T_plot = 25;  % Fixed reference temperature (25°C)
            
            figure; hold on;
            colors = lines(numel(SOC_levels));
            for i = 1:numel(SOC_levels)
                SOC_val = SOC_levels(i);
                Qloss_SOC = f_cal(p_cal, [t_extrap T_plot*ones(size(t_extrap)) SOC_val*ones(size(t_extrap))]);
                Q_pred_SOC = 100 - Qloss_SOC;
                plot(t_extrap/365, Q_pred_SOC, 'Color', colors(i,:), 'LineWidth', 1.5, ...
                    'DisplayName', sprintf('SOC = %d%%', SOC_val));
            end
            xlabel('Years'); ylabel('Relative capacity (%)');
            title(sprintf('Calendar ageing at %d°C as a function of SOC', T_plot));
            grid on;
            ylim([80 100]);
            legend('Location', 'best');
        end

        function plot_SOH_trajectory(time, SOH)
            figure; hold on; grid on;
            plot(time/365, SOH, 'LineWidth', 2);
            xlabel('Time (years)');
            ylabel('State of Health (%)');
            ylim([70 100]);
            title('Predicted SOH trajectory');
        end

    end
end
