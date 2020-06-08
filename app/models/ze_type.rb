# load ZeType model from ndr_workflow gem first
require NdrWorkflow::Engine.root.join('app', 'models', 'ze_type')

class ZeType
  has_many :pseudonymisationkeys
end
