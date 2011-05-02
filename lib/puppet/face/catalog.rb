require 'puppet/indirector/face'

Puppet::Indirector::Face.define(:catalog, '0.0.1') do
  copyright "Puppet Labs", 2011
  license   "Apache 2 license; see COPYING"

  summary "Compile, save, view, and convert catalogs."

  description <<-EOT
This face primarily interacts with the compiling subsystem.
By default, it compiles a catalog using the default manifest and the
hostname from 'certname', but you can choose to retrieve a catalog from
the server by specifying '--from rest'.  You can also choose to print any
catalog in 'dot' format (for easy graph viewing with OmniGraffle or Graphviz)
with '--format dot'.
  EOT

  action(:apply) do
    summary "apply a Puppet::Resource::Catalog object"

    when_invoked do |catalog, options|
      report = Puppet::Transaction::Report.new("apply")
      report.configuration_version = catalog.version

      Puppet::Util::Log.newdestination(report)

      begin
        benchmark(:notice, "Finished catalog run") do
          catalog.apply(:report => report)
        end
      rescue => detail
        puts detail.backtrace if Puppet[:trace]
        Puppet.err "Failed to apply catalog: #{detail}"
      end

      report.finalize_report
      report
    end
  end

  action(:download) do
    summary "download the catalog given the certname and facts"

    when_invoked do |certname, facts, options|
      Puppet::Resource::Catalog.indirection.terminus_class = :rest
      facts_to_upload = {:facts_format => :b64_zlib_yaml, :facts => CGI.escape(facts.render(:b64_zlib_yaml))}
      catalog = nil
      retrieval_duration = thinmark do
        catalog = Puppet::Face[:catalog, '0.0.1'].find(certname, facts_to_upload)
      end
      catalog = catalog.to_ral
      catalog.finalize
      catalog.retrieval_duration = retrieval_duration
      catalog.write_class_file
      catalog
    end
  end
end