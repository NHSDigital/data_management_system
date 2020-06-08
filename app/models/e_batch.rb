# load EBatch model from ndr_workflow gem first
require NdrWorkflow::Engine.root.join('app', 'models', 'e_batch')

# A batch of imported data, e.g. a month of prescription data, or a death file
class EBatch
  has_many :ppatients, class_name: 'Pseudo::Ppatient'
  scope :imported, -> { where('digest is not null') }

  def destroy
    ppatientids = Pseudo::Ppatient.where(e_batch_id: id).pluck(:id)
    ppatientids.each_slice(999) do |id_chunk|
      Pseudo::Ppatient.transaction do
        Pseudo::Ppatient.where(id: id_chunk).delete_all
      end
    end
    result = super # Destroy the e_batch
    # Remove any orphaned PpatientRawdata records
    # ... assuming that PpatientRawdata and Ppatient are only ever committed atomically.
    Pseudo::PpatientRawdata.joins('left join ppatients on ppatients.ppatient_rawdata_id = ' \
                                  'ppatient_rawdata.ppatient_rawdataid').
      where(ppatients: { ppatient_rawdata_id: nil }).delete_all if ppatientids.present?
    result
  end
end
