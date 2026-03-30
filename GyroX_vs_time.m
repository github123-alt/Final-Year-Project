clear; clc; close all;

%% Load and parse the CSV file
filename = 'output_IMU.csv';
fid = fopen(filename, 'r');
if fid == -1
    error('Cannot open file: %s', filename);
end

time_sec = [];
gyroX    = [];
lineCount = 0;

while ~feof(fid)
    line = fgetl(fid);
    if ~ischar(line) || isempty(strtrim(line))
        continue;
    end

    parts = strsplit(strtrim(line), ',');
    if length(parts) < 6
        continue;
    end

    dt_str = strtrim(parts{2});
    gX = str2double(parts{6});
    if isnan(gX)
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
    gyroX(end+1)    = gX;     %#ok<SAGROW>
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
gyroX    = gyroX(:);

%% Re-zero time so that 420s becomes t=0
t_offset  = 420;
time_plot = time_sec - t_offset;

% Event times in the new (shifted) reference frame
takeoff_t = 424.8 - t_offset;   %  4.8 s

%% Compute axis limits
x_min    = 0;
x_max    = 70;
vis_mask = time_plot >= x_min & time_plot <= x_max;
y_min    = min(gyroX(vis_mask)) - 0.05;
y_max    = max(gyroX(vis_mask)) + 0.05;

%% Compute min/max of visible window
gX_visible = gyroX(vis_mask);
t_visible  = time_plot(vis_mask);

[gX_max, idx_max] = max(gX_visible);
[gX_min, idx_min] = min(gX_visible);

t_at_max = t_visible(idx_max);
t_at_min = t_visible(idx_min);

fprintf('\n--- Gyro X Stats (visible window: 0 to 70s) ---\n');
fprintf('Maximum GyroX : %.6f rad/s  at t = %.2f secs\n', gX_max, t_at_max);
fprintf('Minimum GyroX : %.6f rad/s  at t = %.2f secs\n', gX_min, t_at_min);
fprintf('------------------------------------------------\n');

% Align Land xline with minimum gyroX time
land_t = t_at_min;

%% Plot
figure('Name', 'Gyro X vs Time', 'NumberTitle', 'off', ...
    'Position', [100, 100, 1100, 580]);

% Raw data
plot(time_plot, gyroX, 'b-', 'LineWidth', 1.0);
hold on;

% Smoothed overlay
window    = 20;
gX_smooth = movmean(gyroX, window);
plot(time_plot, gX_smooth, 'r-', 'LineWidth', 2);

% Take Off vertical line
hl1 = xline(takeoff_t, '--k', 'LineWidth', 1.2);
hl1.Annotation.LegendInformation.IconDisplayStyle = 'off';

% Land vertical line
hl2 = xline(land_t, '--k', 'LineWidth', 1.2);
hl2.Annotation.LegendInformation.IconDisplayStyle = 'off';

% Take Off annotation
text(takeoff_t + 0.5, y_min + 0.01, 'Take Off', ...
    'FontSize', 12, 'FontWeight', 'bold', 'Color', 'k', ...
    'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom');

% Land annotation
text(land_t + 0.5, y_min + 0.01, 'Land', ...
    'FontSize', 12, 'FontWeight', 'bold', 'Color', 'k', ...
    'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom');

% Mark MAX point
plot(t_at_max, gX_max, 'v', ...
    'MarkerSize', 12, ...
    'MarkerFaceColor', 'k', ...
    'MarkerEdgeColor', 'k');
text(t_at_max + 0.5, gX_max - 0.01, ...
    sprintf('  Max: %.6f rad/s @ %.2f s', gX_max, t_at_max), ...
    'FontSize', 11, ...
    'FontWeight', 'bold', ...
    'Color', 'k', ...
    'BackgroundColor', [1.00 1.00 1.00], ...
    'EdgeColor', 'k', ...
    'Margin', 4, ...
    'VerticalAlignment', 'top', ...
    'HorizontalAlignment', 'left');

% Mark MIN point
plot(t_at_min, gX_min, '^', ...
    'MarkerSize', 12, ...
    'MarkerFaceColor', 'k', ...
    'MarkerEdgeColor', 'k');
text(t_at_min - 0.5, gX_min + 0.03, ...
    sprintf('Min: %.6f rad/s @ %.2f s', gX_min, t_at_min), ...
    'FontSize', 11, ...
    'FontWeight', 'bold', ...
    'Color', 'k', ...
    'BackgroundColor', [1.00 1.00 1.00], ...
    'EdgeColor', 'k', ...
    'Margin', 4, ...
    'VerticalAlignment', 'bottom', ...
    'HorizontalAlignment', 'right');

hold off;

%% Labels, legend, grid
xlabel('Time (secs)', 'FontSize', 13);
ylabel('Gyro X (rad/s)', 'FontSize', 13);
title('Gyro X vs Time', 'FontSize', 15, 'FontWeight', 'bold');
legend('Raw GyroX data', 'Smoothed (20-pt moving avg)', 'Location', 'northeast');
grid on;

%% Apply axis limits
xlim([x_min, x_max]);
ylim([y_min, y_max]);