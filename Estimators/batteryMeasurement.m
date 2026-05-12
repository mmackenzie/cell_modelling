function y = batteryMeasurement(x, u)

    current = u(1);
    OCV = u(2);
    R0 = u(3);

    % Terminal Voltage Calculation
    % V_terminal = V_ocv + V_transients + V_ohmic
    y = OCV + x(2) + x(3) + x(4) + (current * R0);
end