function isLeft = hemifieldTime(Events, Triggers, t)
% creates nans ones and zeros vector of whether trial was left hemifield or
% right.

t_max = numel(t);
isLeft = nan(1, t_max);

EventTypes = {Events.type};
EventTimes = round([Events.latency]);

LeftStarts = EventTimes(strcmp(EventTypes, Triggers.LeftBlock));
RightStarts = EventTimes(strcmp(EventTypes, Triggers.RightBlock));
End = EventTimes(strcmp(EventTypes, Triggers.End));

if LeftStarts(1)<RightStarts(1)
    Left = windows2time(LeftStarts, RightStarts, t_max);
    Right = windows2time(RightStarts, [LeftStarts(2:end), End], t_max);
else

    Right = windows2time(RightStarts, LeftStarts, t_max);
    Left = windows2time(LeftStarts, [RightStarts(2:end), End], t_max);
end

isLeft(Left) = 1;
isLeft(Right) = 0;

end



function Time = windows2time(Starts, Ends, t_max)

Time = false(1, t_max);

for Indx_S = 1:numel(Starts)
    Time(Starts(Indx_S):Ends(Indx_S)) = true;
end
end