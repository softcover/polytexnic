# encoding=utf-8
require 'spec_helper'

describe 'Polytexnic::Pipeline#to_html' do

  subject(:processed_text) { Polytexnic::Pipeline.new(polytex).to_html }

  describe "tabular environments" do

    context "simple table with centered elements" do

      let(:polytex) do <<-'EOS'
        \begin{tabular}{cc}
        \hline
        HTTP request & URL \\
        \hline
        GET & /users \\
        GET & /users/1
        \end{tabular}
      EOS
      end

      let(:output) do <<-'EOS'
        <table class="tabular">
        <tr class="top_border bottom_border"><td class="align_center">HTTP request</td>
        <td class="align_center">URL</td>
        </tr><tr><td class="align_center">GET</td>
        <td class="align_center">/users</td>
        </tr><tr><td class="align_center">GET</td>
        <td class="align_center">/users/1</td>
        </tr></table>
      EOS
      end

      it { should resemble output }

      context "longtable" do

        let(:polytex) do <<-'EOS'
          \begin{longtable}{cc}
          \hline
          HTTP request & URL \\
          \hline
          GET & /users \\
          GET & /users/1
          \end{longtable}
        EOS
        end

        it { should resemble output }
      end
    end

    context "more complicated left-aligned cells with lines" do
      let(:polytex) do <<-'EOS'
        \begin{tabular}{|l|lll|}
        \multicolumn{4}{|c|}{Cell spanning four columns} \\
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
          <table class="tabular">

            <tr>
            <td colspan="4" class="left_border align_center right_border">Cell spanning four columns</td>
            </tr>
            <tr class="bottom_border">
              <td class="left_border align_left right_border">HTTP request</td>
              <td class="align_left">URL</td>
              <td class="align_left">Action</td>
              <td class="align_left right_border">Purpose</td>
            </tr>
            <tr>
              <td class="left_border align_left right_border">GET</td>
              <td class="align_left">/users</td>
              <td class="align_left">index</td>
              <td class="align_left right_border">page to list all users</td>
            </tr>
            <tr>
              <td class="left_border align_left right_border">GET</td>
              <td class="align_left">/users/1</td>
              <td class="align_left">show</td>
              <td class="align_left right_border">page to show user with id 1</td>
            </tr>
            <tr>
              <td class="left_border align_left right_border">GET</td>
              <td class="align_left">/users/new</td>
              <td class="align_left">new</td>
              <td class="align_left right_border">page to make a new user</td>
            </tr>
            <tr>
              <td class="left_border align_left right_border">POST</td>
              <td class="align_left">/users</td>
              <td class="align_left">create</td>
              <td class="align_left right_border">create a new user</td>
            </tr>
            <tr>
              <td class="left_border align_left right_border">GET</td>
              <td class="align_left">/users/1/edit</td>
              <td class="align_left">edit</td>
              <td class="align_left right_border">page to edit user with id 1</td>
            </tr>
            <tr>
              <td class="left_border align_left right_border">PATCH</td>
              <td class="align_left">/users/1</td>
              <td class="align_left">update</td>
              <td class="align_left right_border">update user with id 1</td>
          </tr>
          <tr>
            <td class="left_border align_left right_border">DELETE</td>
            <td class="align_left">/users/1</td>
            <td class="align_left">destroy</td>
            <td class="align_left right_border">delete user with id 1</td>
          </tr>
        </table>
      EOS
      end
    end

    context "table whose border used to break for some reason" do
      let(:polytex) do <<-'EOS'
        \begin{tabular}{l|l|ll}
        DELETE & /users/1 & destroy & delete user with id 1
        \end{tabular}

        \begin{tabular}{|r|l|ll|}
        DELETE & /users/1 & destroy & delete user with id 1
        \end{tabular}
      EOS
      end

      it do
        should resemble <<-'EOS'
          <table class="tabular">
            <tr>
              <td class="align_left right_border">DELETE</td>
              <td class="align_left right_border">/users/1</td>
              <td class="align_left">destroy</td>
              <td class="align_left">delete user with id 1</td>
            </tr>
          </table>
          <table class="tabular">
            <tr>
              <td class="left_border align_right right_border">DELETE</td>
              <td class="align_left right_border">/users/1</td>
              <td class="align_left">destroy</td>
              <td class="align_left right_border">delete user with id 1</td>
            </tr>
          </table>
        EOS
      end
    end
  end

  describe "table environments" do

    context "with a label and a cross-reference" do
      let(:polytex) do <<-'EOS'
        \begin{table}
        \begin{tabular}{cc}
        HTTP request & URL \\
        GET & /users \\
        GET & /users/1
        \end{tabular}
        \label{table:foo}
        \end{table}

        Table~\ref{table:foo}
        EOS
      end

      it do
        should resemble <<-'EOS'
          <div id="table-foo" data-tralics-id="uid1" data-number="1" class="table">
          <table class="tabular"><tr><td class="align_center">HTTP request</td>
          <td class="align_center">URL</td>
          </tr><tr><td class="align_center">GET</td>
          <td class="align_center">/users</td>
          </tr><tr><td class="align_center">GET</td>
          <td class="align_center">/users/1</td>
          </tr></table>
            <div class="caption">
              <span class="header">Table 1</span>
            </div>
          </div>
          <p><a href="#table-foo" class="hyperref">Table <span class="ref">1</span></a></p>
        EOS
      end
    end

    context "with a caption" do
      let(:polytex) do <<-'EOS'
        \begin{table}
        \begin{tabular}{cc}
        HTTP request & URL \\
        GET & /users \\
        GET & /users/1
        \end{tabular}
        \caption{HTTP requests.}
        \end{table}
        EOS
      end

      it do
        should resemble <<-'EOS'
          <div id="uid1" data-tralics-id="uid1" data-number="1" class="table">
          <table class="tabular"><tr><td class="align_center">HTTP request</td>
          <td class="align_center">URL</td>
          </tr><tr><td class="align_center">GET</td>
          <td class="align_center">/users</td>
          </tr><tr><td class="align_center">GET</td>
          <td class="align_center">/users/1</td>
          </tr></table>
            <div class="caption">
              <span class="header">Table 1:</span>
              <span class="description">HTTP requests.</span>
            </div>
          </div>
        EOS
      end

      context "with a caption and a label" do
        let(:polytex) do <<-'EOS'
          \begin{table}
          \begin{tabular}{cc}
          HTTP request & URL \\
          GET & /users \\
          GET & /users/1
          \end{tabular}
          \caption{HTTP requests.\label{table:foo}}
          \end{table}

          Table~\ref{table:foo}
          EOS
        end

        it do
          should resemble <<-'EOS'
            <div id="table-foo" data-tralics-id="uid1" data-number="1" class="table">
            <table class="tabular"><tr><td class="align_center">HTTP request</td>
            <td class="align_center">URL</td>
            </tr><tr><td class="align_center">GET</td>
            <td class="align_center">/users</td>
            </tr><tr><td class="align_center">GET</td>
            <td class="align_center">/users/1</td>
            </tr></table>
              <div class="caption">
                <span class="header">Table 1: </span>
                <span class="description">HTTP requests.</span>
              </div>
            </div>
            <p><a href="#table-foo" class="hyperref">Table <span class="ref">1</span></a></p>
          EOS
        end
      end
    end
  end
end