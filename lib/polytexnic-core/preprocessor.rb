# encoding=utf-8
require 'securerandom'

module Polytexnic
  module Preprocessor

    def preprocess
      to_xml
    end

    def to_xml
      tralics = `which tralics`.strip
      file = Tempfile.new(['polytex', '.tex'])
      file.write preprocess_polytex
      file.close
      Dir.mkdir 'log' unless File.directory?('log')
      system("#{tralics} -nomathml #{file.path} > log/tralics.log")
      dirname = File.dirname(file.path)
      xml_filename = File.basename(file.path, '.tex') + '.xml'
      raw_xml = clean_xml File.read(File.join(dirname, xml_filename))
      doc = Nokogiri::XML(raw_xml)
      add_document_tag(doc)
      @xml = doc.to_xml
    ensure
      xmlfile = file.path.sub('.tex', '.xml')
      logfile = file.path.sub('.tex', '.log')
      [xmlfile, logfile].each do |file|
        File.delete(file) if File.exist?(file)
      end
      file.delete
    end

    # Wrap the whole document in <document></document>.
    # Fragmentary documents come wrapped in 'unknown' tags.
    # Full documents are wrapped in 'std' tags.
    # Change either to 'document'.
    def add_document_tag(doc)
      %w[unknown std].each do |parent_tag|
        node = doc.at_css(parent_tag)
        node.name = 'document' unless node.nil?
      end
    end

    # Returns a salted hash digest of the string.
    def digest(string)
      Digest::SHA1.hexdigest(SecureRandom.base64 + string)
    end

    def preprocess_polytex
      polytex = @polytex
      output = []
      lines = polytex.split("\n")
      handle_literal_environments(lines, output)

      output = output.join("\n")

      # handle title fields
      %w{title subtitle author date}.each do |field|
        output.gsub! /\\#{field}\{(.*?)\}/ do |s|
          Polytexnic.instance_variable_set "@#{field}", $1
          ''
        end
      end

      output.gsub! /\\maketitle/ do |s|
        xmlelement('maketitle')
      end

      output.gsub! /\\chapter\{(.*?)\}/ do |s|
        xmlelement('chapter'){ $1 }
      end

      output
    end

    def xmlelement(name)
      output = "\\begin{xmlelement}{#{name}}"
      output << yield if block_given?
      output << "\\end{xmlelement}"
    end

    def clean_xml(raw_xml)
      nokogiri_ellipsis_workaround(raw_xml)
    end

    # Fixes a Nokogiri bug.
    # As of this writing, the latest version of Nokogiri (1.5.6) doesn't
    # handle the horizontal ellipsis character '&#133;' correctly in Ruby 2.0.
    # The kludgy solution is to replace it with '…' in the raw XML,
    # which does work.
    def nokogiri_ellipsis_workaround(raw_xml)
      raw_xml.gsub('&#133;', '…')
    end

    # Handles environments that should be passed through the pipeline intact.
    # The includes verbatim environments ('verbatim', 'Verbatim') and all the
    # equation environments handled by MathJax ('equation', 'align', etc.).
    # We take care to keep count of the number of begins we see so that the
    # code handles nested environments correctly; i.e.,
    #   \begin{verbatim}
    #     \begin{verbatim}
    #     \emph{foo bar}
    #     \end{verbatim}
    #   \end{verbatim}
    #   lorem ipsum
    # gets includes the internal literal text without accidentally grabbing the
    # 'lorem ipsum' at the end.
    def handle_literal_environments(lines, output)
      language = nil
      while (line = lines.shift)
        if line =~ /%=\s+lang:(\w+)/
          language = $1
        elsif line.begin_literal?
          literal_type = line.literal_type
          output << xmlelement(element(literal_type)) do
            count = 1
            text = []
            text << line if line.math_environment?
            while (line = lines.shift)
              if line.begin_literal?
                count += 1
              elsif line.end_literal?(literal_type)
                count -= 1
                if count == 0
                  text << line if line.math_environment?
                  break
                end
              end
              text << line
            end
            raise "Missing \\end{#{line.literal_type}}" if count != 0
            content = text.join("\n")
            key = digest(content)
            if language.nil?
              literal_cache[key] = content
              tag = 'literal'
            else
              code_cache[key] = [content, language]
              tag = 'code'
            end
            xmlelement(tag) { key }
          end
          language = nil
          output << '' # To force the next element to be a paragraph
        else
          output << line
        end
      end
    end

    def element(literal_type)
      if math_environments.include?(literal_type)
        'equation'
      else
        literal_type
      end
    end
  end
end

def math_environments
  %w[align align* alignat alignat* aligned array
     Bmatrix bmatrix cases
     eqnarray eqnarray* equation equation*
     gather gather* gathered
     matrix multline multline*
     pmatrix smallmatrix split subarray
     Vmatrix vmatrix
    ]
end

def math_environment_regex
  math_environments.map { |s| Regexp.escape(s) }.join('|')
end

class String

  def begin_literal?
    match(/^\s*\\begin{#{literal}}\s*$/)
  end

  def end_literal?(literal_type)
    match(/^\s*\\end{#{Regexp.escape(literal_type)}}\s*$/)
  end

  # Returns the type of literal environment.
  # '\begin{verbatim}' => 'verbatim'
  # '\begin{equation}' => 'equation'
  def literal_type
    # raise scan(/\\begin{(.*?)}/).flatten.first.inspect
    scan(/\\begin{(.*?)}/).flatten.first
  end

  def math_environment?
    match(/(?:#{math_environment_regex})/)
  end

  private

    # Returns a string matching the supported literal environments.
    def literal
      "(?:verbatim|Verbatim|#{math_environment_regex}|code)"
    end
end