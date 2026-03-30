clear; clc; close all;

%% Load and parse the CSV file
filename = 'output_Baro.csv';
fid = fopen(filename, 'r');
if fid == -1
    error('Cannot open file: %s', filename);
end

time_sec = [];
altitude = [];
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

    dt_str = strtrim(parts{2});
    Alt = str2double(parts{7});
    if isnan(Alt)
        continue;
    end

    try
        dt = datetime(dt_str, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS');
    catch
        try
            dt = datetime(dt_str, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SS');
        catch
            continue;
        end
    end

    t_num = datenum(dt);
    time_sec(end+1) = t_num;  %#ok<SAGROW>
    altitude(end+1) = Alt;    %#ok<SAGROW>
    lineCount = lineCount + 1;
end

fclose(fid);
fprintf('Successfully parsed %d data points.\n', lineCount);

if lineCount == 0
    error('No valid data points found.');
end

%% Convert time to seconds from start
time_sec = (time_sec - time_sec(1)) * 86400;
time_sec = time_sec(:);
altitude = altitude(:);

%% Re-zero time so that 420s becomes t=0
t_offset  = 420;
time_plot = time_sec - t_offset;

% Event times in the new (shifted) reference frame
takeoff_t = 424.8 - t_offset;   %  4.8 s

%% Compute axis limits
x_min    = 0;
x_max    = 70;
vis_mask = time_plot >= x_min & time_plot <= x_max;
y_min    = min(altitude(vis_mask)) - 4;
y_max    = max(altitude(vis_mask)) + 3;

%% Compute min/max of visible window
alt_visible = altitude(vis_mask);
t_visible   = time_plot(vis_mask);

[alt_max, idx_max] = max(alt_visible);
[alt_min, idx_min] = min(alt_visible);

t_at_max = t_visible(idx_max);
t_at_min = t_visible(idx_min);

fprintf('\n--- Barometer Altitude Stats (visible window: 0 to 70s) ---\n');
fprintf('Maximum Altitude : %.4f m  at t = %.2f secs\n', alt_max, t_at_max);
fprintf('Minimum Altitude : %.4f m  at t = %.2f secs\n', alt_min, t_at_min);
fprintf('-----------------------------------------------------------\n');

% Align Land xline with minimum altitude time
land_t = t_at_min;

%% Plot
figure('Name', 'Barometer Altitude vs Time', 'NumberTitle', 'off', ...
    'Position', [100, 100, 1100, 580]);

% Raw data
plot(time_plot, altitude, 'b-', 'LineWidth', 1.0);
hold on;

% Smoothed overlay
window     = 20;
alt_smooth = movmean(altitude, window);
plot(time_plot, alt_smooth, 'r-', 'LineWidth', 2);

% Take Off vertical line
hl1 = xline(takeoff_t, '--k', 'LineWidth', 1.2);
hl1.Annotation.LegendInformation.IconDisplayStyle = 'off';

% Land vertical line (now coincides with min altitude x)
hl2 = xline(land_t, '--k', 'LineWidth', 1.2);
hl2.Annotation.LegendInformation.IconDisplayStyle = 'off';

% Take Off annotation
text(takeoff_t + 0.5, y_min + 0.5, 'Take Off', ...
    'FontSize', 12, 'FontWeight', 'bold', 'Color', 'k', ...
    'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom');

% Land annotation
text(land_t + 0.5, y_min + 0.5, 'Land', ...
    'FontSize', 12, 'FontWeight', 'bold', 'Color', 'k', ...
    'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom');

% Mark MAX point
plot(t_at_max, alt_max, 'v', ...
    'MarkerSize', 12, ...
    'MarkerFaceColor', 'k', ...
    'MarkerEdgeColor', 'k');
text(t_at_max + 0.5, y_max - 0.2, ...
    sprintf('  Max: %.4f m @ %.2f s', alt_max, t_at_max), ...
    'FontSize', 11, ...
    'FontWeight', 'bold', ...
    'Color', 'k', ...
    'BackgroundColor', [1.00 1.00 1.00], ...
    'EdgeColor', 'k', ...
    'Margin', 4, ...
    'VerticalAlignment', 'top', ...
    'HorizontalAlignment', 'left');

% Mark MIN point — shifted downward to avoid overlap
plot(t_at_min, alt_min, '^', ...
    'MarkerSize', 12, ...
    'MarkerFaceColor', 'k', ...
    'MarkerEdgeColor', 'k');
text(t_at_min - 0.5, alt_min - 1.0, ...
    sprintf('Min: %.4f m @ %.2f s  ', alt_min, t_at_min), ...
    'FontSize', 11, ...
    'FontWeight', 'bold', ...
    'Color', 'k', ...
    'BackgroundColor', [1.00 1.00 1.00], ...
    'EdgeColor', 'k', ...
    'Margin', 4, ...
    'VerticalAlignment', 'top', ...
    'HorizontalAlignment', 'right');

hold off;

%% Labels, legend, grid
xlabel('Time (secs)', 'FontSize', 13);
ylabel('Barometer Altitude (m)', 'FontSize', 13);
title('Barometer Altitude vs Time', 'FontSize', 15, 'FontWeight', 'bold');
legend('Raw Altitude data', 'Smoothed (20-pt moving avg)', 'Location', 'northeast');
grid on;

%% Apply axis limits
xlim([x_min, x_max]);
ylim([y_min, y_max]);
