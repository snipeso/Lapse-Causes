function EEG = remove_noise(EEG, Cuts_Filepath)
% from EEGLAB structured data, looks for corresponding .mat file where
% manual scoring of noise output was saved (in /Cleaning/Cuts/) as a TMPREJ
% array, which is a n x (2+3+ # channels) matrix. The first two columns are
% the start and end timepoints of the artefact. 

m = matfile(Cuts_Filepath);

Artefacts = m.TMPREJ;
ArtefactsSampleRate = m.srate;

if ~isempty(Artefacts)
    Starts = convert_samplerate(Artefacts(:, 1), ArtefactsSampleRate, EEG.srate);
    Ends = convert_samplerate(Artefacts(:, 2), ArtefactsSampleRate, EEG.srate);
    
    % handle edge cases due to resampling
    if any(Ends > size(EEG.data, 2))
        Diff = max(Ends) - size(EEG.data, 2);
        warning([num2str(Diff), ' extra samples'])
        
        if Diff > 10
            error(['Too much discrepancy for ', EEG.filename])
        end
        
        % set end to file end
        Ends(Ends>size(EEG.data, 2)) = size(EEG.data, 2);
    end
    
    % set to NaN all values that were marked as noise
    for Indx_N = 1:numel(Starts)
        EEG.data(:, Starts(Indx_N):Ends(Indx_N)) = nan;
    end
end
end


function Point = convert_samplerate(Point, fs1, fs2)
Time = Point./fs1; % written out so my tired brain understands
Point = round(Time.*fs2);
end