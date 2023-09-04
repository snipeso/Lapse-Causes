function TaskPoints = identify_task_timepoints(EEG, Triggers)

TimepointsCount = size(EEG.data, 2);
TaskPoints = zeros(1, TimepointsCount);

TriggerTypes = {EEG.event.type};
TriggerLatencies = [EEG.event.latency];

StartTask = round(TriggerLatencies(strcmp(TriggerTypes, Triggers.Start)));
if isempty(StartTask)
    StartTask = 1;
end

EndTask = round(TriggerLatencies(strcmp(TriggerTypes, Triggers.End)));
if isempty(EndTask)
    EndTask = numel(TaskPoints);
end

TaskPoints(StartTask:EndTask) = 1;
end
