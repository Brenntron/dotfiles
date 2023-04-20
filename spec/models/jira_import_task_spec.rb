describe JiraImportTask do
  describe '.export_xlsx' do
    let(:jira_import_task) { FactoryBot.create(:jira_import_task, issue_key: 'SD-1') }
    let!(:import_url) { FactoryBot.create(:import_url, jira_import_task: jira_import_task) }

    context 'when issue_keys parameter is empty' do
      it 'returns a sheet with all JiraImportTask records' do
        workbook = JiraImportTask.export_xlsx('')
        worksheet = workbook[0]
        expect(worksheet.sheet_data[0][0].value).to eq 'SUBMITTED_URL'
        expect(worksheet.sheet_data[1][0].value).to eq import_url.submitted_url
        expect(worksheet.sheet_data[1][1].value).to eq import_url.domain
        expect(worksheet.sheet_data[1][2].value).to eq jira_import_task.issue_key
        expect(worksheet.sheet_data[1][3].value).to eq jira_import_task.status
        expect(worksheet.sheet_data[1][4].value).to eq jira_import_task.submitter
        expect(worksheet.sheet_data[1][5].value).to eq jira_import_task.bast_task
        expect(worksheet.sheet_data[1][6].value).to eq jira_import_task.imported_at.utc.iso8601
      end

      context 'when workbook has multiple JiraImportTask records' do
        before do
          FactoryBot.create(:jira_import_task, :with_import_urls, issue_key: 'SD-2')
        end

        it 'returns amount of rows equal to the sum of all ImportUrl records' do
          # + 1 means that we have to add the header row
          expected_rows = ImportUrl.count + 1

          workbook = JiraImportTask.export_xlsx('')
          worksheet = workbook[0]
          expect(worksheet.sheet_data.size).to eq(expected_rows)
        end
      end

      it 'write correct headers' do
        sheet = JiraImportTask.export_xlsx('')[0]

        # iterate throught EXPORT_FIELD_NAMES to check sheet headers
        described_class::EXPORT_FIELD_NAMES.each_with_index do |field_name, index|
          expect(sheet[0][index].value).to eq field_name
        end
      end
    end

    context 'when issue_keys parameter is not empty' do
      let(:jira_import_task2) { FactoryBot.create(:jira_import_task, issue_key: 'SD-3') }
      let!(:import_url2) { FactoryBot.create(:import_url, jira_import_task: jira_import_task2) }
      
      it 'returns a sheet with only matching JiraImportTask records' do
        workbook = JiraImportTask.export_xlsx('SD-1')
        worksheet = workbook[0]
        # + 1 means that we have to add the header row
        expected_rows_amount = jira_import_task.import_urls.count + 1
        
        expect(worksheet.sheet_data[0][0].value).to eq 'SUBMITTED_URL'
      end

      context 'when there is JiraImportTask withouth ImportUrl records' do
        let(:jira_import_task) { FactoryBot.create(:jira_import_task, issue_key: 'SD-4')}

        it 'returns empty sheet' do
          workbook = JiraImportTask.export_xlsx('SD-7')
          worksheet = workbook[0]
          
          # 'to eq(1)' means that we have only header row
          expect(worksheet.sheet_data.size).to eq(1)
        end
      end
    end
  end
end
