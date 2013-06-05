module Polytexnic
  module Postprocessor
    module Html

      # Converts Tralics XML output to HTML.
      def xml_to_html(xml)
        doc = Nokogiri::XML(xml)
        emphasis(doc)
        boldface(doc)
        small_caps(doc)
        typewriter(doc)
        verbatim(doc)
        code(doc)
        math(doc)
        footnotes(doc)
        tex_logos(doc)
        quote(doc)
        verse(doc)
        itemize(doc)
        enumerate(doc)
        item(doc)
        remove_errors(doc)
        set_ids(doc)
        chapters_and_section(doc)
        subsection(doc)
        title(doc)
        smart_single_quotes(doc)
        restore_literal(doc)
        make_cross_references(doc)
        hrefs(doc)
        graphics_and_figures(doc)
        html = convert_to_html(doc)
        quote_and_verse(html)
      end

      private

        # Handles output of \emph{} and \textit{}.
        def emphasis(doc)
          doc.xpath('//hi[@rend="it"]').each do |node|
            node.name = 'em'
            node.remove_attribute('rend')
          end
        end

        # Handles output of \textbf{}.
        def boldface(doc)
          doc.xpath('//hi[@rend="bold"]').each do |node|
            node.name = 'strong'
            node.remove_attribute('rend')
          end
        end

        # Handles output of \textsc{}.
        def small_caps(doc)
          doc.xpath('//hi[@rend="sc"]').each do |node|
            node.name = 'span'
            node['class'] = 'sc'
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
            # math a 'noindent' class. This allows the HTML to be styled with
            # CSS in a way that replicates the default behavior of LaTeX, where
            # math can be included in a paragraph. In such a case, paragraphs
            # are indented by default, but text after math environments isn't
            # indented. In HTML, including a math div inside a p tag is illegal,
            # so the next best thing is to add a 'noindent' class to the p tag
            # following the math. Most documents won't use this, as the HTML
            # convention is not to indent paragraphs anyway, but we want to
            # support that case for completeness (mainly because Tralics does).
            begin
              next_paragraph = node.parent.next_sibling.next_sibling
              next_paragraph['noindent'] = 'true'
            rescue
              # We rescue nil in case the math isn't followed by any text.
              nil
            end
          end

          # Paragraphs with noindent
          # See the long comment above.
          doc.xpath('//p[@noindent="true"]').each do |node|
            node['class'] = 'noindent'
            node.remove_attribute('noindent')
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

        # Handles footnotes.
        def footnotes(doc)
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
        end

        # Returns HTML for a nicely styled TeX logo.
        def tex
          %(<span class="texhtml" style="font-family: 'CMU Serif', cmr10, LMRoman10-Regular, 'Times New Roman', 'Nimbus Roman No9 L', Times, serif;">T<span style="text-transform: uppercase; vertical-align: -0.5ex; margin-left: -0.1667em; margin-right: -0.125em;">E</span>X</span>)
        end

        # Returns HTML for a nicely styled LaTeX logo.
        def latex
          %(<span class="texhtml" style="font-family: 'CMU Serif', cmr10, LMRoman10-Regular, 'Times New Roman', 'Nimbus Roman No9 L', Times, serif;">L<span style="text-transform: uppercase; font-size: 70%; margin-left: -0.36em; vertical-align: 0.3em; line-height: 0; margin-right: -0.15em;">A</span>T<span style="text-transform: uppercase; margin-left: -0.1667em; vertical-align: -0.5ex; line-height: 0; margin-right: -0.125em;">E</span>X</span>)
        end

        # Handles logos for TeX and LaTeX.
        def tex_logos(doc)
          doc.xpath('//TeX').each do |node|
            node.replace(Nokogiri::XML::fragment(tex))
          end
          doc.xpath('//LaTeX').each do |node|
            node.replace(Nokogiri::XML::fragment(latex))
          end
        end

        def quote(doc)
          doc.xpath('//p[@rend="quoted"]').each do |node|
            clean_node node, 'rend'
            node.name = 'blockquote'
            node['class'] = 'quote'
          end
        end

        def verse(doc)
          doc.xpath('//p[@rend="verse"]').each do |node|
            clean_node node, %w{rend noindent}
            node.name = 'blockquote'
            node['class'] = 'verse'
          end
        end

        def itemize(doc)
          doc.xpath('//list[@type="simple"]').each do |node|
            clean_node node, 'type'
            node.name = 'ul'
          end
        end

        def enumerate(doc)
          doc.xpath('//list[@type="ordered"]').each do |node|
            clean_node node, 'type'
            node.name = 'ol'
          end
        end

        def item(doc)
          doc.xpath('//item').each do |node|
            clean_node node, %w{id-text id label}
            node.name = 'li'
            node.inner_html = node.at_css('p').inner_html
          end
        end

        # Removes remaining errors.
        def remove_errors(doc)
          doc.xpath('//error').map(&:remove)
        end

        # Set the Tralics ids.
        # These aren't used, but there's little reason to throw them away.
        def set_ids(doc)
          doc.xpath('//*[@id]').each do |node|
            # TODO: make whitelist of non-tralics id's
            next if node['id'] =~ /footnote/

            node['data-tralics-id'] = node['id']
            node['id'] = node['data-label'].gsub(/:/, '-') if node['data-label']

            clean_node node, %w{data-label}
          end
        end

        # Given a section node, process the <head> tag.
        # Supports chapter, section, and subsection.
        def make_headings(doc, node, name)
          head_node = node.children.first
          head_node.name = name
          a = doc.create_element 'a'
          a['href'] = "##{node['id']}"
          a['class'] = 'heading'
          a << head_node.children
          head_node << a
        end

        def chapters_and_section(doc)
          doc.xpath('//div0').each do |node|
            node.name = 'div'
            is_chapter = node['type'] == 'chapter'
            node['class'] = is_chapter ? 'chapter' : 'section'
            clean_node node, %w{id-text type}
            make_headings(doc, node, 'h3')
          end
        end

        def subsection(doc)
          doc.xpath('//div1').each do |node|
            node.name = 'div'
            node['class'] = 'subsection'
            clean_node node, %w{id-text}
            make_headings(doc, node, 'h4')
          end
        end

        def title(doc)
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
        end

        # Converts text to smart single quotes and apostrophes.
        # This means `foo bar' and "don't" is converted to to use nice curly
        # "smart" quotes and apostrophes.
        # We don't bother with double quotes because Tralics already handles
        # those.
        def smart_single_quotes(doc)
          doc.traverse do |node|
            if node.text?
              node.content = node.content.gsub('`', '‘').gsub("'", '’')
            end
          end
        end

        # Restores literal environments (verbatim, code, math, etc.).
        # These environments are hashed and passed through the pipeline
        # so that Tralics doesn't process them.
        def restore_literal(doc)
          doc.xpath('//literal').each do |node|
            raw_content = literal_cache[node.content]
            node.parent.content = escape_backslashes(raw_content)
            node.remove
          end
          # Restore non-ASCII unicode
          doc.xpath('//unicode').each do |node|
            node.content = literal_cache[node.content]
            node.name = 'span'
            node['class'] = 'unicode'
          end
        end

        def make_cross_references(doc)
          # build numbering tree
          chapter_number = 0
          section_number = 0
          subsection_number = 0
          figure_number = 0
          doc.xpath('//*[@data-tralics-id]').each do |node|
            node['data-number'] = case node['class'].to_s
              when 'chapter'
                section_number = 0
                "#{chapter_number += 1}"
              when 'section'
                subsection_number = 0
                cha_n = chapter_number.zero? ? 1 : chapter_number
                "#{cha_n}.#{section_number += 1}"
              when 'subsection'
                cha_n = chapter_number.zero? ? 1 : chapter_number
                sec_n = section_number.zero? ? 1 : section_number
                "#{cha_n}.#{sec_n}.#{subsection_number += 1}"
              end
            if node.name == 'figure'
              cha_n = chapter_number.zero? ? 1 : chapter_number
              node['data-number'] = "#{cha_n}.#{figure_number += 1}"
            end

            # add number span
            if head = node.css('h2 a, h3 a, h4 a').first
              el = doc.create_element 'span'
              el.content = node['data-number'] + ' '
              el['class'] = 'number'
              head.children.first.add_previous_sibling el
            end
          end

          doc.xpath('//ref').each do |node|
            node.name = 'span'
            target = doc.xpath("//*[@data-tralics-id='#{node['target']}']")
            if target.empty?
              node['class'] = 'undefined_ref'
              node.content = node['target']
            else
              node['class'] = 'ref'
              node.content = target.first['data-number']
            end
            clean_node node, 'target'
          end

          doc.xpath('//*[@target]').each do |node|
            node['href'] = "##{node['target'].gsub(/:/, '-')}"
            node['class'] = 'hyperref'
            clean_node node, 'target'
          end
        end

        def hrefs(doc)
          doc.xpath('//xref').each do |node|
            node.name = 'a'
            node['href'] = node['url']
            clean_node node, 'url'
          end
        end

        # Handles both \includegraphics and figure environments.
        def graphics_and_figures(doc)
          doc.xpath('//figure').each do |node|
            node.name = 'div'
            node['class'] = 'figure'
            if internal_paragraph = node.at_css('p')
              clean_node internal_paragraph, 'rend'
            end
            if node['file'] && node['extension']
              filename = "#{node['file']}.#{node['extension']}"
              alt = File.basename(node['file'])
              img = %(<img src="#{filename}" alt="#{alt}" />)
              graphic = %(<div class="graphics">#{img}</div>)
              graphic_node = Nokogiri::HTML.fragment(graphic)
              if child = node.children.first
                # This is the case when there's a caption.
                child.add_previous_sibling(graphic_node)
              else
                node.add_child(graphic_node)
              end
              clean_node node, %w[file extension rend]
            end
            if caption = node.at_css('head')
              caption.name = 'div'
              caption['class'] = 'caption'
              n = node['data-number']
              header = %(<span class="header">Figure #{n}: </span>)
              description = %(<span class="description">#{caption.content}</span>)
              caption.inner_html = Nokogiri::HTML.fragment(header + description)
            end
            clean_node node, ['id-text']
          end
        end

        # Restores quote and verse environemtns.
        # Annoyingly, this is the easiest way to do things.
        # What we really want to do is just make the substitutions
        # \begin{quote} -> <blockquote>
        # \end{quote} -> </blockquote>
        # but that's hard to do using Tralics and XML. As a kludge,
        # we insert a tag with unique name and gsub it at the end.
        def quote_and_verse(html)
          html.gsub("<start-#{quote_digest}></start-#{quote_digest}>",
                    "<blockquote>").
               gsub("<end-#{quote_digest}></end-#{quote_digest}></p>",
                    "</p></blockquote>").
               gsub("<start-#{verse_digest}></start-#{verse_digest}>",
                    '<blockquote class="verse">').
               gsub("<end-#{verse_digest}></end-#{verse_digest}></p>",
                    "</p>\n</blockquote>\n")
        end

        # Highlights source code.
        # We pass it HTML instead of an XML document because otherwise
        # Nokogiri escapes it.
        def highlight_source_code(html)
          html.tap do
            code_cache.each do |key, (content, language)|
              html.gsub!(key, Pygments.highlight(content, lexer: language))
            end
          end
        end

        # Converts a document to HTML.
        # Because there's no way to know which elements are block-level
        # (and hence can't be nested inside a paragraph tag), we first extract
        # an HTML fragment by converting the document to HTML, and then use
        # Nokogiri's HTML.fragment method to read it in and emit valid markup.
        # (In between, we add in highlighted source code.)
        # This process transforms, e.g., the invalid
        #   <p>Preformatted text: <pre>text</pre> foo</p>
        # to the valid
        #  <p>Preformatted text:</p> <pre>text</pre> <p>foo</p>
        def convert_to_html(doc)
          body = doc.at_css('document').children.to_xhtml
          fragment = highlight_source_code(body)
          Nokogiri::HTML.fragment(fragment).to_xhtml
        end

        # Cleans a node by removing all the given attributes.
        def clean_node(node, attributes)
          [*attributes].each { |a| node.remove_attribute a }
        end
    end
  end
end