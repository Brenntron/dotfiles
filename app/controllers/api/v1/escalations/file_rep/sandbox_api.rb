module API
  module V1
    module Escalations
      module FileRep
        class SandboxApi < Grape::API
          include API::V1::Defaults
          include API::BugzillaRestSession

          resource "escalations/file_rep/sandbox_api" do
            before do
              PaperTrail.request.whodunnit = current_user.id if current_user.present?
            end
            desc ''
            params do
              requires :sha256_hash, type: String, desc: "SHA256 hash"
            end
            get "/sandbox_score/:sha256_hash" do
              api_response = FileReputationApi::Sandbox.sandbox_score(params[:sha256_hash])
              render json: api_response
            end

            desc ''
            params do
              requires :sha256_hash, type: String, desc: "SHA256 hash"
            end
            get "/sandbox_disposition/:sha256_hash" do
              api_response = FileReputationApi::Sandbox.sandbox_disposition(params[:sha256_hash])
              render json: api_response
            end

            desc ''
            params do
              requires :sha256_hash, type: String, desc: "SHA256 hash"
            end
            get "/sandbox_latest_report/:sha256_hash" do
              api_response = FileReputationApi::Sandbox.sandbox_latest_report(params[:sha256_hash])
              render json: api_response
            end

            desc ''
            params do
              requires :sha256_hash, type: String, desc: "SHA256 hash"
              requires :run_id, type: Integer, desc: "Run ID for a given sha256"
            end
            get "/sandbox_report/:run_id/:sha256_hash" do
              sha256_hash = params[:sha256_hash]
              api_response = FileReputationApi::Sandbox.full_report(sha256_hash, params[:run_id])

              begin
                sandbox_score = api_response[:data]['score']
                FileReputationDispute.where(sha256_hash: sha256_hash).update_all(sandbox_score: sandbox_score)
              rescue => except
                Rails.logger.error("Error updating sandbox score for sha256 hash #{sha256_hash} -- #{except.error_message}")
              end

              render json: api_response
            end

            desc ''
            params do
              requires :sha256_hash, type: String, desc: "SHA256 hash"
              requires :run_id, type: Integer, desc: "Run ID for a given sha256"
            end
            get "/sandbox_report_html/:run_id/:sha256_hash" do
              api_response = FileReputationApi::Sandbox.full_report_html(params[:sha256_hash], params[:run_id])
              # render json: api_response
              file_contents = api_response[:data].body.force_encoding("ISO-8859-1").encode("UTF-8")
              return file_contents
              # html_file = File.new("sandbox.html", "w")
              # html_file.puts(file_contents)
              # html_file.close

              # # send_file 'sandbox.html'
              #
              # data = file_contents
              # file = "my_file.txt"
              # File.open(file, "w"){ |f| f << data }
              # send_data( data )


              # send_data file_contents, :filename => "sandbox_report.html", disposition: 'attachment'


                # send_data file_contents.to_s, filename: "sandbox_html_#{Time.now}.html", disposition: 'attachment'

              # send_data html_file.stream.string, filename: "sandbox_report-#{Time.now}.html", disposition: 'attachment'



                #
              # html_file = File.new("sample.html", "w")
              # html_file.puts(file_contents)
              # html_file.close
              #
              # #Attachment name
              # filename = 'sandbox_report.zip'
              # temp_file = Tempfile.new(filename)
              #
              # begin
              #   #This is the tricky part
              #   #Initialize the temp file as a zip file
              #   Zip::OutputStream.open(temp_file) { |zos| }
              #
              #   #Add files to the zip file as usual
              #   Zip::File.open(temp_file.path, Zip::File::CREATE) do |zip|
              #     #Put files in here
              #     zip.add("sandbox_report.html", html_file)
              #   end
              #
              #   #Read the binary data from the file
              #   zip_data = File.read(temp_file.path)
              #
              #   #Send the data to the browser as an attachment
              #   #We do not send the file directly because it will
              #   #get deleted before rails actually starts sending it
              #   send_data(zip_data, :type => 'application/zip', :filename => filename)
              # ensure
              #   #Close and delete the temp file
              #   temp_file.close
              #   temp_file.unlink
              # end



            end
          end
        end
      end
    end
  end
end
