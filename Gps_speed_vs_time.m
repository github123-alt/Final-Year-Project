clear; clc; close all;

%% Load and parse the CSV file
filename = 'output_gps.csv';
fid = fopen(filename, 'r');
if fid == -1
    error('Cannot open file: %s', filename);
end

time_sec = [];
spd      = [];
lineCount = 0;

while ~feof(fid)
    line = fgetl(fid);
    if ~ischar(line) || isempty(strtrim(line))
        continue;
    end

    parts = strsplit(strtrim(line), ',');
    if length(parts) < 14
        continue;
    end

    dt_str = strtrim(parts{2});
    sp = str2double(parts{14});
    if isnan(sp)
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
    spd(end+1)      = sp;     %#ok<SAGROW>
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
spd      = spd(:);

%% Re-zero time so that 420s becomes t=0
t_offset  = 420;
time_plot = time_sec - t_offset;

% Event times in the new (shifted) reference frame
takeoff_t = 424.8 - t_offset;   %  4.8 s

%% Compute axis limits
x_min    = 0;
x_max    = 70;
vis_mask = time_plot >= x_min & time_plot <= x_max;
y_min    = min(spd(vis_mask)) - 3.0;   % extra room so labels sit below data
y_max    = max(spd(vis_mask)) + 2.0;

%% Compute min/max of visible window
spd_visible = spd(vis_mask);
t_visible   = time_plot(vis_mask);

[spd_max, idx_max] = max(spd_visible);
[spd_min, idx_min] = min(spd_visible);

t_at_max = t_visible(idx_max);
t_at_min = t_visible(idx_min);

fprintf('\n--- GPS Speed Stats (visible window: 0 to 70s) ---\n');
fprintf('Maximum Speed : %.4f m/s  at t = %.2f secs\n', spd_max, t_at_max);
fprintf('Minimum Speed : %.4f m/s  at t = %.2f secs\n', spd_min, t_at_min);
fprintf('--------------------------------------------------\n');

% Land xline at minimum speed time
land_t = t_at_min;

%% Plot
figure('Name', 'GPS Speed vs Time', 'NumberTitle', 'off', ...
    'Position', [100, 100, 1100, 580]);

% Raw data
plot(time_plot, spd, 'b-', 'LineWidth', 1.0);
hold on;

% Smoothed overlay
window     = 20;
spd_smooth = movmean(spd, window);
plot(time_plot, spd_smooth, 'r-', 'LineWidth', 2);

% Take Off vertical line
hl1 = xline(takeoff_t, '--k', 'LineWidth', 1.2);
hl1.Annotation.LegendInformation.IconDisplayStyle = 'off';

% Land vertical line
hl2 = xline(land_t, '--k', 'LineWidth', 1.2);
hl2.Annotation.LegendInformation.IconDisplayStyle = 'off';

% Take Off annotation — at the bottom
text(takeoff_t + 0.4, y_min + 0.3, 'Take Off', ...
    'FontSize', 12, 'FontWeight', 'bold', 'Color', 'k', ...
    'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom');

% Land annotation — exactly same Y level as Take Off
text(land_t + 0.4, y_min + 0.3, 'Land', ...
    'FontSize', 12, 'FontWeight', 'bold', 'Color', 'k', ...
    'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom');

% Mark MAX point
plot(t_at_max, spd_max, 'v', ...
    'MarkerSize', 12, ...
    'MarkerFaceColor', 'k', ...
    'MarkerEdgeColor', 'k');
text(t_at_max + 0.4, spd_max + 0.3, ...
    sprintf('Max: %.4f m/s @ %.2f s', spd_max, t_at_max), ...
    'FontSize', 11, ...
    'FontWeight', 'bold', ...
    'Color', 'k', ...
    'BackgroundColor', [1.00 1.00 1.00], ...
    'EdgeColor', 'k', ...
    'Margin', 4, ...
    'VerticalAlignment', 'bottom', ...
    'HorizontalAlignment', 'left');

% Mark MIN point — box to the right of xline, above Land/TakeOff labels
plot(t_at_min, spd_min, '^', ...
    'MarkerSize', 12, ...
    'MarkerFaceColor', 'k', ...
    'MarkerEdgeColor', 'k');
text(t_at_min + 0.4, spd_min + 1.8, ...
    sprintf('Min: %.4f m/s @ %.2f s', spd_min, t_at_min), ...
    'FontSize', 11, ...
    'FontWeight', 'bold', ...
    'Color', 'k', ...
    'BackgroundColor', [1.00 1.00 1.00], ...
    'EdgeColor', 'k', ...
    'Margin', 4, ...
    'VerticalAlignment', 'bottom', ...
    'HorizontalAlignment', 'left');

hold off;

%% Labels, legend, grid
xlabel('Time (secs)', 'FontSize', 13);
ylabel('GPS Speed (m/s)', 'FontSize', 13);
title('GPS Speed vs Time', 'FontSize', 15, 'FontWeight', 'bold');
legend('Raw Speed data', 'Smoothed (20-pt moving avg)', 'Location', 'northeast');
grid on;

%% Apply axis limits
xlim([x_min, x_max]);
ylim([y_min, y_max]);