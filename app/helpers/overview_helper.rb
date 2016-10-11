module OverviewHelper

  def find_exploit_link(references)
    types = ExploitType.all.select(:id,:name)
    exploits=Hash.new {|h,k| h[k] = [] }
    references.each do |ref|
      ref.exploits.each do |exploit|
        exploits[types[exploit.exploit_type_id-1].name] << [exploit.id, exploit.data, exploit.attachment]
      end
    end
    render "bugs/tabs/exploits", exploits: exploits
  end
  def findExploitHTML(data)
    exploit_split = data.split(/(?i)\b((?:https?:(?:\/{1,3}|[a-z0-9%])|[a-z0-9.\-]+[.](?:com|net|org|edu|gov)\/)(?:[^\s()<>{}\[\]]+|\([^\s()]*?\([^\s()]+\)[^\s()]*?\)|\([^\s]+?\))+(?:\([^\s()]*?\([^\s()]+\)[^\s()]*?\)|\([^\s]+?\)|[^\s`!()\[\]{};:'".,<>?«»“”‘’])|(?:(?<!@)[a-z0-9]+(?:[.\-][a-z0-9]+)*[.](?:com|net|org|edu|gov)\b\/?(?!@)))/)
    render "bugs/tabs/links", data:exploit_split
  end
end