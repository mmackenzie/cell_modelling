function model = fit_degradation_models(storage_data, cycling_data, R, SOC_ref)
    % Fit calendar and cycling models
    calendar_model = fit_calendar(storage_data, R, SOC_ref);
    cycling_model = fit_cycling(cycling_data, R);

    % Pack into a single struct
    model.calendar = calendar_model;
    model.cycling = cycling_model;
end
