# TODO: update with real roles
roles = if Rails.env.test?
          YAML.load_file(Rails.root.join('test/cas_applicant_roles.yml'))
        else
          YAML.load_file(Rails.root.join('config/cas_applicant_roles.yml'))
        end

CANCER_ANALYST_DATASETS = roles['ndrs_analyst']['datasets']
NDRS_DEVELOPER_DATASETS = roles['ndrs_developer']['datasets']
NDRS_QA_DATASETS = roles['ndrs_qa']['datasets']
