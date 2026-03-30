clear; clc; close all;

%% Load and parse the CSV file
filename = 'output_att.csv';
fid = fopen(filename, 'r');
if fid == -1
    error('Cannot open file: %s', filename);
end

time_sec = [];
att_pitch = [];
lineCount = 0;

while ~feof(fid)
    line = fgetl(fid);
    if ~ischar(line) || isempty(strtrim(line))
        continue;
    end

    % Split by comma
    parts = strsplit(strtrim(line), ',');
    if length(parts) < 10
        continue;
    end

    % Column 2: datetime string
    dt_str = strtrim(parts{2});
    % Column 7: Att.Pitch in degrees
    val = str2double(parts{7});
    if isnan(val)
        continue;
    end

    % Parse datetime
    try
        dt = datetime(dt_str, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS');
    catch
        try
            dt = datetime(dt_str, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SS');
        catch
            continue;
        end
    end

    % Convert datetime to seconds
    t_num = datenum(dt);
    time_sec(end+1) = t_num;  %#ok<SAGROW>
    att_pitch(end+1) = val;   %#ok<SAGROW>
    lineCount = lineCount + 1;
end

fclose(fid);
fprintf('Successfully parsed %d data points.\n', lineCount);

if lineCount == 0
    error('No valid data points found.');
end

%% Convert time to seconds from start
time_sec = (time_sec - time_sec(1)) * 86400;

%% Re-zero time so that 420s becomes t=0
t_offset  = 420;
time_plot = time_sec - t_offset;

%% Column vectors
time_plot = time_plot(:);
att_pitch = att_pitch(:);

fprintf('Time range : %.1f seconds (after offset)\n', max(time_plot));
fprintf('Att.Pitch  : %.2f deg to %.2f deg\n', min(att_pitch), max(att_pitch));

%% Visible window
x_min    = 0;
x_max    = max(time_plot) + 5;
vis_mask = time_plot >= x_min & time_plot <= x_max;

y_min    = min(att_pitch(vis_mask)) - 3;
y_max    = max(att_pitch(vis_mask)) + 3;

%% Plot
figure('Name', 'Att.Pitch vs Time', 'NumberTitle', 'off', ...
    'Position', [100, 100, 1100, 550]);

% Raw data
plot(time_plot, att_pitch, 'b-', 'LineWidth', 1.0);
hold on;

% Smoothed overlay
window      = 20;
pitch_smooth = movmean(att_pitch, window);
plot(time_plot, pitch_smooth, 'r-', 'LineWidth', 2);

% Takeoff vertical line
takeoff_t = 424.8 - t_offset;   % shifted to new reference
xline(takeoff_t, '--k', 'LineWidth', 1.2);
text(takeoff_t + 0.5, y_min + 0.5, 'Take Off', ...
    'FontSize', 12, 'FontWeight', 'bold', 'Color', 'k', ...
    'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom');

% Land vertical line fixed at 53.9s
land_t = 53.9;
xline(land_t, '--k', 'LineWidth', 1.2);
text(land_t + 0.5, y_min + 0.5, 'Land', ...
    'FontSize', 12, 'FontWeight', 'bold', 'Color', 'k', ...
    'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom');

hold off;

%% Labels, legend, grid
xlabel('Time (secs)', 'FontSize', 13);   % starts at zero now
ylabel('Att.Pitch (deg)', 'FontSize', 13);
title('Att.Pitch vs Time', 'FontSize', 15, 'FontWeight', 'bold');
legend('Raw Att.Pitch data', 'Smoothed (20-pt moving avg)', 'Location', 'best');
grid on;

%% Apply axis limits
xlim([x_min, x_max]);
ylim([y_min, y_max]);
