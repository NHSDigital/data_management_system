# This migration comes from ndr_error (originally 20180203174345)
# Adds supplementary column to error fingerprint
class AddCauseToErrorFingerprints < NdrError.migration_class
  def change
    add_column :error_fingerprints, :causal_error_fingerprintid, :string

    add_foreign_key :error_fingerprints, :error_fingerprints,
                    column:      :causal_error_fingerprintid,
                    primary_key: :error_fingerprintid

    add_index :error_fingerprints, :causal_error_fingerprintid
  end
end
