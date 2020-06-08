module SchemaBrowser
  # utility methods
  module Utility
    def tag(name, options = {}, &block)
      if options.present?
        attrs = options.each_with_object(' ') do |(k, v), r|
          option = k.to_s + '=' + '"' + v.to_s + '" '
          option.rstrip! if k == options.keys.last
          r << option
        end
      end
      @html << "#{indent}<#{name}#{attrs}>\n"

      @depth += 1
      block.call if block_given?

      @depth -= 1
      @html << "#{indent}</#{name}>\n"
    end

    def head_common
      tag(:head) do
        tag(:title) do
          content(dataset.full_name)
        end
        templates
      end
    end

    def body_common(&block)
      tag(:body) do
        tag(:div, id: 'wrap') do
          block.call if block_given?
        end
        footer_common
        scripts
      end
    end

    def body_container_common(&block)
      tag(:div, class: 'container') do
        tag(:div, class: 'row') do
          tag(:div, class: 'span8') do
            tag(:h3, class: 'pack-title text-right') do
              content(dataset.full_name)
            end
          end
        end
        block.call if block_given?
      end
    end

    def navbar
      tag(:div, class: 'navbar') do
        tag(:div, class: 'navbar-inner') do
          tag(:div, class: 'container') do
            tag(:div, class: 'nav-collapse collapse') do
              tag(:p, class: 'navbar-text pull-right') do
                tag(:b) do
                  content('Version: ')
                end
                content(version.schema_version_format)
              end
              tag(:ul, class: 'nav') do
                main_menu
                dataset_categories
                xmltypes
              end
            end
          end
        end
      end
    end

    def main_menu
      tag(:li, class: 'dropdown') do
        tag(:a, href: '#', class: 'dropdown-toggle', 'data-toggle' => 'dropdown') do
          content('Overview')
          tag(:b, class: 'caret')
        end
        tag(:ul, class: 'dropdown-menu') do
          tag(:li) do
            tag(:a, href: "#{path}/index.html") do
              content('About')
            end
          end
          tag(:li) do
            tag(:a, href: "#{path}/ChangeLog.html") do
              content('Change Log')
            end
          end
        end
      end
    end

    def dataset_categories
      core_cat = version.core_category.name
      tag(:li, class: 'dropdown') do
        tag(:a, href: '#', class: 'dropdown-toggle', 'data-toggle' => 'dropdown') do
          content('Categories')
          tag(:b, class: 'caret')
          tag(:ul, class: 'dropdown-menu') do
            parent_model
            cats = version_categories.pluck(:name)
            cats.unshift(core_cat)
            cats.each do |category|
              tag(:li) do
                tag(:a, href: "#{path}/Categories/#{category}.html") do
                  category == core_cat ? content(category + ' (Core)') : content(category)
                end
              end
            end
          end
        end
      end
    end

    def parent_model
      tag(:li) do
        tag(:a, href: "#{path}/Tabular/#{dataset.name}.html") do
          content("#{dataset.name} (Parent Model)")
        end
      end
    end

    def xmltypes
      tag(:li) do
        tag(:a, href: "#{path}/DataTypes.html") do
          content('Data Types')
        end
      end
    end

    def about
      tag(:div, id: 'content', class: 'row') do
        tag(:div, class: 'span12') do
          tag(:h3) do
            content('About')
          end
          content(dataset.description)
        end
      end
      tag(:div, id: 'push')
    end

    def footer_common
      tag(:div, id: 'footer') do
        tag(:div, class: 'container') do
          tag(:div, class: 'row') do
            contact_us
            release_date
          end
        end
      end
    end

    def contact_us
      tag(:div, class: 'span6') do
        tag(:p, class: 'text-left') do
          tag(:a, href: 'COSD@phe.gov.uk ') do
            content('Contact Us')
          end
        end
      end
    end

    def release_date
      tag(:div, class: 'span6') do
        tag(:p, class: 'text-right') do
          tag(:b) do
            content('Release Date: ')
          end
          content(Date.current.strftime('%Y/%m/%d'))
        end
      end
    end

    def content(content)
      @depth += 1
      @html << indent + content.to_s + "\n"
      @depth -= 1
    end

    def templates
      @html << indent + '<meta name="viewport" content="width=device-width, initial-scale=1.0"/>'
      new_line
      @html << indent + '<link href="' + path +
               '/Template/css/bootstrap/bootstrap.min.css" rel="stylesheet" media="screen"/>'
      new_line
      @html << indent + '<link href="' + path +
               '/Template/css/base.css" rel="stylesheet" media="screen"/>'
      new_line
      @html << indent + '<link href="' + path +
               '/Template/css/google-code-prettify/prettify.css" rel="stylesheet" media="screen"/>'
      new_line
    end

    def scripts
      @html << indent + '<script src="' + path +
               '/Template/js/jquery/jquery-1.8.3.js"> </script>'
      new_line
      @html << indent + '<script src="' + path +
               '/Template/js/bootstrap/bootstrap.min.js"> </script>'
      new_line
      @html << indent + '<script src="' + path +
               '/Template/js/google-code-prettify/prettify.js"> </script>'
      new_line
      @html << indent + '<script>!function ($){$(function(){window.prettyPrint ' \
               '&& prettyPrint()})}(window.jQuery)</script>'
      new_line
    end

    def path
      @index ? '.' : '..'
    end

    def new_line
      @html << "\n"
    end

    def version_categories
      (version.categories - [version.core_category]).sort_by(&:sort)
    end
  end
end
