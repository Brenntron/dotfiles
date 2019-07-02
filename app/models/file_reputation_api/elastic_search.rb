require 'elasticsearch'
require 'hashie'

class FileReputationApi::ElasticSearch

  def self.query(sha256)
    client = Elasticsearch::Client.new hosts: [
        { host: Rails.configuration.elastic.host,
          port: Rails.configuration.elastic.port,
          user: Rails.configuration.elastic.username ,
          password: Rails.configuration.elastic.password,
          scheme: 'https'
        }], log: true, transport_options: { ssl: { verify: false}}


    begin
      response = client.search index: 'pokes', size: 1,
                               body: {
                                   query: {
                                       bool: {
                                           must: [
                                                    { term: {hash: sha256}},
                                                    ],
                                           should: [],
                                           must_not: [
                                               term: { mode: 'fetch'}
                                           ]
                                       }
                                   },
                                   sort: {
                                       time: { order: 'desc'},
                                   }
                               }


      disposition_last_set = Time.at(response['hits']['hits'][0]['_source']['time'])

      disposition_last_set.utc.strftime("%b %e, %Y %l:%M %p")
    rescue
      return 'No history to display'
    end
  end

  def self.get_history(sha256)
    client = Elasticsearch::Client.new hosts: [
        { host: Rails.configuration.elastic.host,
          port: Rails.configuration.elastic.port,
          user: Rails.configuration.elastic.username ,
          password: Rails.configuration.elastic.password,
          scheme: 'https'
        }], log: true, transport_options: { ssl: { verify: false}}


    begin
      response = client.search index: 'pokes', size: 1000,
                               body: {
                                   query: {
                                       bool: {
                                           must: [
                                               { term: {hash: sha256}},
                                           ],
                                           should: [],
                                           must_not: [
                                               term: { mode: 'fetch'}
                                           ]
                                       }
                                   },
                                   sort: {
                                       time: { order: 'desc'},
                                   }
                               }



      history = response['hits']['hits']

      history
    rescue
      return 'No history to display'
    end
  end

end