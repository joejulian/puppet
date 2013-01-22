require 'puppet'
require 'spec_helper'
require 'puppet_spec/compiler'

describe 'the select method' do
  include PuppetSpec::Compiler

  before :each do
    node      = Puppet::Node.new("floppy", :environment => 'production')
    @compiler = Puppet::Parser::Compiler.new(node)
    @scope    = Puppet::Parser::Scope.new(@compiler)
    @topscope = @scope.compiler.topscope
    @scope.parent = @topscope
  end

  context "should be callable as" do
    it 'select on an array (all berries)' do
      catalog = compile_to_catalog(<<-MANIFEST)
        $a = ['strawberry','blueberry','orange']
        $a.select {|$x| = $x  =~ /berry$/}.foreach {|$v| 
          file { "/file_$v": ensure => present }
        }
      MANIFEST

      catalog.resource(:file, "/file_strawberry")['ensure'].should == 'present'
      catalog.resource(:file, "/file_blueberry")['ensure'].should == 'present'
    end    
  end
end
