function Q_loss = extrapolate_cycling(p, N, T, R)
    k_cyc = p(1);
    Ea    = p(2);
    % b_DoD = p(3);
    % b_Cr  = p(4);
    % Q_loss = k_cyc .* exp(-Ea ./ (R * (T + 273.15))) .* ...
    %          (DoD .^ b_DoD) .* (Cr .^ b_Cr) .* N;
    Q_loss = k_cyc .* exp(-Ea ./ (R * (T + 273.15))) .* (N .^ 0.9);
end
