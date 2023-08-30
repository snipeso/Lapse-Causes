% for each participant, plots the burst criteria used to evaluate bursts,
% to determine if any of them are redundant

Parameters = analysisParameters();
Paths = Parameters.Paths;
Task = Parameters.Task;
Participants = Parameters.Participants;
Sessions = Parameters.Sessions.LAT;
Sessions = {'Session2Beam1'};

Source_Bursts = fullfile(Paths.AnalyzedData, 'EEG', 'Bursts_New', Task);

for idxParticipant = 1:numel(Participants)
for idxSession = 1 %:numel(Sessions)
            Bursts = load_datafile(Source_Bursts, Participants{idxParticipant}, Sessions{idxSession}, 'Bursts');
        if isempty(Bursts); continue; end

    cycy.plot.burst_criteriaset_diagnostics(Bursts)
    title([Participants{idxParticipant}, ' ', Sessions{idxSession}])

end
end