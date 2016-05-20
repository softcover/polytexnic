# encoding=utf-8
module Polytexnic
  module Postprocessor
    module Html

      # Converts Tralics XML output to HTML.
      def xml_to_html(xml)
        restore_underscores(xml)
        doc = Nokogiri::XML(xml)
        comments(doc)
        emphasis(doc)
        boldface(doc)
        small_caps(doc)
        small(doc)
        skips(doc)
        verbatim(doc)
        code(doc)
        metacode(doc)
        typewriter(doc)
        quote(doc)
        verse(doc)
        itemize(doc)
        enumerate(doc)
        item(doc)
        remove_errors(doc)
        set_ids(doc)
        chapters_and_sections(doc)
        subsection(doc)
        subsubsection(doc)
        headings(doc)
        sout(doc)
        kode(doc)
        coloredtext(doc)
        filepath(doc)
        backslash_break(doc)
        spaces(doc)
        center(doc)
        title(doc)
        doc = smart_single_quotes(doc)
        tex_logos(doc)
        restore_literal(doc)
        doc = restore_unicode(doc)
        restore_inline_verbatim(doc)
        codelistings(doc)
        asides(doc)
        make_cross_references(doc)
        hrefs(doc)
        graphics_and_figures(doc)
        images_and_imageboxes(doc)
        tables(doc)
        math(doc)
        frontmatter(doc)
        mainmatter(doc)
        footnotes(doc)
        table_of_contents(doc)
        convert_to_html(doc)
      end

      private

        # Restores underscores.
        # Tralics does weird stuff with underscores, in some contexts,
        # so they are subbed out and passed through the pipeline intact.
        # This is where we restore them.
        def restore_underscores(xml)
          xml.gsub!(underscore_digest, '_')
        end

        # Replaces comment content with proper HTML comments.
        def comments(doc)
          doc.xpath('//comment').each do |node|
            node.replace("<!-- #{node.inner_html} -->")
          end
        end

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

        # Handles \small.
        def small(doc)
          doc.xpath('//hi[@rend="small"]').each do |node|
            node.name = 'small'
            node.remove_attribute('rend')
          end
        end

        # Handles \bigskip, etc.
        def skips(doc)
          doc.xpath('//p[@spacebefore]').each do |node|
            node['style'] = "margin-top: #{node['spacebefore']}"
            node.remove_attribute('spacebefore')
          end
        end

        # Handles output of \texttt{}.
        def typewriter(doc)
          doc.xpath('//hi[@rend="tt"]').each do |node|
            node.name = 'code'
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
              # Check to make sure it's a paragraph.
              raise unless next_paragraph.name == 'p'
              next_paragraph['noindent'] = 'true'
            rescue
              # We rescue nil in case the math isn't followed by a paragraph.
              nil
            end
          end
          doc.xpath('//equation//texmath[@textype="equation*"]').each do |node|
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

          # using \ensuremath
          doc.xpath('//texmath[@textype="inline"]').each do |node|
            node.name = 'span'
            node.content = "\\( #{node.content} \\)"
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
          # For symbolic footnotes, we want to suppress numbers, which can be
          # done in CSS, but it doesn't work in many EPUB & MOBI readers.
          # As a kludge, we switch to ul in this case, which looks nicer.
          list_type = footnote_symbols? ? 'ul' : 'ol'
          footnotes_node = Nokogiri::XML::Node.new(list_type, doc)
          footnotes_node['class'] = 'footnotes'
          footnotes_node['class'] += ' nonumbers' if footnote_symbols?
          footnotes[chapter_number].each_with_index do |footnote, i|
            n = i + 1
            note = Nokogiri::XML::Node.new('li', doc)
            note['id'] = footnote_id(chapter_number, n)
            reflink = Nokogiri::XML::Node.new('a', doc)
            reflink['class'] = 'arrow'
            reflink.content = "↑"
            reflink['href'] = footnote_ref_href(chapter_number, n)
            html = "#{footnote.inner_html} #{reflink.to_xhtml}"
            html = "<sup>#{fnsymbol(i)}</sup> #{html}" if footnote_symbols?
            note.inner_html = html
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
              content = footnote_symbols? ? fnsymbol(i) : n.to_s
              link.content = content
              node.inner_html = link
              # Support footnotes in chapter & section headings.
              if node.parent['class'] == 'heading'
                # Move footnote outside section anchor tag.
                node.parent = node.parent.parent
              end
              # Add an intersentence space if appropriate.
              previous_character = node.previous_sibling.content[-1]
              end_of_sentence = %w[. ! ?].include?(previous_character)
              after = node.next_sibling
              end_of_paragraph = after.nil? || after.content.strip.empty?
              if end_of_sentence && !end_of_paragraph
                space = Nokogiri::XML::Node.new('span', node.document)
                space['class'] = 'intersentencespace'
                node['class'] += ' intersentence'
                node.add_next_sibling(space)
              end
              # Remove spurious intersentence space from mid-sentence notes.
              next_sibling = node.next_sibling
              if !end_of_sentence && intersentence_space?(next_sibling)
                next_sibling.remove
              end
            end
          end
        end

        # Returns true if a node is an intersentence space
        def intersentence_space?(node)
          node && node.values == ['intersentencespace']
        end

        # Returns the nth footnote symbol for use in non-numerical footnotes.
        # By using the modulus operator %, we arrange to loop around to the
        # front if the number footnotes exceeds the number of symbols.
        def fnsymbol(n)
          symbols = %w[* † ‡ § ¶ ‖ ** †† ‡‡]
          symbols[n % symbols.size]
        end

        # Returns the chapter number for a given node.
        # Every node is inside some div that has a 'data-number' attribute,
        # so recursively search the parents to find it.
        # Then return the first number in the value, e.g., "1" in "1.2".
        # Update: Hacked a solution to handle the uncommon case of a footnote
        # inside a section* environment.
        def chapter_number(node)
          return 0 if article?
          number = node['data-number']
          if number && !number.empty?
            number.split('.').first.to_i
          elsif section_star?(node)
            chapter_number(section_star_chapter(node))
          else
            chapter_number(node.parent) rescue nil
          end
        end

        # Returns true if node is inside section*.
        def section_star?(node)
          begin
            # puts (val = node.parent.parent.attributes['class'].value) + '*******'
            # puts node.parent.parent.parent.parent.children[1] if val == 'section-star'
            node.parent.parent.attributes['class'].value == 'section-star'
          rescue
            false
          end
        end

        # Returns the chapter node for a section*.
        def section_star_chapter(node)
          section_star = node.parent.parent
          potential_chapter = section_star
          # Keep accessing previous siblings until we hit a chapter.
          while (potential_chapter = potential_chapter.previous_sibling) do
            return potential_chapter if chapter?(potential_chapter)
          end
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

        # Returns HTML for a nicely styled TeX logo.
        def tex
          %(<span class="texhtml">T<span class="texhtmlE">E</span>X</span>)
        end

        # Returns HTML for a nicely styled LaTeX logo.
        def latex
          %(<span class="texhtml">L<span class="texhtmlA">A</span>T<span class="texhtmlE">E</span>X</span>)
        end

        # Handles \begin{quote} ... \end{quote}.
        def quote(doc)
          doc.xpath('//p[@rend="quoted"]').each do |node|
            clean_node node, %w{rend noindent}
            node.name = 'blockquote'
            node['class'] = 'quote'
          end

          # Put a class on each paragraph.
          # This is needed to style them for Kindle for iPad.
          doc.css('blockquote p').each do |node|
            node['class'] = 'quote'
          end
        end

        # Handles \begin{verse} ... \end{verse}.
        def verse(doc)
          doc.xpath('//p[@rend="verse"]').each do |node|
            clean_node node, %w{rend noindent}
            node.name = 'blockquote'
            node['class'] = 'verse'
          end
        end

        # Converts itemized lists to uls.
        def itemize(doc)
          doc.xpath('//list[@type="simple"]').each do |node|
            clean_node node, 'type'
            node.name = 'ul'
          end
        end

        # Converts enumerated lists to ols.
        def enumerate(doc)
          doc.xpath('//list[@type="ordered"]').each do |node|
            clean_node node, 'type'
            node.name = 'ol'
          end
        end

        # Returns the node for a list item (li).
        def item(doc)
          doc.xpath('//item/p[@noindent="true"]').each do |node|
            node.replace(node.inner_html)
          end
          doc.xpath('//item').each do |node|
            clean_node node, %w{id-text id label}
            node.name = 'li'
          end
        end

        # Removes remaining errors.
        # Also included is the 'newpage' & 'allowbreak' tags, which
        # theoretically should have been added to the list of ignored commands
        # in utils.rb#tralics_commands, but for some reason that doesn't work.
        def remove_errors(doc)
          %w[newpage allowbreak error].each do |tag|
            doc.xpath("//#{tag}").map(&:remove)
          end
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
            elsif label = node.at_css('data-label')
              node['id'] = pipeline_label(label)
              label.remove
            end
            clean_node node, %w{data-label place width}
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

        # Convert data-labels to valid CSS ids.
        def convert_labels(node)
          node.children.each do |child|
            if child.name == 'data-label'
              node['id'] = pipeline_label(child)
              child.remove
              break
            end
          end
        end

        # Pulls the label out of the node.
        def pipeline_label(node)
          node.inner_html
        end

        # Processes the <head> tag given a section node.
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

        # Converts div0 to chapters and sections depending on node type.
        def chapters_and_sections(doc)
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
              # Add an id for linking based on the text of the section.
              text = node.children.first.text
              node['id'] = text.downcase.gsub(' ', '_').gsub(/[^\w]/, '')
              node['class'] += '-star'
            end
            clean_node node, %w{type rend}
            make_headings(doc, node, heading)
          end
        end

        # Converts div1 to subsections.
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

        # Converts div2 to subsections.
        def subsubsection(doc)
          doc.xpath('//div2').each do |node|
            node.name = 'div'
            node['class'] = 'subsubsection'
            clean_node node, %w{rend}
            make_headings(doc, node, 'h4')
          end
        end

        # Converts heading elements to the proper spans.
        # Headings are used in theorem-like environments like asides.
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

        # Converts colored text to HTML.
        def coloredtext(doc)
          # Handle \coloredtext{red}{text}
          doc.xpath('//coloredtext').each do |node|
            node.name  = 'span'
            node['style'] = "color: #{node['color']}"
            clean_node node, 'color'
          end

          # Handle \coloredtexthtml{ff0000}{text}
          doc.xpath('//coloredtexthtml').each do |node|
            node.name  = 'span'
            color = node['color']
            # Catch common case of using lower-case hex.
            if color =~ /[a-f]/
              raise "RGB hex color must be upper-case (for LaTeX's sake)"
            end
            node['style'] = "color: ##{color}"
            clean_node node, 'color'
          end
        end

        # Converts filesystem path (\filepath) to the proper tag.
        def filepath(doc)
          doc.xpath('//filepath').each do |node|
            node.name  = 'span'
            node['class'] = 'filepath'
          end
        end

        # Builds the full heading for codelisting-like environments.
        # The full heading, such as "Listing 1.1: Foo bars." needs to be
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
          number.content = number.content.sub!('0.', '') if article?
          number.name = 'span'
          number['class'] = 'number'
          if css_class == 'codelisting'
            description = node.at_css('.description').content
            number.content += ':' unless description.empty?
          else
            number.content += '.'
          end

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
        # We use a span instead of '<br />' because breaks can't be styled
        # easily, and are also invalid in some contexts where we want a
        # break (e.g., inside h1 tags).
        def backslash_break(doc)
          doc.xpath('//backslashbreak').each do |node|
            node.name  = 'span'
            node['class'] = 'break'
          end
        end

        # Handles normal, thin, and intersentence spaces.
        def spaces(doc)
          doc.xpath('//thinspace').each do |node|
            node.name  = 'span'
            node['class'] = 'thinspace'
            node.inner_html = '&thinsp;'
          end
          doc.xpath('//normalspace').each do |node|
            node.replace(' ')
          end
          doc.xpath('//intersentencespace').each do |node|
            node.name = 'span'
            node['class'] = 'intersentencespace'
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

        # Handles the title, author, date, etc., produced by \maketitle.
        def title(doc)
          doc.xpath('//maketitle').each do |node|
            node.name = 'div'
            node['id'] = 'title_page'
            %w{title subtitle author date}.each do |field|
              title_element = maketitle_elements[field]
              if title_element
                type = %w{title subtitle}.include?(field) ? 'h1' : 'h2'
                el = Nokogiri::XML::Node.new(type, doc)
                pipe = Polytexnic::Pipeline.new(title_element,
                                                literal_cache: literal_cache)
                raw_html = pipe.to_html
                content = Nokogiri::HTML.fragment(raw_html).at_css('p')
                unless (content.nil? && field == 'date')
                  el.inner_html = content.inner_html.strip
                  el['class'] = field
                  node.add_child el
                end
              elsif field == 'date'
                # Date is missing, so insert today's date.
                el = Nokogiri::XML::Node.new('h2', doc)
                el['class'] = field
                el.inner_html = Date.today.strftime("%A, %b %e")
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

        def restore_unicode(doc)
          s = doc.to_xml
          unicode_cache.each do |key, value|
            s.gsub!(key, value)
          end
          Nokogiri::XML(s)
        end

        # Restores things inside \verb+...+
        def restore_inline_verbatim(doc)
          doc.xpath('//inlineverbatim').each do |node|
            node.content = literal_cache[node.content]
            node.name = 'span'
            node['class'] = 'inline_verbatim'
          end
        end

        # Creates linked cross-references.
        def make_cross_references(doc)
          # build numbering tree
          doc.xpath('//*[@data-tralics-id]').each do |node|
            node['data-number'] = formatted_number(node)
            clean_node node, 'id-text'
            # Add number span
            if (head = node.css('h1 a, h2 a, h3 a').first)
              el = doc.create_element 'span'
              el.content = section_label(node)
              el['class'] = 'number'
              chapter_name = head.children.first
              if chapter_name.nil?
                head.add_child(el)
              else
                chapter_name.add_previous_sibling(el)
              end
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
            if node['target'] == '_blank'
              # This branch gets hit when running a title element
              # through the pipeline a second time.
              node['href'] = unescape_special_chars(literal_cache[node['href']])
            else
              node['href'] = "##{node['target'].gsub(':', '-')}"
              node['class'] = 'hyperref'
              clean_node node, 'target'
            end
          end
        end

        # Returns the section label for the node; e.g., "Chapter 2".
        def section_label(node)
          number = node['data-number']
          if chapter?(node)
            label = if language_labels["chapter"]["order"] == "reverse"
                      number + ' ' + chaptername
                    else
                      chaptername + ' ' + number
                    end
          else
            label = number
          end
          label + ' '
        end

        # Returns true if the node represents a chapter.
        def chapter?(node)
          attributes = node.attributes
          attributes && attributes['class'] &&
                        attributes['class'].value =~ /chapter/
        end

        # Returns the name to use for chapters.
        # The default is 'Chapter', of course, but this can be overriden
        # using 'language_labels', especially in books other than English.
        def chaptername
          language_labels["chapter"]["word"]
        end

        # Returns the formatted number appropriate for the node.
        # E.g., "2.1" for a section.
        # Note: sets @cha as a side-effect. Yes, this is gross.
        def formatted_number(node)
          if node['class'] == 'chapter'
            # Tralics numbers figures & equations
            # overall, not per chapter, so we need
            # counters.
            @equation = 0
            @figure = 0
            @table = 0
            @aside = 0
            @cha = article? ? nil : node['id-text']
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
            @equation = ref_number(node, @cha, @equation)
            label_number(@cha, @equation)
          elsif node['class'] == 'codelisting'
            @listing = number_from_id(node['id-text'])
            label_number(@cha, @listing)
          elsif node['class'] == 'aside'
            @aside = @cha.nil? ? number_from_id(node['id-text']) : @aside + 1
            label_number(@cha, @aside)
          elsif node.name == 'table' && node['id-text']
            @table = ref_number(node, @cha, @table)
            label_number(@cha, @table)
          elsif node.name == 'figure'
            @figure = ref_number(node, @cha, @figure)
            label_number(@cha, @figure)
          end
        end

        # Returns the reference number (i.e., the 'x' in '2.x').
        def ref_number(node, chapter, object)
          chapter.nil? ? node['id-text'] : object + 1
        end

        # Extract the sequential number from the node id.
        # I.e., number_from_id('2.3') -> '3'
        def number_from_id(id)
          id.split('.')[1]
        end

        # Returns true if pipeline was called on an article document.
        def article?
          !!article
        end

        # Returns a label number for use in headings.
        # For example, label_number("1", "2") returns "1.2".
        def label_number(*args)
          args.compact.join('.')
        end

        def hrefs(doc)
          doc.xpath('//xref').each do |node|
            node.name = 'a'
            node['href'] = unescape_special_chars(literal_cache[node['url']])
            node['target'] = '_blank'   # open in new window/tab
            # Put a class on hrefs containing TeX to allow a style override.
            node.traverse do |descendant|
              if descendant['class'] == 'texhtml'
                node['class'] = 'tex'
                break
              end
            end
            clean_node node, 'url'
          end
        end

        # Unescapes some special characters that are escaped by kramdown.
        def unescape_special_chars(url)
          url.gsub(/\\_/, '_').gsub(/\\#/, '#').gsub(/\\%/, '%')
        end

        # Handles both \includegraphics and figure environments.
        # The unified treatment comes from Tralics using the <figure> tag
        # in both cases.
        def graphics_and_figures(doc)
          doc.xpath('//figure').each do |node|
            process_graphic(node, klass: 'figure')
          end
        end

        # Processes a graphic, including the description.
        def process_graphic(node, options={})
          klass = options[:klass]
          raw_graphic = (node['rend'] == 'inline')
          node.name = raw_graphic ? 'span' : 'div'
          unless raw_graphic
            if node['class']
              node['class'] += " #{klass}"
            else
              node['class'] = klass
            end
          end
          if internal_paragraph = node.at_css('p')
            clean_node internal_paragraph, 'rend'
          end

          # If no extension is specified in the source code
          # this assumes .png for HTML / EPUB / MOBI
          if node['extension'].nil?
            node['extension'] = 'png'
          end

          if node['file'] && node['extension']
            filename = png_for_pdf(node['file'], node['extension'])
            alt = File.basename(node['file'])
            img = %(<img src="#{filename}" alt="#{alt}" />)
            graphic = %(<span class="graphics">#{img}</span>)
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

        # Handles \image and \imagebox commands.
        def images_and_imageboxes(doc)
          doc.xpath('//image').each do |node|
            handle_image(node, klass: 'image')
          end

          doc.xpath('//imagebox').each do |node|
            handle_image(node, klass: 'image box')
          end
        end

        # Processes custom image environment to use a div and the right class.
        def handle_image(node, options={})
          klass = options[:klass]
          container = node.parent
          container.name = 'div'
          container['class'] = 'graphics ' + klass
          node.name = 'img'
          node['src'] = png_for_pdf(node.content.gsub(underscore_digest, '_'))
          node['alt'] = node['src'].split('.').first
          node.content = ""
        end

        # Returns the name of an image file with PNG for PDF if necessary.
        # This is to support PDF images in the raw source, which look good in
        # PDF document, but need to be web-friendly in the HTML. We standardize
        # on PNG for simplicity. This means that, to do something like
        #     \image{images/foo.pdf}
        # authors need to have both foo.pdf and foo.png in their images/
        # directory. In this case, foo.pdf will be used in the PDF output, while
        # foo.png will automatically be used in the HTML, EPUB, & MOBI versions.
        def png_for_pdf(name, extension=nil)
          if extension.nil?
            name.sub('.pdf', '.png')
          else
            ext = extension == 'pdf' ? 'png' : extension
            "#{name}.#{ext}"
          end
        end

        # Adds a caption to a node.
        # This works for figures and tables (at the least).
        def add_caption(node, options={})
          name = language_labels[options[:name].to_s]
          doc = node.document
          full_caption = Nokogiri::XML::Node.new('div', doc)
          full_caption['class'] = 'caption'
          n = node['data-number']
          if description_node = node.at_css('head')
            content = description_node.inner_html
            separator = content.empty? ? '' : ':'
            h = %(<span class="header">#{name} #{n}#{separator} </span>)
            d = %(<span class="description">#{content}</span>)
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
            if node['cols']
              node['colspan'] = node['cols']
            end
          end
          doc.xpath('//table/row').each do |node|
            node.name = 'tr'
            klass = []
            if node['top-border'] == 'true'
              klass << 'top_border'
              clean_node node, %w[top-border]
            end
            if node['bottom-border'] == 'true'
              klass << 'bottom_border'
              clean_node node, %w[bottom-border]
            end
            node['class'] = klass.join(' ') unless klass.empty?
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
              if custom_alignment?(cell)
                cell['class'] = custom_class(cell)
              else
                cell['class'] = alignment_class(alignment)
              end
              clean_node cell, %w[halign right-border left-border cols]
            end
          end
        end

        # Returns true if the cell comes with custom alignment.
        # This is the case with a multicolumn row.
        def custom_alignment?(cell)
          cell['cols']
        end

        # Returns the custom class for a cell.
        def custom_class(cell)
          [].tap do |klass|
            klass << 'left_border' if cell['left-border']
            klass << "align_#{cell['halign']}" if cell['halign']
            klass << 'right_border' if cell['right-border']
            klass << 'top-border' if cell['top-border']
          end.join(' ')
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
        def trim_empty_paragraphs!(string)
          string.gsub!(/<p>\s*<\/p>/m, '')
        end

        # Restores quotes or verse inside figure.
        # This is a terrible hack.
        def restore_figure_quotes!(string)
          figure_quote_cache.each do |key, html|
            string.gsub!(/<p>\s*#{key}\s*<\/p>/m, html)
          end
        end

        # Retores literal HTML included via %=.
        # E.g., writing
        #    %= </span>
        # inserts a literal closing span tag into the HTML output.
        def restore_literal_html!(string)
          literal_html_cache.each do |key, html|
            string.gsub!(/<p>\s*<literalhtml>#{key}<\/literalhtml>\s*<\/p>/m,
                         html)
            string.gsub!(/<literalhtml>#{key}<\/literalhtml>/, html)
          end
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
            trim_empty_paragraphs!(html)
            restore_figure_quotes!(html)
            restore_literal_html!(html)
          end
        end

        # Handles table of contents (if present).
        # This code could no doubt be made much shorter, but probably at the
        # cost of clarity.
        def table_of_contents(doc)
          toc = doc.at_css('tableofcontents')
          return if toc.nil?
          label = language_labels["contents"]
          toc.add_previous_sibling(%(<h1 class="contents">#{label}</h1>))
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
            when 'chapter-star'
              html << '<ul>' if current_depth == 0
              while current_depth > 1
                close_list(html)
                current_depth -= 1
              end
              current_depth = 1
              insert_li(html, node)
            when 'section'
              html << '<ul>' if article? && current_depth == 0
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
