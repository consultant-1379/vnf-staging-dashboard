require File.expand_path('../../lib/spinnaker', __FILE__)
require 'net/imap'
require 'mail'
require 'date'
require 'httparty'
require 'sanitize'
require 'yaml'
require 'time'

#Net::IMAP::debug = true

SPINNAKER_URL="https://spinnaker-api.rnd.gic.ericsson.se"
SPINNAKER_PIPELINE_ID = '5a01ef78-7891-41c9-b89a-b844148f2087'
SPINNAKER_PIPELINE_ID_TESTING ='89488c89-9328-4112-af5b-02b01be0798f'

SCHEDULER.every '1m', :first_in => '0s' do
  imap = Net::IMAP.new("outlook.office365.com", 993, ssl: true)
  begin
    imap.login("spinnaker-maintrack@outlook.com", "MTadmin123")
  rescue
    abort 'Authentication failed'
  end
  get_todays_emails(imap)
  imap.logout
  imap.disconnect
end

def get_todays_emails(imap)
  imap.select("inbox")
  today = Net::IMAP.format_date(Date.today)
  received_today = imap.search(["UNSEEN", "SINCE", today])

  received_today.each do |mail|
    raw_message = imap.fetch(mail, 'RFC822').first.attr['RFC822']
    message = Mail.read_from_string raw_message
    decoded_message = Sanitize.clean(message.body.decoded)

    data = YAML.load_file("data/data.yaml")

    check_for_new_day(today, data)
    update_data_in_yaml(decoded_message, data)
    versions = get_versions(data)
    populate_csv_file(today, decoded_message, versions)
  end
end

def check_for_new_day(today, data)
  # checking for new day and appending to yaml file
  data_data = data.last['Date']
  if not data_data.eql? today
    new_day = {
        "Date" => today.to_s,
        "Versions" => [{
            "ecmVersion" => "",
            "lcmVersion" => "",
            "soVersion" => ""
        }],
        "SBG" => 0,
        "BGF" => 0,
        "MTAS" => 0,
        "CSCF" => 0
    }
    data.push(new_day)
    File.open("data/data.yaml", "w+") {|file| file.write(YAML.dump(data))}
  end
end

def update_data_in_yaml(mail, data)
  node_type = mail.match(/(?<=Node=)[^\s]+/)

  # GET COUNT FROM YAML
  sbg_count = data.last['SBG'].to_i
  bgf_count = data.last['BGF'].to_i
  mtas_count = data.last['MTAS'].to_i
  cscf_count = data.last['CSCF'].to_i

  # CHECK NEW EMAIL NODE
  if node_type.to_s.eql? "SBG"
    sbg_count += 1
  elsif node_type.to_s.eql? "BGF"
    bgf_count += 1
  elsif node_type.to_s.eql? "MTAS"
    mtas_count += 1
  elsif node_type.to_s.eql? "CSCF"
    cscf_count += 1
  end

  # UPDATE COUNT
  data.last['SBG'] = sbg_count
  data.last['BGF'] = bgf_count
  data.last['MTAS'] = mtas_count
  data.last['CSCF'] = cscf_count

  # UPDATE YAML
  File.open("data/data.yaml", "w") {|file| file.write(YAML.dump(data))}
end

### USING HA PIPELINE FULL STACK PARRALEL TO GET VERSIONS FOR DEMO AND TESTING PURPOSES ###
def get_versions(data)
  spinnakerResponse = Spinnaker.source_json("#{SPINNAKER_URL}/executions?pipelineConfigIds=#{SPINNAKER_PIPELINE_ID_TESTING}&limit=1&statuses=Succeeded")
  unless spinnakerResponse[0].eql? nil
    processSpinnakerResponse(data, spinnakerResponse)
  end
end

def processSpinnakerResponse(data, spinnakerResponse)
  ecmReleaseVersion= Jenkins.release_from_ecm_artifacts_file(spinnakerResponse[0]["trigger"]["buildInfo"]["url"])
  lcmReleaseVersion = Jenkins.release_from_lcm_artifacts_file(spinnakerResponse[0]["stages"][1]["outputs"]["buildInfo"]["url"])
  soReleaseVersion = Jenkins.release_from_so_artifacts_file(spinnakerResponse[0]["stages"][6]["context"]["buildInfo"]["url"])

  ecmVersion = ecmReleaseVersion.match(/(?<=RELEASE=)[^\s]+/)
  lcmVersion = lcmReleaseVersion.match(/(?<=media_version=)[^\s]+/)
  soVersion = soReleaseVersion.match(/(?<=SO_VERSION:     )[^\s]+/)

  data.last["Versions"][0]["ecmVersion"] = ecmVersion.to_s
  data.last["Versions"][0]["lcmVersion"] = lcmVersion.to_s
  data.last["Versions"][0]["soVersion"] = soVersion.to_s

  File.open("data/data.yaml", "w") {|file| YAML.dump(data, file)}

  return "ECM: #{ecmVersion.to_s}", "LCM: #{lcmVersion.to_s}", "SO: #{soVersion.to_s}"
end

def populate_csv_file(today, mail, versions)
  # PULL RELEVANT INFORMATION FROM EMAIL
  node_type = mail.match(/(?<=Node=)[^\s]+/)
  build_status = mail.match(/(?<=Status=)[^\s]+/)
  node_version = mail.match(/(?<=Version=)[^\s]+/)
  workflow_version = mail.match(/(?<=WorkflowVersion=)[^\s]+/)

  # POPULATE THE CSV WITH RELEVANT INFORMATION
  CSV.open("data/data.csv", "a") do |csv|
    # CSCF HAS NODE AND WORKFLOW VERSION
    if node_type.to_s.eql? "CSCF"
      csv << [today, versions, node_type, node_version, workflow_version, build_status]
    else
      csv << [today, versions, node_type, node_version, nil, build_status]
    end
  end
end
