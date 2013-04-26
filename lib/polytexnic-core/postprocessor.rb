# encoding=utf-8
require 'cgi'

module Polytexnic
  module Postprocessor

    def postprocess
      xml_to_html
    end

    def xml_to_html
      @html = Nokogiri::HTML.fragment(processed_xml).to_html
    end

    def processed_xml
      doc = Nokogiri::XML(@xml)
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
      # Code
      doc.xpath('//code').each do |node|
        node.name = 'div'
        node['class'] = 'code'
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

      # (La)TeX logos
      doc.xpath('//TeX').each do |node|
        node.name = 'span'
        node['class'] = 'TeX'
        node.content = '\( \mathrm{\TeX} \)'
      end
      doc.xpath('//LaTeX').each do |node|
        node.name = 'span'
        node['class'] = 'LaTeX'
        node.content = '\( \mathrm{\LaTeX} \)'
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
        node.name = 'div'
        node['class'] = node['type'] == 'chapter' ? 'chapter' : 'section'
        clean_node node, %w{id-text type}

        node.xpath('.//head').each do |head_node|
          head_node.name = 'h2'
        end
      end

      # subsection
      doc.xpath('//div1').each do |node|
        node.name = 'div'
        node['class'] = 'subsection'
        clean_node node, %w{id-text}

        node.xpath('.//h2').each do |head_node|
          head_node.name = 'h3'
        end
      end

      # chapter
      doc.xpath('//chapter').each do |node|
        node.name = 'h1'
        node['class'] = 'chapter'
      end

      doc.xpath('//error').map(&:remove)

      # set data-tralics-id
      doc.xpath('//*[@id]').each do |node|
        # TODO: make whitelist of non-tralics id's
        next if node['id'] =~ /footnote/

        node['data-tralics-id'] = node['id']
        node['id'] = node['data-label'].gsub(/:/, '-') if node['data-label']

        clean_node node, %w{data-label}
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

      # restore literal environments
      doc.xpath('//literal').each do |node|
        node.parent.content = escape_backslashes(literal_cache[node.content])
        node.remove
      end
      # (including non-ASCII unicode)
      doc.xpath('//unicode').each do |node|
        node.content = literal_cache[node.content]
        node.name = 'span'
        node['class'] = 'unicode'
      end

      # build numbering tree
      chapter_number = 0
      section_number = 0
      subsection_number = 0
      doc.xpath('//*[@data-tralics-id]').each do |node|
        node['data-number'] = case node['class'].to_s
          when 'chapter'
            section_number = 0
            "#{chapter_number += 1}"
          when 'section'
            subsection_number = 0
            "#{chapter_number}.#{section_number += 1}"
          when 'subsection'
            "#{chapter_number}.#{section_number += 1}.#{subsection_number += 1}"
          end

        el = Nokogiri::XML::Node.new('span', doc)
        el.content = node['data-number']
        el['class'] = 'number'
        if head = node.css('h2, h3').first
          head.children.first.add_previous_sibling el
        end
      end

      doc.xpath('//ref').each do |node|
        target = doc.xpath("//*[@data-tralics-id='#{node['target']}']").first
        node.name = 'a'
        node['href'] = "##{target['id'].gsub(/:/, '-')}"
        node['class'] = 'ref'
        node.content = target['data-number']
        clean_node node, 'target'
      end

      html = doc.at_css('document').children.to_html

      # highlight source code
      # We need to put it after the call to 'to_html' because otherwise
      # Nokogiri escapes it.
      html.tap do
        code_cache.each do |key, (content, language)|
          html.gsub!(key, Pygments.highlight(content, lexer: language))
        end
      end
    end

    def clean_node(node, attributes)
      [*attributes].each { |a| node.remove_attribute a }
    end
  end
end