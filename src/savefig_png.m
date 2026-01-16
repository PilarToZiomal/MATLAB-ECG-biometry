function savefig_png(fig, outPath, dpi)
%SAVEFIG_PNG Save a figure as PNG with consistent styling.
% Inputs:
%   fig     - figure handle
%   outPath - full output path ending in .png
if nargin < 3 || isempty(dpi); dpi = 200; end

outDir = fileparts(outPath);
if ~exist(outDir, "dir"); mkdir(outDir); end

if isempty(fig) || ~ishandle(fig)
    fig = gcf;
end

set(fig, "Color", "w");
set(fig, "MenuBar", "none");

ax = findall(fig, "Type", "axes");
for k = 1:numel(ax)
    try
        if isprop(ax(k), "Toolbar") && ~isempty(ax(k).Toolbar)
            ax(k).Toolbar.Visible = "off";
        end
    catch
    end
    try
        disableDefaultInteractivity(ax(k));
    catch
    end
    try
        set(ax(k), "Color", "w", "XColor", "k", "YColor", "k", ...
            "GridColor", [0.8 0.8 0.8], "MinorGridColor", [0.9 0.9 0.9], ...
            "FontName", "Helvetica", "FontSize", 11, "LineWidth", 1, "Box", "on");
    catch
    end
end

txt = findall(fig, "Type", "text");
try
    set(txt, "Color", "k", "FontName", "Helvetica");
catch
end

lgd = findall(fig, "Type", "legend");
try
    set(lgd, "TextColor", "k", "FontName", "Helvetica", "Box", "off");
catch
end

try
    exportgraphics(fig, outPath, "Resolution", dpi, "BackgroundColor", "white");
catch
    print(fig, outPath, "-dpng", sprintf("-r%d", dpi));
end
end
