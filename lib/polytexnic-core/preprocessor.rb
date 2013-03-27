# encoding=utf-8
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
      system("#{tralics} -nomathml #{file.path} > /dev/null")
      dirname = File.dirname(file.path)
      xml_filename = File.basename(file.path, '.tex') + '.xml'
      raw_xml = File.read(File.join(dirname, xml_filename))
      xml = Nokogiri::XML(raw_xml).at_css('p').to_xml

      @xml = xml
    ensure
      file.unlink
    end

    def digest(string)
      Digest::SHA1.hexdigest(string)
    end

    def preprocess_polytex
      polytex = @polytex
      output = []
      lines = polytex.split("\n")
      while (line = lines.shift)
        if line =~ /^\s*\\begin{verbatim}\s*$/
          output << xmlelement(:verbatim) do
            verbatim_count = 1
            verbatim_text = []
            while (line = lines.shift)
              if line =~ /^\s*\\begin{verbatim}\s*$/
                verbatim_count += 1
              elsif line =~ /^\s*\\end{verbatim}\s*$/
                verbatim_count -= 1
                break if verbatim_count == 0
              end
              verbatim_text << line if verbatim_count > 0
            end
            raise 'Missing \end{verbatim}' if verbatim_count != 0
            content = verbatim_text.join("\n")
            key = self.digest(content)
            @verbatim_cache[key] = content
            key
          end
        else
          output << line
        end
      end
      # puts output.join("\n")
      output.join("\n")
    end

    def xmlelement(name)
      output = "\\begin{xmlelement}{#{name}}"
      output << yield if block_given?
      output << "\\end{xmlelement}"
    end


  end
end