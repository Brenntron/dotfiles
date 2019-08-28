FactoryBot.define do
  factory :amp_naming_convention do
    pattern                         {"Pattern"}
    example                         {"Example"}
    engine                          {"Engine"}
    engine_description              {"Engine Description"}
    notes                           {"Notes"}
    public_notes                    {"Public Notes"}
    contact                         {"Contact"}
    table_sequence                  {1}
  end
end