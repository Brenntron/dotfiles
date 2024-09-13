class Wbrs::ManualWlblSerializer < ActiveModel::Serializer
  attributes :id, :ctime, :list_type, :mtype, :state, :threat_cats, :url, :ursername
end
