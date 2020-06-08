Pseudonymisation and loading procedures
========================================================================
for the prescriptions database
========================================================================

*Documentation by KH - 11th November 2016*


Overview
--------
This article describes the pseudonymisation and loading procedure used for electronic prescription data.

ONS executes a procedure which pseudonymises the patient data at source.
This data is sent to PHE on an encrypted disk.

The procedure is implemented in a Ruby script and uses standard third-party encryption and hashing modules.

For each month's data:

- Generate initial salts
- Create encrypted versions of strings containing NHS number and date of birth ('demographics')
- Generate and encrypt key used to encrypt the demographics
- For each row (item) of prescription data: output a comma-separated row of text


----

Data sizes
----------
- One month's data: ~ 81 million rows in a CSV file.
- Each CSV file is ~ 33Gb.
- The estimated division into PostgreSQL table sizes is:
  - ppatient_rawdata: 7.5Gb
  - ppatients: 10Gb
  - prescription_data: 14Gb


----

Pseudonymisation process
-------------------------
Variables which are read by PHE from the data file and stored in the database are boxed.

- These initial random strings are 64 characters long (= 32 bytes = 256 bits):

  salt1 :math:`\leftarrow` 'abc..'

  salt2 :math:`\leftarrow` 'def..'

- A hashed version of a string derived from the patient's NHS number:

  pseudo_id1 :math:`\leftarrow` SHA2('nhsnumber\_'+NHSNUMBER, salt1)

- A random sequence of 32 bytes is used to create a key for encryption of demographics:

  demog_key  :math:`\leftarrow` random(32 bytes)

- Create Key Encryption Key and encrypt demographics (NHS number and date of birth):

  key_bundle :math:`\leftarrow` base64(AES-256-CBC(SHA256('nhsnumber\_'+NHSNUMBER+salt2), demog_key))

  *Note that* SHA256(NHS number+salt2) *is used as the key to encrypt the demog_key here, and demog_key
  is the data which is encrypted.*

  all_demographics :math:`\leftarrow` '{"nhsnumber":"NHSNUMBER","birthdate":"1970-02-03"}'

  encrypted_demographics :math:`\leftarrow` base64(AES-256-CBC(SHA256(demog_key), all_demographics))

- Output one row per prescription item. CSV format is used. The layout in table 1 shows the mapping process
  (the field names are slightly different in the received form).


Table 1: Source to database mapping
------------------------------------


+--------------+------------+-------------+------------------------+--------------------------+
| CSV field    | pseudo_id1 | key_bundle  | encrypted_demographics | prescription data fields |
+==============+============+=============+========================+==========================+
| Table column | pseudo_id1 | decrypt_key |        rawdata         |     part_month etc.      |
+--------------+------------+-------------+------------------------+--------------------------+
| Table name   | ppatients  |        ppatient_rawdata              |   prescription_data      |
+--------------+------------+--------------------------------------+--------------------------+




----

Table linkage
---------------

.. image:: prescription_tables.png

----

Loading process
----------------

Received CSV file has the current naming scheme:

e.g. PHE_201504_pseudonymised.csv

for year 2015, month 4.

1. Direct load method

  The live PostgreSQL database is called \verb+prescr_lv01+. Login to the server **ncr-prescr-db1** with **ssh** first.

  - For a first-time run, with an empty database - from psql::

    \i defer_constraints.sql

    to delay foreign-key constraint validation until after transaction. This is a one-off,
    as it isn't created by the Rails migration.

  - (also for testing) To clear the prescriptions-related tables (**and** e_batch, ze_type and zprovider)::

    \i truncate_tables.sql

  - A single CSV file (one month's data) is too large to process as a whole on a
    server with 8Gb RAM. This is because the cache created to hold patient_rawdata
    becomes too large as the source data is processed.

    Instead, a workaround is to process each CSV file in two equal parts.

    Rows are selected by the first hex digit of the pseudo_id1 field:

    Part **a**: match first digit of pseudo_id1 in [0-7]

    Part **b**: match first digit of pseudo_id1 in [8-f]

    These hex digits in general will be nearly equally distributed across the source
    CSV file.

    The procedure is now to process each part in turn; create the CSV files then load
    them into the database.

    For a single month, it is critical to load part **a** into the database before creating
    the part **b** files --- to generate the correct patient_id and ppatient_rawdata_id counters.

  - Part **a**

    ::

      # specify year, month and part parameters
      $ ./create_prescr.rb 2015 4 a

    This script creates 4 CSV files for one month's data::

      e_batch_201504a.csv
      ppatients_201504a.csv
      ppatient_rawdata_201504a.csv
      prescription_data_201504a.csv

    Estimated time: Total 1h 10mins.

  - To load the 4 CSV files directly into the database tables::

    \i load_tables_a.sql

    Estimated time: Total 1h 10mins.

  - Part **b**

    ::

      # specify year, month and part parameters
      $ ./create_prescr.rb 2015 4 b

    This script creates 4 CSV files for one month's data::

      e_batch_201504b.csv
      ppatients_201504b.csv
      ppatient_rawdata_201504b.csv
      prescription_data_201504b.csv

    Estimated time: Total 1h 10mins.

  - To load the 4 CSV files directly into the database tables::

    \i load_tables_b.sql

    Estimated time: Total 1h 10mins.

    Note that the part **b** loader does not add another e_batch entry; there is only one
    per month's data.


2. Native Rails method (ActiveRecord)

  For the live database, this can only be run on the app server (**ncr-prescr-app1**) -
  *not* the database server (**ncr-prescr-db1**).

  - In MBIS, run the rake task

    ::

      rails prescription:import_pseudonymised

    Estimated time: 2 days per month's data.



----

Loading into CASREF
--------------------

Loading the prescription data into the CASREF database (Oracle) consists of two steps:

1. Match patients in the prescription database with patients in CASREF - by **pseudo_id1**.
2. Select the matched patients' prescription data and use an Oracle utility (**SQL\*Loader**) to load
   the data into CASREF.

An auxiliary SQL table, **prescription_patientids**, is created by the first step. Its definition is shown in table 2.

Table 2: Matched CASREF patients

===========   ==============================
  Field       Description
===========   ==============================
pseudo_id1    encrypted NHS number
patientid     CASREF ID of matched patient
===========   ==============================

The scheme is to select :math:`\frac{1}{16}` th of the patients by matching only those with **pseudo_id1**
beginning with the hex digit 0.

In this case, the auxiliary table is called **prescription_patientids_prefix0**.
