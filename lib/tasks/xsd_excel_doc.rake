namespace :xsd do
  desc 'Generate schema documentation'
  task generate_schema_documentation: :pick_dataset_version do
    Axlsx::Package.new do |package|
      workbook = package.workbook
      workbook.use_shared_strings = true
      workbook.escape_formulas = false

      columns = [
        'Data Item No.',
        'Data Item Section',
        'Data Item Name',
        'Data Item Description',
        'Format',
        'National Code',
        'National Code Definition',
        'Data Dictionary Element',
        'Other Collections',
        'Schema Specification'
      ]

      workbook.styles do |styles|
        defaults               = { sz: 10, alignment: { vertical: :center, wrap_text: true } }
        border_top_bottom      = {
          border: { style: :thin, color: '000000', edges: %i[top bottom] }
        }
        border_top_bottom_left = {
          border: { style: :thin, color: '000000', edges: %i[top bottom left] }
        }
        text_bold              = { b: true }
        text_large             = { sz: 14 }
        text_white             = { fg_color: 'FFFFFF' }
        background_dark_blue   = { bg_color: '0066CC' }
        background_pale_blue   = { bg_color: '99CCFF' }
        background_cyan        = { bg_color: 'CCFFFF' }
        background_green       = { bg_color: '387F39' }

        style_page_header = styles.add_style(
          defaults.merge(text_large).
            merge(background_dark_blue).
            merge(text_bold).
            merge(text_white)
        )

        style_data_item_header1 = styles.add_style(
          defaults.merge(border_top_bottom_left).
            merge(background_dark_blue).
            merge(text_white).
            merge(alignment: { wrap_text: true, horizontal: :center, vertical: :center })
        )

        style_data_item_header2 = styles.add_style(
          defaults.merge(border_top_bottom_left).
            merge(background_cyan).
            merge(alignment: { wrap_text: true, horizontal: :center, vertical: :center })
        )

        style_entity = styles.add_style(
          defaults.merge(background_pale_blue)
        )

        style_entity_bold = styles.add_style(
          defaults.merge(background_pale_blue).
            merge(text_bold)
        )

        style_entity_bold_end = styles.add_style(
          defaults.merge(background_pale_blue).
            merge(text_bold)
        )

        style_data_item = styles.add_style(
          defaults.merge(border_top_bottom_left).
            merge(alignment: { wrap_text: true, horizontal: :center, vertical: :center })
        )

        style_data_item_bold = styles.add_style(
          defaults.merge(border_top_bottom_left).
            merge(text_bold).
            merge(alignment: { wrap_text: true, horizontal: :center, vertical: :center })
        )

        style_repeating_item = styles.add_style(
          defaults.merge(border_top_bottom).
            merge(background_cyan).
            merge(text_bold)
        )

        style_choice = styles.add_style(
          defaults.merge(border_top_bottom).
            merge(background_green).
            merge(text_bold).
            merge(text_white)
        )

        render_page_header = lambda do |sheet|
          sheet.add_row(Array.new(columns.count), style: style_page_header) do |row|
            row.cells.first.value = "#{@dataset.full_name} - #{sheet.name}"
            sheet.merge_cells(row.cells[0..-1])
          end

          sheet.add_row(Array.new(columns.count), style: style_page_header) do |row|
            row.cells.first.value = "Version #{@dataset_version.semver_version}"
            sheet.merge_cells(row.cells[0..-1])
          end
        end

        render_column_header = lambda do |sheet|
          cell_styles = []
          8.times { cell_styles << style_data_item_header1 }
          2.times { cell_styles << style_data_item_header2 }

          sheet.add_row(columns, style: cell_styles)
        end

        render_node = lambda do |node, default_sheet, section, exit_condition|
          return if exit_condition&.call(node)

          sheet = if node.node_for_category?(nil)
                    default_sheet
                  else
                    category = @dataset_version.categories.detect do |c|
                      node.node_for_category?(c.name)
                    end
                    category ? workbook.sheet_by_name(category.name) : default_sheet
                  end

          if node.is_a? Nodes::Entity
            sheet.add_row(Array.new(columns.count), style: style_entity_bold) do |row|
              cell = row.cells.second
              cell.value = "#{sheet.name} - #{node.name}"
              cell.merge(row.cells.last)
            end

            [node.description, node.excel_occurrence_text].compact.each do |text|
              sheet.add_row(Array.new(columns.count), style: style_entity) do |row|
                cell = row.cells.second
                cell.value = text
                cell.merge(row.cells.last)
              end
            end

            node.child_nodes.find_each do |child_node|
              render_node.call(child_node, default_sheet, node, exit_condition)
            end
            sheet.add_row(Array.new(columns.count), style: style_entity_bold_end) do |row|
              cell = row.cells.second
              cell.value = "#{node.name} END"
              cell.merge(row.cells.last)
            end
          elsif node.is_a? Nodes::DataItem
            if node.max_occurs.blank?
              sheet.add_row(Array.new(columns.count), style: style_repeating_item) do |row|
                cell = row.cells.second
                cell.value = "Start of repeating item - #{node.name}\n" \
                             'Multiple occurences of this item are permitted'
                cell.merge(row.cells.last)
              end
            end

            code_column_index  = columns.index('National Code')
            value_column_index = columns.index('National Code Definition')
            link_column_index  = columns.index('Data Dictionary Element')

            enums = node.xmltype.enumeration_values.for_version(@dataset_version).
                    order(:sort).
                    pluck(:enumeration_value, :annotation)
            rows  = Array.new([1, enums.count].max) { Array.new(columns.count) }

            rows[0] = [
              node.reference,
              section ? "#{sheet.name} - #{section.name}" : nil,
              node.annotation,
              node.description,
              node.xmltype.doc_format,
              nil,
              nil,
              node.annotation,
              nil, # "other collections"
              "#{node.min_occurs}..#{node.max_occurrences}"
            ]

            enums.each_with_index do |(code, value), index|
              row = rows[index]
              row[code_column_index] = code
              row[value_column_index] = value
            end

            cell_styles = Array.new(columns.count) { style_data_item }
            cell_styles[0] = style_data_item_bold
            cell_styles[2] = style_data_item_bold

            rows.map! { |row| sheet.add_row(row, style: cell_styles) }

            if node.data_dictionary_element_link
              sheet.add_hyperlink location: node.data_dictionary_element_link,
                                  ref: rows.first.cells[link_column_index]
            end

            rows.first.cells.each_with_index do |cell, index|
              next if [code_column_index, value_column_index].include?(index)

              cell.merge(rows.last.cells[index])
            end

            if node.max_occurs.blank?
              sheet.add_row(Array.new(columns.count), style: style_repeating_item) do |row|
                cell = row.cells.second
                cell.value = "End of repeating item - #{node.name}"
                cell.merge(row.cells.last)
              end
            end
          elsif node.is_a?(Nodes::Choice)
            # Probably not a sustainable solution long term...
            return if node.name == 'TreatmentChoice'

            sheet.add_row(Array.new(columns.count), style: style_choice) do |row|
              cell = row.cells.second
              cell.value = 'Choice start'
              cell.merge(row.cells.last)
            end

            node.child_nodes.find_each do |child_node|
              render_node.call(child_node, default_sheet, section, exit_condition)

              sheet.add_row(Array.new(columns.count), style: style_choice) do |row|
                cell = row.cells.second
                cell.value = node.choice_type.name
                cell.merge(row.cells.last)
              end
            end
            sheet.rows.delete_at(sheet.rows.size - 1)

            sheet.add_row(Array.new(columns.count), style: style_choice) do |row|
              cell = row.cells.second
              cell.value = 'Choice end'
              cell.merge(row.cells.last)
            end
          else
            node.child_nodes.find_each do |child_node|
              render_node.call(child_node, default_sheet, section, exit_condition)
            end
          end
        end

        head = @dataset_version.nodes.find_by(parent_id: nil)
        root = @dataset_version.entities.find_by(name: 'Record')

        header_sheet = workbook.add_worksheet(name: 'XML Header') do |sheet|
          render_page_header.call(sheet)
          sheet.add_row([])
          render_column_header.call(sheet)
        end

        core_sheet = workbook.add_worksheet(name: 'Core') do |sheet|
          render_page_header.call(sheet)
          sheet.add_row([])
          render_column_header.call(sheet)
        end

        @dataset_version.categories.order(:name).each do |category|
          workbook.add_worksheet(name: category.name) do |sheet|
            render_page_header.call(sheet)
            sheet.add_row([])
            render_column_header.call(sheet)
          end
        end

        render_node.call head, header_sheet, nil, ->(node) { node.name == root.name }
        render_node.call root, core_sheet, nil, nil
      end

      workbook.worksheets.each do |sheet|
        sheet.column_widths(15, 20, 30, 40, 15, 15, 30, 30, 15, 25)
      end

      # TODO: parameterize output path
      filename = "#{@dataset.name.downcase}_dataset_v#{@dataset_version.semver_version}.xlsx"
      package.serialize(Rails.root.join('tmp', filename))
    end
  end

  task :initialize_highline do
    require 'highline'

    @cli = HighLine.new
  end

  task pick_dataset: %i[environment initialize_highline] do
    @dataset = @cli.choose do |menu|
      menu.header = 'Please choose a dataset'
      Dataset.find_each do |dataset|
        menu.choice(dataset.name) { dataset }
      end
    end
  end

  task pick_dataset_version: :pick_dataset do
    @dataset_version = @cli.choose do |menu|
      menu.header = 'Please choose a dataset version'
      @dataset.dataset_versions.each do |dataset_version|
        menu.choice(dataset_version.semver_version) { dataset_version }
      end
    end
  end
end
