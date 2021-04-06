FactoryBot.define do
  factory :platform do
    public_name {"All"}
    internal_name {"all"}
    webrep {true}
    emailrep {true}
    webcat {true}
    filerep {true}
    active {true}
  end

  trait :webrep do
    public_name {"Webrep"}
    internal_name {"webrep"}
    webrep {true}
    emailrep {false}
    webcat {false}
    filerep {false}
    active {true}
  end

  trait :emailrep do
    public_name {"Emailrep"}
    internal_name {"webrep"}
    webrep {false}
    emailrep {true}
    webcat {false}
    filerep {false}
    active {true}
  end

  trait :webcat do
    public_name {"Webcat"}
    internal_name {"webcat"}
    webrep {false}
    emailrep {false}
    webcat {true}
    filerep {false}
    active {true}
  end

  trait :filerep do
    public_name {"Filerep"}
    internal_name {"filerep"}
    webrep {false}
    emailrep {false}
    webcat {false}
    filerep {true}
    active {true}
  end

  trait :inactive do
    public_name {"Inactive"}
    internal_name {"inactive"}
    webrep {true}
    emailrep {true}
    webcat {true}
    filerep {true}
    active {false}
  end
end