# encoding=utf-8
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
          @xml.gsub!(key, value)
        end
      end
    end

    def process_xml(xml)
      doc = Nokogiri::XML(xml)
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
        note = Nokogiri::XML::Node.new('div', doc)
        note['id'] = "footnote-#{n}"
        note['class'] = 'footnote'
        note.content = node.content

        unless footnotes_node
          footnotes_node = Nokogiri::XML::Node.new('div', doc)
          footnotes_node['id'] = 'footnotes'
          doc.root.add_child footnotes_node
        end

        footnotes_node.add_child note

        node.name = 'sup'
        %w{id-text id place}.each { |a| node.remove_attribute a }
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

      doc.at_css('unknown').children.to_html
    end

  end
end