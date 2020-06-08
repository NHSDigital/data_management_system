# Abstract superclass for service objects.
# Subclass should implement `initialize(**kwargs, &block)` and `call` methods.
class ApplicationService
  def self.call(**kwargs, &block)
    new(**kwargs, &block).call
  end
end
