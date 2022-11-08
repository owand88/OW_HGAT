---METRIC_GROUP_NAME = tugrul_test
---OWNER = tates
---TEAM = 
---PARTITION_DATE = counter_date
---MATURITY_GAP = 1
---FREQUENCY = daily
---PII = No



-- Set the dynamic variable value by running the code and refresing its value
%refresh_var(${counter_var})
;

-- Update the counter column in the table
insert into p_workbench_t.dynamic_variable_test (counter) values (${counter_var} + 1)
;

-- Return the final results
select
counter as counter_value
,current_date() - 1 as counter_date
from p_workbench_t.dynamic_variable_test