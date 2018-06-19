describe SnortDocPublisher do
  let(:cve_year) { 2015 }
  let(:reference) do
    FactoryGirl.create(:cve_reference, year: cve_year, index: 200, fail_count: 0)
  end
  let(:url_reference_type) do
    FactoryGirl.create(:url_reference_type)
  end
  let(:cve_file_content) do
    {
      "CVE_data_type" => "CVE",
      "CVE_data_format" => "MITRE",
      "CVE_data_version" => "4.0",
      "CVE_data_numberOfCVEs" => "7980",
      "CVE_data_timestamp" => "2018-06-08T07:16Z",
      "CVE_Items" => [
        {
          "cve" => {
            "data_type" => "CVE",
            "data_format" => "MITRE",
            "data_version" => "4.0",
            "CVE_data_meta" => {
                "ID" => "CVE-2015-0200",
                "ASSIGNER" => "cve@mitre.org"
            },
            "affects" => {
              "vendor" => {
                "vendor_data" => [
                  {
                    "vendor_name" => "ibm",
                    "product" => {
                      "product_data" => [
                        {
                          "product_name" => "websphere_commerce",
                          "version" => {
                            "version_data" => [
                              {
                                  "version_value" => "6.0"
                              }, {
                                  "version_value" => "7.0.0.6"
                              }, {
                                  "version_value" => "7.0.0.7"
                              }, {
                                  "version_value" => "7.0.0.8"
                              }
                            ]
                          }
                        }
                      ]
                    }
                  }
                ]
              }
            },
            "problemtype" => {
              "problemtype_data" => [
                {
                  "description" => [
                    {
                        "lang" => "en",
                        "value" => "CWE-200"
                    }
                  ]
                }
              ]
            },
            "references" => {
              "reference_data" => [
                {
                    "url" => "http=>//www-01.ibm.com/support/docview.wss?uid=swg1JR50683",
                    "name" => "JR50683",
                    "refsource" => "AIXAPAR"
                }, {
                    "url" => "http://www-01.ibm.com/support/docview.wss?uid=swg1JR52306",
                    "name" => "JR52306",
                    "refsource" => "AIXAPAR"
                }, {
                    "url" => "http://www-01.ibm.com/support/docview.wss?uid=swg21902799",
                    "name" => "http://www-01.ibm.com/support/docview.wss?uid=swg21902799",
                    "refsource" => "CONFIRM"
                }, {
                    "url" => "http://www.securitytracker.com/id/1032392",
                    "name" => "1032392",
                    "refsource" => "SECTRACK"
                }
              ]
            },
            "description" => {
              "description_data" => [
                {
                    "lang" => "en",
                    "value" => "IBM WebSphere Commerce 6.x through 6.0.0.11 and 7.x before 7.0.0.8 IF2 allows local users to obtain sensitive database information via unspecified vectors."
                }
              ]
            }
          },
          "configurations" => {
            "CVE_data_version" => "4.0",
            "nodes" => [
              {
                "operator" => "OR",
                "cpe" => [
                  {
                      "vulnerable" => true,
                      "cpe22Uri" => "cpe:/a:ibm:websphere_commerce:6.0",
                      "cpe23Uri" => "cpe:2.3:a:ibm:websphere_commerce:6.0:*:*:*:*:*:*:*"
                  }, {
                      "vulnerable" => true,
                      "cpe22Uri" => "cpe:/a:ibm:websphere_commerce:7.0.0.7",
                      "cpe23Uri" => "cpe:2.3:a:ibm:websphere_commerce:7.0.0.7:*:*:*:*:*:*:*"
                  }, {
                      "vulnerable" => true,
                      "cpe22Uri" => "cpe:/a:ibm:websphere_commerce:7.0.0.8",
                      "cpe23Uri" => "cpe:2.3:a:ibm:websphere_commerce:7.0.0.8:*:*:*:*:*:*:*"
                  }
                ]
              }
            ]
          },
          "impact" => {
            "baseMetricV2" => {
              "cvssV2" => {
                  "version" => "2.0",
                  "vectorString" => "(AV:L/AC:L/Au:N/C:P/I:N/A:N)",
                  "accessVector" => "LOCAL",
                  "accessComplexity" => "LOW",
                  "authentication" => "NONE",
                  "confidentialityImpact" => "PARTIAL",
                  "integrityImpact" => "NONE",
                  "availabilityImpact" => "NONE",
                  "baseScore" => 2.1
              },
              "severity" => "LOW",
              "exploitabilityScore" => 3.9,
              "impactScore" => 2.9,
              "obtainAllPrivilege" => false,
              "obtainUserPrivilege" => false,
              "obtainOtherPrivilege" => false,
              "userInteractionRequired" => false
            }
          },
          "publishedDate" => "2015-05-29T15:59Z",
          "lastModifiedDate" => "2016-12-31T02:59Z"
        }
      ]
    }.to_json
  end



  ### TESTS ####################################################################

  it 'downloads all the NVD files' do
    reference
    expect(SnortDocPublisher).to receive(:download_file).with('nvdcve-1.0-2015.json')
    expect(SnortDocPublisher).to receive(:download_file).with('nvdcve-1.0-modified.json')
    expect(SnortDocPublisher).to receive(:download_file).with('nvdcve-1.0-recent.json')

    SnortDocPublisher.download_all

  end

  it 'updates cve data' do
    reference
    url_reference_type
    allow(File).to receive(:exists?).and_return(true)
    allow(File).to receive(:open).and_return(cve_file_content)
    allow(SnortDocPublisher).to receive(:modified_nvd_cve_items).and_return([])
    allow(SnortDocPublisher).to receive(:recent_nvd_cve_items).and_return([])

    SnortDocPublisher.update_cve_data do |errors|
      expect(errors.count).to eql(0)
    end

    expect(SnortDocPublisher.errors.count).to eql(0)
    expect(Cve.count).to eql(1)
  end
end
