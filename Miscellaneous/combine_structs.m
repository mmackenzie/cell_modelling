fields = fieldnames(part1);
DATA = struct();

for i = 1:numel(fields)
    f = fields{i};
    
    % Get the last time of part1
    lastTime = part1.(f).Time(end);
    
    % Compute time offset to apply to part2
    offset = seconds(lastTime - part2.(f).Time(1));
    
    % Shift part2 time
    part2_shifted = part2.(f);
    part2_shifted.Time = part2_shifted.Time + seconds(offset);
    
    % Concatenate timetables
    DATA.(f) = [part1.(f); part2_shifted];
end
