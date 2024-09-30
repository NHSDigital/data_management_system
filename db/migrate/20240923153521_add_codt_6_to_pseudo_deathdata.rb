# Add column codt_6 to deathdata table
# New field for cause of death line 1(d)
# Previously we had:
# CODT_1 = 1a/a
# CODT_2 = 1b/b
# CODT_3 = 1c/c
# CODT_4 = II/d
# CODT_5 = II/e
# now we have:
# CODT_1 = 1a/a
# CODT_2 = 1b/b
# CODT_3 = 1c/c
# CODT_6 = 1d/d
# CODT_4 = II/d
# CODT_5 = II/e
# Change from 2024-09-09: New field for cause of death  line 1(d) on non-neonatal deaths
# CODT_6 = 1d/f
# In the registration it is positioned between CODT_3 and CODT_4
#
# "From April 2024 a new MCCD [Medical certificate of cause of death] will
# replace the existing one to reflect the introduction of medical examiners and
# bring the new MCCD in line with international standards. These changes will
# impact how certifying doctors, medical examiners and coroners capture cause
# of death information on MCCDs/Coroner forms."
class AddCodt6ToPseudoDeathdata < ActiveRecord::Migration[6.1]
  def change
    add_column :death_data, :codt_6, :string
  end
end
