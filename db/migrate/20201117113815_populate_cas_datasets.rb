class PopulateCasDatasets < ActiveRecord::Migration[6.0]
  def up
    names.each do |name|
      Dataset.create!(dataset_type_id: DatasetType.fetch(:cas).id, team_id: cas_team.id,
                      name: name, full_name: name)
    end
  end

  def down
    Dataset.cas.destroy_all
    cas_team.destroy
  end

  def cas_team
    @team ||=
      Team.find_or_create_by(name: 'CAS Applications',
                             organisation_id: Organisation.find_by(name: 'Public Health England').id,
                             z_team_status_id: ZTeamStatus.find_by(name: 'Active').id)
  end

  def names
    [
      "ONS incidence tables (all available)Schema: ONS1971_1994, 1989, 2010, 2011, 2012, 2013, 2014 ONS short declaration form completed.",
      "*ONS mortality tables (all available)Schema: ONS2011, 2012, 2013, 2014 etc..",
      "Cancer Waiting Times referrals",
      "Cancer Waiting Times Legacy data",
      "Anonymised Patient Reported Outcomes Measures(bowel,bladder, pilot 2011 and 2012)Schema: PROMS",
      "Patient Reported Outcomes Measures(bowel, bladder, pilot 2011,2012)Schema: PROMS",
      "Patient Reported Outcomes Measures(Gynaecological cancers)Schema: PROMS",
      "Biobank indicator",
      "Prescriptions sample Schema: PRESCRIPTIONSAMPLE, PRESCRIPTION2015",
      "Mosaic etc... Schema: Mosaic2017, Mosaic2018 etc."
    ]
  end
end
