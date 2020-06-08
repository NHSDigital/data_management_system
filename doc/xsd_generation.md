To build samples for all:
Seed the database:

* bin/rake xsd:all
currently builds a schema file(s) in tmp

alternatively
* bin/rake xsd:all_zip

will currently build zips in tmp

can be tested against an xml file. some samples in test/xml_files

* configure run_test: true in config/xsd.yml
* bin/rails test test/models/schema_test.rb

TODO: 
NHS Digital built v2 and v3 COSDPathology as v7 and v8
Building as COSD_Pathology going forwards to avoid the clash at genuine version 4.
Build original v8 again and validate as COSDPathology quick hack done to manual sample files
to validate them against COSD_Pathology-v3-0 - able to carry on with schema diff'ing work.
