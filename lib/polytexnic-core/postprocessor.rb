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

    # Handles output of \emph{} and \textit{}.
    def emphasis(doc)
      doc.xpath('//hi[@rend="it"]').each do |node|
        node.name = 'em'
        node.remove_attribute('rend')
      end
    end

    # Handles output of \texttt{}.
    def typewriter(doc)
      doc.xpath('//hi[@rend="tt"]').each do |node|
        node.name = 'span'
        node['class'] = 'tt'
        node.remove_attribute('rend')
      end
    end

    # Handles verbatim and Verbatim environments.
    # \begin{verbatim}
    # <stuff>
    # \end{verbatim}
    # and
    # \begin{Verbatim}
    # <stuff>
    # \end{Verbatim}
    # Note that verbatim is a built-in LaTeX environment, whereas
    # Verbatim is loaded by the Verbatim package (and used by the
    # code environment).
    def verbatim(doc)
      doc.xpath('//verbatim').each do |node|
        node.name = 'pre'
        node['class'] = 'verbatim'
      end
      doc.xpath('//Verbatim').each do |node|
        node.name = 'pre'
        node['class'] = 'verbatim'
      end      
    end

    # Handles code environments.
    # \begin{code}
    # <code>
    # \end{code}
    def code(doc)
      doc.xpath('//code').each do |node|
        node.name = 'div'
        node['class'] = 'code'
      end      
    end

    # Handles math environments.
    # Included are 
    # \begin{equation}
    # <equation>
    # \end{equation}
    # and all the AMSTeX variants defined in Preprocessor#math_environments.
    # We also handle inline/display math of the form \(x\) and \[y\].
    def math(doc)
      # math environments
      doc.xpath('//equation').each do |node|
        node.name = 'div'
        node['class'] = 'equation'
        # Mimic default Tralics behavior of giving paragraph tags after
        # math a 'noindent' class. This allows the HTML to be styled with CSS
        # in a way that replicates the default behavior of LaTeX, where
        # math can be included in a paragraph. In such a case, paragraphs
        # are indented by default, but text after math environments isn't
        # indented. In HTML, including a math div inside a p tag is illegal,
        # so the next best thing is to add a 'noindent' class to the p tag
        # following the math. Most documents won't use this, as the HTML
        # convention is not to indent paragraphs anyway, but we want to 
        # support that use case for completeness (mainly because Tralics does).
        begin
          next_paragraph = node.parent.next_sibling.next_sibling
          next_paragraph['noindent'] = 'true'
        rescue
          # We rescue nil in case the math isn't followed by any text.
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
    end

    def processed_xml
      doc = Nokogiri::XML(@xml)
      emphasis(doc)
      typewriter(doc)
      verbatim(doc)
      code(doc)
      math(doc)

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

      doc.xpath('//error').map(&:remove)

      # set data-tralics-id
      doc.xpath('//*[@id]').each do |node|
        # TODO: make whitelist of non-tralics id's
        next if node['id'] =~ /footnote/

        node['data-tralics-id'] = node['id']
        node['id'] = node['data-label'].gsub(/:/, '-') if node['data-label']

        clean_node node, %w{data-label}
      end

      # chapter/section
      doc.xpath('//div0').each do |node|
        node.name = 'div'
        is_chapter = node['type'] == 'chapter'
        node['class'] = is_chapter ? 'chapter' : 'section'
        clean_node node, %w{id-text type}

        node.xpath('.//head').each do |head_node|
          head_node.name = 'h3'
          a = doc.create_element 'a'
          a['href'] = "##{node['id']}"
          a['class'] = 'heading'
          a << head_node.children
          head_node << a
        end
      end

      # subsection
      doc.xpath('//div1').each do |node|
        node.name = 'div'
        node['class'] = 'subsection'
        clean_node node, %w{id-text}

        node.xpath('.//head').each do |head_node|
          head_node.name = 'h4'
          a = doc.create_element 'a'
          a['href'] = "##{node['id']}"
          a['class'] = 'heading'
          a << head_node.children
          head_node << a
        end
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
            cha_n = chapter_number == 0 ? 1 : chapter_number
            "#{cha_n}.#{section_number += 1}"
          when 'subsection'
            cha_n = chapter_number == 0 ? 1 : chapter_number
            sec_n = section_number == 0 ? 1 : section_number
            "#{cha_n}.#{sec_n}.#{subsection_number += 1}"
          end

        # add number span
        if head = node.css('h2 a, h3 a').first
          el = doc.create_element 'span'
          el.content = node['data-number']
          el['class'] = 'number'
          head.children.first.add_previous_sibling el
        end
      end

      doc.xpath('//ref').each do |node|
        target = doc.xpath("//*[@data-tralics-id='#{node['target']}']").first
        node.name = 'span'
        node['class'] = 'ref'
        node.content = target['data-number']
        clean_node node, 'target'
      end

      doc.xpath('//*[@target]').each do |node|
        node['href'] = "##{node['target'].gsub(/:/, '-')}"
        node['class'] = 'hyperref'
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

    # Cleans a node by removing all the given attributes.
    def clean_node(node, attributes)
      [*attributes].each { |a| node.remove_attribute a }
    end

    def find_by_label(doc, label)
    end
  end
end