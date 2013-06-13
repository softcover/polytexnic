# encoding=utf-8
require 'spec_helper'

describe 'Polytexnic::Core::Pipeline#to_html' do

  let(:processed_text) { Polytexnic::Core::Pipeline.new(polytex).to_html }
  subject { processed_text }

  describe "tabular environment" do

    context "simple table with centered elements" do

      let(:polytex) do <<-'EOS'
        \begin{tabular}{cc}
        HTTP request & URL \\
        GET & /users \\
        GET & /users/1
        \end{tabular}
      EOS
      end

      it do
        should resemble <<-'EOS'
          <table><tr><td class="halign-center">HTTP request</td>
          <td class="halign-center">URL</td>
          </tr><tr><td class="halign-center">GET</td>
          <td class="halign-center">/users</td>
          </tr><tr><td class="halign-center">GET</td>
          <td class="halign-center">/users/1</td>
          </tr></table>
        EOS
      end
    end

    context "more complicated left-aligned cells with hlines" do
      let(:polytex) do <<-'EOS'
        \begin{tabular}{llll}
        HTTP request & URL & Action & Purpose \\ \hline

        GET & /users & index & page to list all users \\
        GET & /users/1 & show & page to show user with id 1\\
        GET & /users/new & new & page to make a new user \\
        POST & /users & create & create a new user \\
        GET & /users/1/edit & edit & page to edit user with id 1 \\
        PATCH & /users/1 & update & update user with id 1  \\
        DELETE & /users/1 & destroy & delete user with id 1
        \end{tabular}
      EOS
      end

      it do
        should resemble <<-'EOS'
          <table><tr class="bottom-border">
          <td class="halign-left">HTTP request</td>
          <td class="halign-left">URL</td>
          <td class="halign-left">Action</td>
          <td class="halign-left">Purpose</td>
          </tr><tr><td class="halign-left">GET</td>
          <td class="halign-left">/users</td>
          <td class="halign-left">index</td>
          <td class="halign-left">page to list all users</td>
          </tr><tr><td class="halign-left">GET</td>
          <td class="halign-left">/users/1</td>
          <td class="halign-left">show</td>
          <td class="halign-left">page to show user with id 1</td>
          </tr><tr><td class="halign-left">GET</td>
          <td class="halign-left">/users/new</td>
          <td class="halign-left">new</td>
          <td class="halign-left">page to make a new user</td>
          </tr><tr><td class="halign-left">POST</td>
          <td class="halign-left">/users</td>
          <td class="halign-left">create</td>
          <td class="halign-left">create a new user</td>
          </tr><tr><td class="halign-left">GET</td>
          <td class="halign-left">/users/1/edit</td>
          <td class="halign-left">edit</td>
          <td class="halign-left">page to edit user with id 1</td>
          </tr><tr><td class="halign-left">PATCH</td>
          <td class="halign-left">/users/1</td>
          <td class="halign-left">update</td>
          <td class="halign-left">update user with id 1</td>
          </tr><tr><td class="halign-left">DELETE</td>
          <td class="halign-left">/users/1</td>
          <td class="halign-left">destroy</td>
          <td class="halign-left">delete user with id 1</td>
          </tr></table>
        EOS
      end
    end
  end
end