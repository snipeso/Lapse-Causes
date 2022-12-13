function Bursts = hemifieldBursts(Bursts, EEG, Triggers)
% determine whether the burst occured during a left (-1) or right (1) block
% or neither (0)


TriggerTypes = {EEG.events.type};
TriggerTimes = [EEG.events.latency];

LeftStarts = TriggerTimes(strcmp(TriggerTypes, Triggers.LeftBlock));
LeftEnds = LeftStarts + 2*60*fs; % 2 minutes for each block

RightStarts = TriggerTimes(strcmp(TriggerTypes, Triggers.LeftBlock));
RightEnds = RightStarts + 2*60*fs; % 2 minutes for each block


for Indx_B = 1:numel(Bursts)

    B = Bursts(Indx_B);


    if any(B.All_Start > LeftStarts & B.All_End < LeftEnds)
        Bursts(Indx_B).Hemifield = -1;
    elseif any(B.All_Start > RightStarts & B.All_End < RightEnds)
        Bursts(Indx_B).Hemifield = 1;
    else
        Bursts(Indx_B).Hemifield = 0;
    end
end