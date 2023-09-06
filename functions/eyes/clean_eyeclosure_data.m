function EyeClosed = clean_eyeclosure_data(Eyes, EEGMetadata, Triggers, CleanEyeIndx, SampleRate, ConfidenceThreshold)

TaskTime = identify_task_timepoints(EEGMetadata, Triggers); % for data quality, it needs to see if there's enough clean data during the task
Eye = check_eye_dataquality(Eyes, CleanEyeIndx, ConfidenceThreshold, TaskTime);
EyeClosed = detect_eyeclosure(Eye, SampleRate, ConfidenceThreshold);
