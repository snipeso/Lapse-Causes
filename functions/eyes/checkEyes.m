function Eye = checkEyes(Eyes, DQ, ConfidenceThreshold, TaskTime)
% checks that the data quality for the chosen eye meets acceptable criteria
% returns a blank if it's not ok

% if no chosen eye, quit right now
if isempty(DQ) || isnan(DQ) || DQ==0
    warning('no good eye')
    Eye = [];
    return
end

% if no task timeline provided, just use all timepoints
if ~exist("TaskTime", 'var') || isempty(TaskTime)
    TaskTime = ones(size(1, Eyes.Raw, 2));
end

%%% Go

Eye = Eyes.Raw(round(DQ), :);

JudgeEye = Eye(TaskTime==1);


% has to be more than 50% eyes-open
if nnz(JudgeEye<ConfidenceThreshold) > .5*numel(JudgeEye)
    warning('too much EC')
    Eye = [];
    return
end


% has to have at least SOME eye closure
if nnz(JudgeEye<ConfidenceThreshold) ==0
    warning('No EC')
    Eye = [];
    return
end

