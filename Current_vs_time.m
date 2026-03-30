clear; clc; close all;

%% Load and parse the CSV file
filename = 'Voltage_Output.csv';
fid = fopen(filename, 'r');
if fid == -1
    error('Cannot open file: %s', filename);
end

time_sec = [];
current  = [];
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
    Cur = str2double(parts{8});
    if isnan(Cur)
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
    current(end+1)  = Cur;    %#ok<SAGROW>
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
current  = current(:);

%% Re-zero time so that 420s becomes t=0
t_offset  = 420;
time_plot = time_sec - t_offset;

% Event times in the new (shifted) reference frame
takeoff_t = 424.8 - t_offset;   %  4.8 s
land_t    = 53.9;                  %  53.9 s

%% Compute axis limits
x_min    = 0;
x_max    = 70;
vis_mask = time_plot >= x_min & time_plot <= x_max;
y_min    = min(current(vis_mask)) - 2;     % extra padding at bottom for annotations
y_max    = max(current(vis_mask)) + 3;     % extra padding at top for Max box

%% Compute min/max
cur_visible = current(vis_mask);
t_visible   = time_plot(vis_mask);

[cur_max, idx_max] = max(cur_visible);
[cur_min, idx_min] = min(cur_visible);

t_at_max = t_visible(idx_max);
t_at_min = t_visible(idx_min);

fprintf('\n--- Current Drawn Stats (visible window: 0 to 70s) ---\n');
fprintf('Maximum Current : %.4f A  at t = %.2f secs\n', cur_max, t_at_max);
fprintf('Minimum Current : %.4f A  at t = %.2f secs\n', cur_min, t_at_min);
fprintf('------------------------------------------------------\n');

%% Plot
figure('Name', 'Current Drawn vs Time', 'NumberTitle', 'off', ...
    'Position', [100, 100, 1100, 580]);

% Raw data
plot(time_plot, current, 'b-', 'LineWidth', 1.0);
hold on;

% Smoothed overlay
window     = 20;
cur_smooth = movmean(current, window);
plot(time_plot, cur_smooth, 'r-', 'LineWidth', 2);

% Take Off vertical line
hl1 = xline(takeoff_t, '--k', 'LineWidth', 1.2);
hl1.Annotation.LegendInformation.IconDisplayStyle = 'off';

% Land vertical line
hl2 = xline(land_t, '--k', 'LineWidth', 1.2);
hl2.Annotation.LegendInformation.IconDisplayStyle = 'off';

% Take Off annotation — right of xline, just above bottom
text(takeoff_t + 0.5, y_min + 0.5, 'Take Off', ...
    'FontSize', 12, 'FontWeight', 'bold', 'Color', 'k', ...
    'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom');

% Land annotation — right of xline, just above bottom
text(land_t + 0.5, y_min + 0.5, 'Land', ...
    'FontSize', 12, 'FontWeight', 'bold', 'Color', 'k', ...
    'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom');

% Mark MAX point — placed just below the top padding area
plot(t_at_max, cur_max, 'v', ...
    'MarkerSize', 12, ...
    'MarkerFaceColor', 'k', ...
    'MarkerEdgeColor', 'k');
text(t_at_max + 0.5, y_max - 0.5, ...
    sprintf('  Max: %.4f A @ %.2f s', cur_max, t_at_max), ...
    'FontSize', 11, ...
    'FontWeight', 'bold', ...
    'Color', 'k', ...
    'BackgroundColor', [1.00 1.00 1.00], ...
    'EdgeColor', 'k', ...
    'Margin', 4, ...
    'VerticalAlignment', 'top', ...
    'HorizontalAlignment', 'left');

% Mark MIN point — above the marker, left-aligned to avoid Land overlap
plot(t_at_min, cur_min, '^', ...
    'MarkerSize', 12, ...
    'MarkerFaceColor', 'k', ...
    'MarkerEdgeColor', 'k');
text(t_at_min - 0.5, cur_min + 1.5, ...
    sprintf('Min: %.4f A @ %.2f s  ', cur_min, t_at_min), ...
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
ylabel('Current Drawn (Amp)', 'FontSize', 13);
title('Current Drawn vs Time', 'FontSize', 15, 'FontWeight', 'bold');
legend('Current Drawn raw data', 'Smoothed (20-pt moving avg)', 'Location', 'northeast');
grid on;

%% Apply axis limits
xlim([x_min, x_max]);
ylim([y_min, y_max]);