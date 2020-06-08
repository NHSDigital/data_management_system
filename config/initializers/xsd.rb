settings = YAML.safe_load(File.open(Rails.root.join('config', 'xsd.yml')))
RUN_SCHEMA_TESTS = settings['run_test']
RANDOM_OPTIONAL_ELEMENTS = settings['Random_optional_elements']
PRINT_TEST_OUTPUT = settings['print_test_output']