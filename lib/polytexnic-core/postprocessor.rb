module Polytexnic
  module Postprocessor

    def postprocess
      xml_to_html
    end

    def xml_to_html
      html = process_xml(postprocess_xml)
      @html = Nokogiri::HTML(html).to_html
    end

    def postprocess_xml
      xml = @xml
      @verbatim_cache.each do |key, value|
        xml.gsub!(key, value)
      end

      xml
    end

    def process_xml(xml)
      doc = Nokogiri::XML(xml)
      doc.xpath('//hi[@rend="it"]').each do |node|
        node.name = 'em'
        node.xpath('//@rend').remove
      end
      doc.xpath('//verbatim').each do |node|
        node.name = 'pre'
        node['class'] = 'verbatim'
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

      doc.to_html
    end

  end
end