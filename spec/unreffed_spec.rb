# The classes below were not being loaded,
# so our test coverage was invalid
#
# The code below loads those classes to correct for this.

describe Admin::HomeController
describe Admin::MigrationsController

describe EventsController
describe ReferencesController
describe RolesController

describe ApiTest::EngineTypesController
describe ApiTest::EnginesController
describe ApiTest::JobsController
describe ApiTest::PcapsController
describe ApiTest::RuleConfigurationsController
describe ApiTest::SnortConfigurationsController

describe Repo::RuleCommitter
describe RuleEvent::RuleCommitEvent
describe RuleSyntax::Metadata

