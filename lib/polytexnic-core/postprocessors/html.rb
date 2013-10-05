# encoding=utf-8
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
        metacode(doc)
        quote(doc)
        verse(doc)
        itemize(doc)
        enumerate(doc)
        item(doc)
        remove_errors(doc)
        set_ids(doc)
        chapters_and_section(doc)
        subsection(doc)
        subsubsection(doc)
        headings(doc)
        sout(doc)
        kode(doc)
        codelistings(doc)
        backslash_break(doc)
        asides(doc)
        center(doc)
        title(doc)
        doc = smart_single_quotes(doc)
        tex_logos(doc)
        restore_literal(doc)
        restore_inline_verbatim(doc)
        make_cross_references(doc)
        hrefs(doc)
        graphics_and_figures(doc)
        tables(doc)
        math(doc)
        frontmatter(doc)
        mainmatter(doc)
        footnotes(doc)
        table_of_contents(doc)
        convert_to_html(doc)
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

        # Handles metacode environments.
        # \begin{metacode}
        # <code>
        # \end{metacode}
        def metacode(doc)
          doc.xpath('//metacode').each do |node|
            node.name = 'div'
            node['class'] = 'code'
          end
        end

        # Handles math environments.
        # Included are
        # \begin{equation}
        # <equation>
        # \end{equation}
        # and all the AMS-LaTeX variants defined in
        # Preprocessor#math_environments.
        # We also handle inline/display math of the form \(x\) and \[y\].
        def math(doc)
          # math environments
          doc.xpath('//equation//texmath[@textype="equation"]').each do |node|
            node.name = 'div'
            node['class'] = 'equation'
            node.content = literal_cache[node.content.strip] + "\n"
            clean_node node, ['textype', 'type']
            node.parent.replace(node)
            begin
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
              next_paragraph = node.next_sibling
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

          # inline math
          doc.xpath('//inline').each do |node|
            node.name = 'span'
            node.content = literal_cache[node.content.strip]
            node['class'] = 'inline_math'
            clean_node node, ['textype', 'type']
          end
        end

        # Handles frontmatter (if any).
        def frontmatter(doc)
          doc.xpath('//frontmatter').each do |node|
            node.name = 'div'
            node['id'] = 'frontmatter'
            node['data-number'] = 0
          end
        end

        # Handles mainmatter.
        def mainmatter(doc)
          doc.xpath('//mainmatter').each do |node|
            node.parent << node.children
            node.remove
          end
        end

        # Processes and places footnotes.
        def footnotes(doc)
          footnotes = Hash.new { |h, k| h[k] = [] }
          doc.xpath('//note[@place="foot"]').each do |footnote|
            footnotes[chapter_number(footnote)] << footnote
          end
          # Handle chapters 1 through n-1.
          doc.xpath('//div[@class="chapter"]').each_with_index do |chapter, i|
            make_footnotes(footnotes, i, chapter)
          end
          # Place the footnotes for Chapter n (if any).
          final_chapter_number = doc.xpath('//div[@class="chapter"]').length
          make_footnotes(footnotes, final_chapter_number)
          rewrite_contents(footnotes)
        end

        # Returns a unique CSS id for the footnotes of a given chapter.
        def footnotes_id(chapter_number)
          "cha-#{chapter_number}_footnotes"
        end

        # Returns a unique CSS id for footnote n in given chapter.
        def footnote_id(chapter_number, n)
          "cha-#{chapter_number}_footnote-#{n}"
        end

        # Returns the href needed to link to footnote n.
        def footnote_href(chapter_number, n)
          "##{footnote_id(chapter_number, n)}"
        end

        # Returns a unique CSS id for the footnote reference.
        def footnote_ref_id(chapter_number, n)
          "cha-#{chapter_number}_footnote-ref-#{n}"
        end

        # Returns the href needed to link to reference for footnote n.
        def footnote_ref_href(chapter_number, n)
          "##{footnote_ref_id(chapter_number, n)}"
        end

        def make_footnotes(footnotes, previous_chapter_number, chapter = nil)
          unless (chapter_footnotes = footnotes[previous_chapter_number]).empty?
            doc = chapter_footnotes.first.document
            footnotes_node = footnotes_list(footnotes, previous_chapter_number)
            place_footnotes(footnotes_node, previous_chapter_number, chapter)
          end
        end

        # Returns a list of footnotes ready for placement.
        def footnotes_list(footnotes, chapter_number)
          doc = footnotes.values[0][0].document
          footnotes_node = Nokogiri::XML::Node.new('ol', doc)
          footnotes_node['class'] = 'footnotes'
          footnotes[chapter_number].each_with_index do |footnote, i|
            n = i + 1
            note = Nokogiri::XML::Node.new('li', doc)
            note['id'] = footnote_id(chapter_number, n)
            reflink = Nokogiri::XML::Node.new('a', doc)
            reflink['class'] = 'arrow'
            reflink.content = "↑"
            reflink['href'] = footnote_ref_href(chapter_number, n)
            note.inner_html = "#{footnote.inner_html} #{reflink.to_xhtml}"
            footnotes_node.add_child note
          end
          footnotes_node
        end

        # Places footnotes for Chapter n-1 just before Chapter n.
        def place_footnotes(footnotes_node, chapter_number, chapter = nil)
          doc = footnotes_node.document
          footnotes_wrapper_node = Nokogiri::XML::Node.new('div', doc)
          footnotes_wrapper_node['id'] = footnotes_id(chapter_number)
          footnotes_wrapper_node.add_child footnotes_node
          if chapter.nil?
            doc.children.last.add_child(footnotes_wrapper_node)
          else
            chapter.add_previous_sibling(footnotes_wrapper_node)
          end
        end

        # Rewrites contents of each footnote with its corresponding number.
        def rewrite_contents(footnotes)
          footnotes.each do |chapter_number, chapter_footnotes|
            chapter_footnotes.each_with_index do |node, i|
              n = i + 1
              node.name = 'sup'
              clean_node node, %w{place id id-text data-tralics-id data-number}
              node['id'] = footnote_ref_id(chapter_number, n)
              node['class'] = 'footnote'
              link = Nokogiri::XML::Node.new('a', node.document)
              link['href'] = footnote_href(chapter_number, n)
              link.content = n.to_s
              node.inner_html = link
            end
          end
        end

        # Returns the chapter number for a given node.
        # Every node is inside some div that has a 'data-number' attribute,
        # so recursively search the parents to find it.
        # Then return the first number in the value, e.g., "1" in "1.2".
        def chapter_number(node)
          number = node['data-number']
          if number && !number.empty?
            number.split('.').first.to_i
          else
            chapter_number(node.parent)
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
        def set_ids(doc)
          doc.xpath('//*[@id]').each do |node|
            # TODO: make whitelist of non-tralics id's
            next if node['id'] =~ /footnote/

            node['data-tralics-id'] = node['id']
            convert_labels(node)
            clean_node node, %w{data-label}
          end
          # Replace '<unexpected>' tags with their children.
          doc.xpath('//unexpected').each do |node|
            node.parent.children = node.children
            node.remove
          end
          doc.xpath('//figure').each do |node|
            if unexpected = node.at_css('unexpected')
              # Tralics puts in an 'unexpected' tag sometimes.
              label = node.at_css('data-label')
              node['id'] = pipeline_label(label)
              unexpected.remove
              clean_node node, %w{data-label}
            elsif label = node.at_css('data-label')
              node['id'] = pipeline_label(label)
              label.remove
              clean_node node, %w{data-label}
            end
          end
          doc.xpath('//table').each do |node|
            if unexpected = node.at_css('unexpected')
              # Tralics puts in an 'unexpected' tag sometimes.
              label = node.at_css('data-label')
              node['id'] = pipeline_label(label)
              unexpected.remove
              clean_node node, %w{data-label}
            elsif label = node.at_css('data-label')
              node['id'] = pipeline_label(label)
              label.remove
              clean_node node, %w{data-label}
            end
          end
          doc.xpath('//equation').each do |node|
            if label = node.at_css('data-label')
              node.at_css('texmath')['id'] = pipeline_label(label)
              label.remove
            end
          end
        end

        def convert_labels(node)
          node.children.each do |child|
            if child.name == 'data-label'
              node['id'] = pipeline_label(child)
              child.remove
              break
            end
          end
        end

        # Restore the label.
        # Tralics does weird stuff with underscores, so they are subbed out
        # so that they can be passed through the pipeline intact. This is where
        # we restore them.
        def pipeline_label(node)
          node.inner_html.gsub(underscore_digest, '_')
        end

        # Given a section node, process the <head> tag.
        # Supports chapter, section, and subsection.
        def make_headings(doc, node, name)
          head_node = node.children.first
          head_node.name = name
          a = doc.create_element 'a'
          a['href'] = "##{node['id']}" unless node['id'].nil?
          a['class'] = 'heading'
          a << head_node.children
          head_node << a
        end

        def chapters_and_section(doc)
          doc.xpath('//div0').each do |node|
            node.name = 'div'
            if node['type'] == 'chapter'
              node['class'] = 'chapter'
              heading = 'h1'
            else
              node['class'] = 'section'
              heading = 'h2'
            end
            if node['rend'] == 'nonumber'
              node['class'] += '-star'
            end
            clean_node node, %w{type rend}
            make_headings(doc, node, heading)
          end
        end

        def subsection(doc)
          doc.xpath('//div1').each do |node|
            node.name = 'div'
            node['class'] = 'subsection'
            if node['rend'] == 'nonumber'
              node['class'] += '-star'
            end
            clean_node node, %w{rend}
            make_headings(doc, node, 'h3')
          end
        end

        def subsubsection(doc)
          doc.xpath('//div2').each do |node|
            node.name = 'div'
            node['class'] = 'subsubsection'
            clean_node node, %w{rend}
            make_headings(doc, node, 'h4')
          end
        end

        # Converts heading elements to the proper spans.
        # Headings are used in codelisting-like environments such as asides
        # and codelistings.
        def headings(doc)
          doc.xpath('//heading').each do |node|
            node.name  = 'span'
            node['class'] = 'description'
          end
        end

        # Converts strikeout text (\sout) to the proper tag.
        def sout(doc)
          doc.xpath('//sout').each do |node|
            node.name  = 'del'
          end
        end

        # Converts inline code (\kode) to the proper tag.
        def kode(doc)
          doc.xpath('//kode').each do |node|
            node.name  = 'code'
          end
        end

        # Builds the full heading for codelisting-like environments.
        # The full heading, such as "Listing 1.1. Foo bars." needs to be
        # extracted and manipulated to produce the right tags and classes.
        def build_heading(node, css_class)
          node.name  = 'div'
          node['class'] = css_class

          heading = node.at_css('p')
          heading.attributes.each do |key, value|
            node.set_attribute(key, value)
            heading.remove_attribute(key)
          end
          heading.name = 'div'
          heading['class'] = 'heading'

          number = heading.at_css('strong')
          number.name = 'span'
          number['class'] = 'number'
          number.content += '.'

          heading
        end

        # Processes codelisting environments.
        def codelistings(doc)
          doc.xpath('//codelisting').each do |node|
            heading = build_heading(node, 'codelisting')
            code = heading.at_css('div.code')
            node.add_child(code)
          end
        end

        # Add in breaks from '\\'.
        def backslash_break(doc)
          doc.xpath('//backslashbreak').each do |node|
            node.name  = 'br'
          end
        end

        # Processes boxes/asides.
        def asides(doc)
          doc.xpath('//aside').each do |node|
            build_heading(node, 'aside')
          end
        end

        # Processes centered elements.
        def center(doc)
          doc.xpath('//center').each do |node|
            node.name = 'div'
            node['class'] = 'center'
          end
        end

        def title(doc)
          doc.xpath('//maketitle').each do |node|
            node.name = 'div'
            node['id'] = 'title_page'
            %w{title subtitle author date}.each do |field|
              class_var = Polytexnic.instance_variable_get "@#{field}"
              if class_var
                type = %w{title subtitle}.include?(field) ? 'h1' : 'h2'
                el = Nokogiri::XML::Node.new(type, doc)
                raw = Polytexnic::Core::Pipeline.new(class_var).to_html
                content = Nokogiri::HTML.fragment(raw).at_css('p')
                el.inner_html = content.inner_html
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
          s = doc.to_xml
          s.gsub!('`', '‘')
          s.gsub!("'", '’')
          Nokogiri::XML(s)
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
          # Restore equation references.
          doc.xpath('//eqref').each do |node|
            node.content = literal_cache[node.content]
            node.name = 'span'
            node['class'] = 'eqref'
          end
          # Restore non-ASCII unicode
          doc.xpath('//unicode').each do |node|
            node.content = literal_cache[node.content]
            node.name = 'span'
            node['class'] = 'unicode'
          end
        end

        # Restores things inside \verb+...+
        def restore_inline_verbatim(doc)
          doc.xpath('//inlineverbatim').each do |node|
            node.content = literal_cache[node.content]
            node.name = 'span'
            node['class'] = 'inline_verbatim'
          end
        end

        def make_cross_references(doc)
          # build numbering tree
          doc.xpath('//*[@data-tralics-id]').each do |node|
            node['data-number'] = if node['class'] == 'chapter'
                                    # Tralics numbers figures & equations
                                    # overall, not per chapter, so we need
                                    # counters.
                                    @equation = 0
                                    @figure = 0
                                    @cha = node['id-text']
                                  elsif node['class'] == 'section'
                                    @sec = node['id-text']
                                    label_number(@cha, @sec)
                                  elsif node['class'] == 'subsection'
                                    @subsec = node['id-text']
                                    label_number(@cha, @sec, @subsec)
                                  elsif node['class'] == 'subsubsection'
                                    @ssubsec = node['id-text']
                                    label_number(@cha, @sec, @subsec, @ssubsec)
                                  elsif node['textype'] == 'equation'
                                    if @cha.nil?
                                      @equation = node['id-text']
                                    else
                                      @equation += 1
                                    end
                                    label_number(@cha, @equation)
                                  elsif node['class'] == 'codelisting'
                                    node['id-text']
                                  elsif node['class'] == 'aside'
                                    node['id-text']
                                  elsif node.name == 'table' && node['id-text']
                                    @table = node['id-text']
                                    label_number(@cha, @table)
                                  elsif node.name == 'figure'
                                    if @cha.nil?
                                      @figure = node['id-text']
                                    else
                                      @figure += 1
                                    end
                                    label_number(@cha, @figure)
                                  end
            clean_node node, 'id-text'
            # Add number span
            if head = node.css('h1 a, h2 a, h3 a, h4 a').first
              el = doc.create_element 'span'
              number = node['data-number']
              prefix = (@cha.nil? || number.match(/\./)) ? '' : 'Chapter '
              el.content = prefix + node['data-number'] + ' '
              el['class'] = 'number'
              head.children.first.add_previous_sibling el
            end
          end

          targets = doc.xpath("//*[@data-tralics-id]")
          target_cache = {}
          targets.each do |target|
            target_cache[target['data-tralics-id']] = target
          end

          doc.xpath('//ref').each do |node|
            node.name = 'span'
            target = target_cache[node['target']]
            if target.nil?
              node['class'] = 'undefined_ref'
              node.content = node['target']
            else
              node['class'] = 'ref'
              node.content = target['data-number']
            end
            clean_node node, 'target'
          end

          doc.xpath('//*[@target]').each do |node|
            node['href'] = "##{node['target'].gsub(':', '-')}"
            node['class'] = 'hyperref'
            clean_node node, 'target'
          end
        end

        # Returns a label number for use in headings.
        # For example, label_number("1", "2") returns "1.2".
        def label_number(*args)
          args.compact.join('.')
        end

        def hrefs(doc)
          require 'open-uri'
          doc.xpath('//xref').each do |node|
            node.name = 'a'
            node['href'] = encode(literal_cache[node['url']])
            clean_node node, 'url'
          end
        end

        # Encodes the URL.
        # We take care to preserve '#' symbols, as they are needed to link
        # to CSS ids within HTML documents.
        # This uses 'sub' instead of 'gsub' because only the first '#' can
        # link to an id.
        def encode(url)
          pound_hash = digest('#')
          encoded_url = URI::encode(url.sub('#', pound_hash))
          encoded_url.sub(pound_hash, '#')
        end

        # Handles both \includegraphics and figure environments.
        # The unified treatment comes from Tralics using the <figure> tag
        # in both cases.
        def graphics_and_figures(doc)
          doc.xpath('//figure').each do |node|
            node.name = 'div'
            if node['class']
              node['class'] += ' figure'
            else
              node['class'] = 'figure'
            end
            raw_graphic = (node['rend'] == 'inline')
            if internal_paragraph = node.at_css('p')
              clean_node internal_paragraph, 'rend'
            end
            if node['file'] && node['extension']
              extension = node['extension']
              # Support PDF images in PDF documents and PNGs in HTML.
              extension = 'png' if extension == 'pdf'
              filename = "#{node['file']}.#{extension}"
              alt = File.basename(node['file'])
              img = %(<img src="#{filename}" alt="#{alt}" />)
              graphic = %(<div class="graphics">#{img}</div>)
              graphic_node = Nokogiri::HTML.fragment(graphic)
              if description_node = node.children.first
                description_node.add_previous_sibling(graphic_node)
              else
                node.add_child(graphic_node)
              end
              clean_node node, %w[file extension rend]
            end
            add_caption(node, name: 'figure') unless raw_graphic
          end
        end

        # Adds a caption to a node.
        # This works for figures and tables (at the least).
        def add_caption(node, options={})
          name = options[:name].to_s.capitalize
          doc = node.document
          full_caption = Nokogiri::XML::Node.new('div', doc)
          full_caption['class'] = 'caption'
          n = node['data-number']
          if description_node = node.at_css('head')
            h = %(<span class="header">#{name} #{n}: </span>)
            d = %(<span class="description">#{description_node.content}</span>)
            description_node.remove
            full_caption.inner_html = Nokogiri::HTML.fragment(h + d)
          else
            header = %(<span class="header">#{name} #{n}</span>)
            full_caption.inner_html = header
          end
          node.add_child(full_caption)
          clean_node node, ['id-text']
        end

        # Converts XML to HTML tables.
        def tables(doc)

          doc.xpath('//table/row/cell').each do |node|
            node.name = 'td'
          end
          doc.xpath('//table/row').each do |node|
            node.name = 'tr'
            if node['bottom-border'] == 'true'
              node['class'] = 'bottom_border'
              clean_node node, %w[bottom-border]
            end
          end
          tabular_count = 0
          doc.xpath('//table').each do |node|
            if tabular?(node)
              node['class'] = 'tabular'
              clean_node node, %w[rend]
              add_cell_alignment(node, tabular_count)
              tabular_count += 1
            elsif table?(node)
              node.name = 'div'
              node['class'] = 'table'
              unless node.at_css('table')
                inner_table = Nokogiri::XML::Node.new('table', doc)
                inner_table['class'] = 'tabular'
                inner_table.children = node.children
                add_cell_alignment(inner_table, tabular_count)
                tabular_count += 1
                node.add_child(inner_table)
              end
              clean_node node, %w[rend]
              add_caption(node, name: 'table')
            end
          end
        end

        # Adds the alignment (left, center, right) plus the border (if any).
        def add_cell_alignment(table, tabular_count)
          alignments = @tabular_alignment_cache[tabular_count]
          cell_alignments = alignments.scan(/(\|*(?:l|c|r)\|*)/).flatten
          table.css('tr').each do |row|
            row.css('td').zip(cell_alignments).each do |cell, alignment|
              cell['class'] = alignment_class(alignment)
              clean_node cell, %w[halign right-border left-border]
            end
          end
        end

        # Returns the CSS class corresponding to the given table alignment.
        def alignment_class(alignment)
          alignment.sub('l', 'align_left')
                   .sub('r', 'align_right')
                   .sub('c', 'align_center')
                   .sub(/^\|/, 'left_border ')
                   .sub(/\|$/, ' right_border')
        end

        # Returns true if a table node is from a 'tabular' environment.
        # Tralics converts both
        # \begin{table}...
        # and
        # \begin{tabular}
        # to <table> tags, so we have to disambiguate them.
        def tabular?(table)
          table['rend'] == 'inline'
        end

        # Returns true if a table node is from a 'table' environment.
        # The make_cross_references method tags such tables with a
        # 'data-number' attribute, so we use that to detect 'table' envs.
        def table?(table)
          !table['data-number'].nil?
        end

        # Trims empty paragraphs.
        # Sometimes a <p></p> creeps in due to idiosyncrasies of the
        # Tralics conversion.
        def trim_empty_paragraphs(string)
          string.gsub!(/<p>\s*<\/p>/, '')
        end

        # Converts a document to HTML.
        # Because there's no way to know which elements are block-level
        # (and hence can't be nested inside a paragraph tag), we first extract
        # an HTML fragment by converting the document to HTML, and then use
        # Nokogiri's HTML.fragment method to read it in and emit valid markup.
        # This process transforms, e.g., the invalid
        #   <p>Preformatted text: <pre>text</pre> foo</p>
        # to the valid
        #  <p>Preformatted text:</p> <pre>text</pre> <p>foo</p>
        def convert_to_html(doc)
          highlight_source_code(doc)
          File.open(@highlight_cache_filename, 'wb') do |f|
            f.write(highlight_cache.to_msgpack)
          end
          body = doc.at_css('document').children.to_xhtml
          Nokogiri::HTML.fragment(body).to_xhtml.tap do |html|
            trim_empty_paragraphs(html)
          end
        end

        # Handles table of contents (if present).
        # This code could no doubt be made much shorter, but probably at the
        # cost of clarity.
        def table_of_contents(doc)
          toc = doc.at_css('tableofcontents')
          return if toc.nil?
          toc.add_previous_sibling('<h1 class="contents">Contents</h1>')
          toc.name = 'div'
          toc['id'] = 'table_of_contents'
          toc.remove_attribute 'depth'
          html = []
          current_depth = 0
          doc.css('div').each do |node|
            case node['class']
            when 'chapter'
              html << '<ul>' if current_depth == 0
              while current_depth > 1
                close_list(html)
                current_depth -= 1
              end
              current_depth = 1
              insert_li(html, node)
            when 'section'
              open_list(html) if current_depth == 1
              while current_depth > 2
                close_list(html)
                current_depth -= 1
              end
              current_depth = 2
              insert_li(html, node)
            when 'subsection'
              open_list(html) if current_depth == 2
              while current_depth > 3
                close_list(html)
                current_depth -= 1
              end
              current_depth = 3
              insert_li(html, node)
            when 'subsubsection'
              open_list(html) if current_depth == 3
              while current_depth > 4
                close_list(html)
                current_depth -= 1
              end
              current_depth = 4
              insert_li(html, node)
            end
          end
          toc.add_child(Nokogiri::HTML::DocumentFragment.parse(html.join))
        end

        def open_list(html, li=true)
          html << '<li>' if li
          html << '<ul>'
        end

        def close_list(html, li=true)
          html << '</ul>'
          html << '</li>' if li
        end

        def insert_li(html, node)
          open = %(<li class="#{node['class']}">)
          link = node.at_css('a.heading')
          link['class'] += ' hyperref'
          html << open << link.to_xhtml << '</li>'
        end

        # Cleans a node by removing all the given attributes.
        def clean_node(node, attributes)
          [*attributes].each { |a| node.remove_attribute a }
        end
    end
  end
end