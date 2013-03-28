# encoding=utf-8
require 'cgi'

module Polytexnic
  module Postprocessor

    def postprocess
      xml_to_html
    end

    def xml_to_html
      html  = process_xml(postprocess_xml)
      @html = Nokogiri::HTML.fragment(html).to_html
    end

    def postprocess_xml
      @xml.tap do 
        @verbatim_cache.each do |key, value|
          @xml.gsub!(key, CGI.escapeHTML(escape_backslashes(value)))
        end
      end
    end

    # Escapes backslashes when restoring verbatim elements.
    def escape_backslashes(string)
      string.gsub('\\', '\\\\\\\\')
    end


    def process_xml(xml)
      doc = Nokogiri::XML(xml)
      # clean
      doc.xpath('//comment()').remove

      # Italics/emphasis
      doc.xpath('//hi[@rend="it"]').each do |node|
        node.name = 'em'
        node.remove_attribute('rend')
      end
      doc.xpath('//hi[@rend="tt"]').each do |node|
        node.name = 'span'
        node['class'] = 'tt'
        node.remove_attribute('rend')
      end
      # verbatim
      doc.xpath('//verbatim').each do |node|
        node.name = 'pre'
        node['class'] = 'verbatim'
      end
      # Verbatim
      doc.xpath('//Verbatim').each do |node|
        node.name = 'pre'
        node['class'] = 'verbatim'
      end
      # equation
      doc.xpath('//equation').each do |node|
        node.name = 'div'
        node['class'] = 'equation'
        begin
          next_paragraph = node.parent.next_sibling.next_sibling
          next_paragraph['noindent'] = 'true'
        rescue
          nil
        end
      end
      # inline & display math
      doc.xpath('//texmath').each do |node|
        type = node.attributes['textype'].value
        if type == 'inline'
          node.name = 'span'
          node.content = '\\(' + node.content + '\\)'
          node['class'] = 'inline_math'
        else
          node.name = 'div'
          node.content = '\\[' + node.content + '\\]'
          node['class'] = 'display_math'
        end
        node.remove_attribute('textype')
        node.remove_attribute('type')
      end
      # Paragraphs with noindent
      doc.xpath('//p[@noindent="true"]').each do |node|
        node['class'] = 'noindent'
        node.remove_attribute('noindent')
      end

      # handle footnotes
      footnotes_node = nil
      doc.xpath('//note[@place="foot"]').each_with_index do |node, i|
        n = i + 1
        note = Nokogiri::XML::Node.new('li', doc)
        note['id'] = "footnote-#{n}"
        note.content = node.content

        unless footnotes_node
          footnotes_wrapper_node = Nokogiri::XML::Node.new('div', doc)
          footnotes_wrapper_node['id'] = 'footnotes'
          footnotes_node = Nokogiri::XML::Node.new('ol', doc)
          footnotes_wrapper_node.add_child footnotes_node
          doc.root.add_child footnotes_wrapper_node
        end

        footnotes_node.add_child note

        node.name = 'sup'
        clean_node node, %w{place id id-text}
        node['class'] = 'footnote'
        link = Nokogiri::XML::Node.new('a', doc)
        link['href'] = "#footnote-#{n}"
        link.content = n.to_s
        node.inner_html = link
      end

      # LaTeX logo
      doc.xpath('//LaTeX').each do |node|
        node.name = 'span'
        node['class'] = 'LaTeX'
      end

      # standard environments

      # quote
      doc.xpath('//p[@rend="quoted"]').each do |node|
        clean_node node, 'rend'
        node.name = 'blockquote'
        node['class'] = 'quote'
      end

      # verse
      doc.xpath('//p[@rend="verse"]').each do |node|
        clean_node node, %w{rend noindent}
        node.name = 'blockquote'
        node['class'] = 'verse'
      end

      # itemize
      doc.xpath('//list[@type="simple"]').each do |node|
        clean_node node, 'type'
        node.name = 'ul'
      end

      # enumerate
      doc.xpath('//list[@type="ordered"]').each do |node|
        clean_node node, 'type'
        node.name = 'ol'
      end

      # item
      doc.xpath('//item').each do |node|
        clean_node node, %w{id-text id label}
        node.name = 'li'
        node.xpath('//p').each do |pnode|
          pnode.parent.inner_html = pnode.inner_html
        end
      end

      # section
      doc.xpath('//div0').each do |node|
        id = node['id']
        clean_node node, %w{id id-text}
        node.name = 'div'
        node['class'] = 'section'

        node.xpath('//head').each do |head_node|
          head_node.name = 'h2'
        end
      end

      # chapter
      doc.xpath('//chapter').each_with_index do |node, i|
        n = i + 1

        node.name = 'h1'
        node['class'] = 'chapter'

        a = Nokogiri::XML::Node.new('a', doc)
        a['id'] = "sec-#{n}"

        span = Nokogiri::XML::Node.new('span', doc)
        span.content = node.content

        node.content = ''
        node << a
        node << span
      end

      # title (preprocessed)
      doc.xpath('//maketitle').each do |node|
        node.name = 'h1'
        %w{title subtitle author date}.each do |field|
          class_var = Polytexnic.instance_variable_get "@#{field}"
          if class_var
            type = %w{title subtitle}.include?(field) ? 'h1' : 'h2'
            el = Nokogiri::XML::Node.new(type, doc)
            el.content = class_var
            el['class'] = field
            node.add_child el
          end
        end
      end

      doc.at_css('document').children.to_html
    end

    def clean_node(node, attributes)
      [*attributes].each { |a| node.remove_attribute a }
    end

  end
end