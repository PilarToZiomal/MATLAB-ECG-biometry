function style_confusionchart(cc)
%STYLE_CONFUSIONCHART Apply consistent styling to a confusionchart.

if isempty(cc)
    return;
end

if isprop(cc, "FontName"); cc.FontName = "Helvetica"; end
if isprop(cc, "FontSize"); cc.FontSize = 11; end
if isprop(cc, "FontColor"); cc.FontColor = [0 0 0]; end
if isprop(cc, "TextColor"); cc.TextColor = [0 0 0]; end
if isprop(cc, "GridVisible"); cc.GridVisible = "on"; end
if isprop(cc, "ColorbarVisible"); cc.ColorbarVisible = "off"; end
if isprop(cc, "Colormap"); cc.Colormap = parula; end

try
    ax = ancestor(cc, "axes");
catch
    ax = [];
end

if ~isempty(ax)
    try
        set(ax, "Color", "w", "XColor", "k", "YColor", "k", ...
            "LineWidth", 1, "FontName", "Helvetica", "FontSize", 11);
        if isprop(ax, "Title") && ~isempty(ax.Title)
            ax.Title.Color = "k";
        end
        colormap(ax, parula);
    catch
    end
end
end
