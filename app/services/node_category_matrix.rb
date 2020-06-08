# Parses the params submitted by the checkbox matrix of node_categories
class NodeCategoryMatrix
  def initialize(params)
    @params = params
  end

  def call
    node_category_params.tap { |hash| clean_up!(hash) }
  end

  private

  def node_category_params
    @params.require(:node_categories).permit!.to_h
  end

  def clean_up!(hash)
    clean_node_categories!(hash)

    hash
  end

  def clean_node_categories!(hash)
    hash.transform_values!(&:present?)
  end
end
