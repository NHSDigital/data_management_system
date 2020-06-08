# This mixin provides a reversible helper method to add records to lookups
module MigrationHelper
  def add_lookup(klass, primary_key, attributes)
    reversible do |dir|
      dir.up do
        klass.create(attributes) { |z| z.id = primary_key }
      end
      dir.down do
        klass.delete(primary_key)
      end
    end
  end

  def remove_lookup(klass, primary_key, attributes)
    revert { add_lookup(klass, primary_key, attributes) }
  end

  def change_lookup(klass, primary_key, old_attributes, new_attributes)
    reversible do |dir|
      dir.up do
        lookup = klass.where(old_attributes).find(primary_key)
        lookup.update!(new_attributes)
      end
      dir.down do
        lookup = klass.where(new_attributes).find(primary_key)
        lookup.update!(old_attributes)
      end
    end
  end
end
