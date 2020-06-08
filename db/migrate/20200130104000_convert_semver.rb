class ConvertSemver < ActiveRecord::Migration[6.0]
  def change
    DatasetVersion.all.each do |dv|
      dv.update_attribute(:semver_version, dv.semver_version.gsub('-', '.'))
    end
  end
end
