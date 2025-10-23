function Q_loss = extrapolate_calendar(p, t, T, SOC, R, SOC_ref)
    k_cal = p(1);
    Ea    = p(2);
    k_soc = p(3);
    Q_loss = k_cal .* exp(-Ea ./ (R * (T + 273.15))) .* ...
             exp(k_soc .* (SOC - SOC_ref)) .* (t .^ 0.6);
end
