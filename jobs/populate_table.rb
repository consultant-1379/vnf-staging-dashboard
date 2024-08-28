require 'yaml'
ROW_LIMIT = 5

SCHEDULER.every '1m', :first_in => '5s' do
  populate_table
end

def populate_table
  data = YAML.load_file("data/data.yaml")
  hrows = get_table_headers
  rows = get_row_information(data)
  send_event('my-table', { hrows: hrows, rows: rows } )
end

def get_table_headers
  headerRow = [
      { cols: [
          {value: 'Date'},
          {value: 'Versions (Dummy versions)'},
          {value: 'SBG'},
          {value: 'BGF'},
          {value: 'MTAS'},
          {value: 'CSCF'}
      ]}
  ]
  return headerRow
end

def get_row_information(data)
  rows = []
  counter = 0
  data_reversed = data.reverse
  data_reversed.each do |col|
    if counter == ROW_LIMIT
      break
    else
      row = {
          cols: [
              {value: col["Date"]},
              ### CREATE F0RMATTER FOR THIS ###
              {value:
                  "<b>ECM:</b> " + col["Versions"][0]["ecmVersion"] + "<br/>" +
                  "<b>LCM:</b> " + col["Versions"][0]["lcmVersion"] + "<br/>" +
                  "<b>SO:</b> "  + col["Versions"][0]["soVersion"]
              },
              {value: col["SBG"]},
              {value: col["BGF"]},
              {value: col["MTAS"]},
              {value: col["CSCF"]}
          ]
      }
      rows.push(row)
      counter += 1
    end
  end
  return rows
end