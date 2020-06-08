# Wraps CanCan functionality to load resources via a polymorphic parent.
# See CanCan wiki article on nested resources for more.
module PolymorphicAuthorizable
  extend ActiveSupport::Concern

  included do
    def parent_resource_name
      params[:resource_type].singularize
    end

    def parent_resource_class
      parent_resource_name.classify.constantize
    end

    def parent_resource
      variable_name = "@#{parent_resource_class.model_name.element}"

      @parent = instance_variable_get(variable_name) ||
        instance_variable_set(variable_name, parent_resource_class.find(params[:resource_id]))
    end
  end

  class_methods do
    # Loads and authorizes a resource via an associated polymorphic relation.
    # Note that authorization takes place on the parent, not the current resource.
    def polymorphic_load_and_authorize_resource(resource_name, **options)
      options[:through] = :parent_resource

      authorize_polymorphic_resource
      load_resource(resource_name, options)
      _make_collection_accessible(resource_name)
    end

    # Authorizes the polymorphic parent resource. Takes the stance that if a user is authorized
    # to :read the parent then, by extension, they should also be able to view the children.
    def authorize_polymorphic_resource
      before_action do
        authorize! :read, parent_resource
      end
    end

    # Because we're authorizing via the parent we have no rules defined in the ability file.
    # Collection routes are handled via Model.accessible_by(ability) which will generate a SQL
    # predicate that always equates to false in this situation. Typically, we would have a :can
    # rule with a hash of conditions, but that wont work here because the 'parent' resource is
    # not available within the ability. To work around this, we extract the predicates used for
    # the parent binding (i.e. from loading :though another resource) and use these to create a
    # new WHERE clause, sans 't' = 'f'.
    # For more info see:
    # CanCan::ModelAdditions (:accessible_by)
    # CanCan::ModelAdapters::ActiveRecordAdapter (:database_records, :conditions, :false_sql)
    def _make_collection_accessible(resource_name)
      variable_name = "@#{resource_name.to_s.pluralize}"

      before_action only: [:index, :index_new] do
        relation = instance_variable_get(variable_name)
        conditions = relation.where_values_hash
        relation = relation.unscope(:where).where(conditions)
        instance_variable_set(variable_name, relation)
      end
    end
  end
end
