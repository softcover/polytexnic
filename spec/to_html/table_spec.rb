# encoding=utf-8
require 'spec_helper'

describe 'Polytexnic::Core::Pipeline#to_html' do

  let(:processed_text) { Polytexnic::Core::Pipeline.new(polytex).to_html }
  subject { processed_text }

  describe "tabular environment" do
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
        <td class="align-left">HTTP request</cell>
        <td class="align-left">URL</cell>
        <td class="align-left">Action</cell>
        <td class="align-left">Purpose</cell>
        </row><tr><td class="align-left">GET</cell>
        <td class="align-left">/users</cell>
        <td class="align-left">index</cell>
        <td class="align-left">page to list all users</cell>
        </row><tr><td class="align-left">GET</cell>
        <td class="align-left">/users/1</cell>
        <td class="align-left">show</cell>
        <td class="align-left">page to show user with id 1</cell>
        </row><tr><td class="align-left">GET</cell>
        <td class="align-left">/users/new</cell>
        <td class="align-left">new</cell>
        <td class="align-left">page to make a new user</cell>
        </row><tr><td class="align-left">POST</cell>
        <td class="align-left">/users</cell>
        <td class="align-left">create</cell>
        <td class="align-left">create a new user</cell>
        </row><tr><td class="align-left">GET</cell>
        <td class="align-left">/users/1/edit</cell>
        <td class="align-left">edit</cell>
        <td class="align-left">page to edit user with id 1</cell>
        </row><tr><td class="align-left">PATCH</cell>
        <td class="align-left">/users/1</cell>
        <td class="align-left">update</cell>
        <td class="align-left">update user with id 1</cell>
        </row><tr><td class="align-left">DELETE</cell>
        <td class="align-left">/users/1</cell>
        <td class="align-left">destroy</cell>
        <td class="align-left">delete user with id 1</cell>
        </row></table>
      EOS
    end

  end

end