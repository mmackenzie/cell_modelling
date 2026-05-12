function xNext = batteryStateTransition(x, u)

    current = u(1);
    capacity = u(2);
    Ts = u(3);
    R1 = u(4);
    C1 = u(5);
    R2 = u(6);
    C2 = u(7);
    R3 = u(8);
    C3 = u(9);

    % Calculate derivatives
    xdot = zeros(4, 1);
    xdot(1) = current / (3600 * capacity);
    xdot(2) = -1 / (R1 * C1) * x(2) + current / C1;
    xdot(3) = -1 / (R2 * C2) * x(3) + current / C2;
    xdot(4) = -1 / (R3 * C3) * x(4) + current / C3;

    % State update
    xNext = x + xdot * Ts;
end