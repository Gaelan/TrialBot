ROLES = %i(escort vigilante consort investigator consigliere mayor
sherrif executioner mayor vigilante veteran mafioso lookout forger
amnesiac spy blackmailer jailor doctor disguiser serial_killer
bodyguard godfather arsonist medium janitor retributionist survivor
vampire_hunter witch framer vampire jester
)

def parse_role name
	names = {
		'esc' => :escort,
		'trans' => :transporter,
		'vig' => :vigilante,
		'inv' => :investigator,
		'consig' => :consigliere,
		'exe' => :executioner,
		'exec' => :executioner,
		'vet' => :veteran,
		'maf' => :mafioso,
		'lo' => :lookout,
		'amn' => :amnesiac,
		'amne' => :amnesiac,
		'bm' => :blackmailer,
		'doc' => :doctor,
		'disg' => :disguiser,
		'sk' => :serial_killer,
		'bg' => :bodyguard,
		'gf' => :godfather,
		'arso' => :arsonist,
		'med' => :medium,
		'ret' => :retributionist,
		'retri' => :retributionist,
		'surv' => :survivor,
		'vh' => :vampire_hunter,
		'vamp' => :vampire,
		'jest' => :jester,
		'jailer' => :jailor,
		'jail' => :jailor
	}

	names.merge!(Hash[ROLES.map {|name| [name.to_s, name]}])

	return names[name.downcase]
end

GROUPS = [
	[:escort, :transporter, :consort],
	[:investigator, :consigliere, :mayor],
	[:sherrif, :executioner, :werewolf],
	[:vigilante, :veteran, :mafioso],
	[:lookout, :forger, :amnesiac],
	[:spy, :blackmailer, :jailor],
	[:doctor, :disguiser, :serial_killer],
	[:bodyguard, :godfather, :arsonist],
	[:medium, :janitor, :retributionist],
	[:survivor, :vampire_hunter, :witch],
	[:framer, :vampire, :jester]
]

Bot.command :rolegroup do |event, role_name|
	role = parse_role role_name
	group = GROUPS.find { |group| group.include? role }.map(&:to_s).map(&:humanize)
	event.respond "**#{role.to_s.humanize}** is part of the group **#{group.join(', ')}.**"
end