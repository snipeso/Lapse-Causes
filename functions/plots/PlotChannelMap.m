function PlotChannelMap(Chanlocs, ChannelStruct, Colors, Format)
% plots a 3D and grid map of electrode locations

Labels = fieldnames(ChannelStruct);

figure('units','normalized','outerposition',[0 0 .75 .45])
subplot(1, 3, 1)

PlotColors = ones(numel(Chanlocs), 3)*.9;

if isempty(Colors)
    Colors = getColors(numel(Labels));
end

for Indx_Cl = 1:numel(Labels)
    
    Color = Colors(Indx_Cl, :);
    Ch = ChannelStruct.(Labels{Indx_Cl});
    for Indx_Ch = 1:numel(Ch)
        Indx = labels2indexes(Ch(Indx_Ch), Chanlocs);
        if isempty(Indx)
            continue
        end
        PlotColors(Indx, :) = Color;
    end
end
bubbleTopo(PlotColors, Chanlocs, 130, '2D', true, Format)


subplot(1, 3, 2)
bubbleTopo(PlotColors, Chanlocs, 200, '3D', true, Format)


subplot(1, 3, 3)
bubbleTopo(PlotColors, Chanlocs, 200, '3D', true, Format)
view(180, 0)