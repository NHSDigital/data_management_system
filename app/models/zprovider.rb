# load Zprovider model from ndr_workflow gem first
require NdrWorkflow::Engine.root.join('app', 'models', 'zprovider')

class Zprovider
  has_many :pseudonymisationkeys
end
