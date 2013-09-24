# encoding=utf-8
require 'spec_helper'

describe 'Polytexnic::Core::Pipeline#to_html' do

  let(:processed_text) { Polytexnic::Core::Pipeline.new(polytex).to_html }
  subject { processed_text }

  describe '\chapter' do
    let(:polytex) do <<-'EOS'
        \tableofcontents
        \chapter{Foo}
        \label{cha:foo}

        \section{Bar}
        \label{sec:bar}

        \subsection{Baz}
        \label{sec:baz}

        \chapter{Lorem}
        \label{cha:lorem}

      EOS
    end
    subject(:toc) do
      Nokogiri::HTML(processed_text).css('div#table_of_contents')
    end

    it { should_not be_empty }

    it "should have a 'depth' attribute" do
      expect(toc.first['depth']).to be_nil
    end

    it "should have a link to the first chapter" do
      expect(toc.css('li>a')[0]['href']).to eq '#cha-foo'
    end

    it "should have a link to the first section" do
      expect(toc.css('li>a')[1]['href']).to eq '#sec-bar'
    end

    it "should have a link to the second chapter" do
      expect(toc.css('li>a')[2]['href']).to eq '#cha-lorem'
    end
  end
end