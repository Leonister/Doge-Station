/datum/event/abductor

/datum/event/abductor/start()
	//spawn abductor team
	processing = 0 //so it won't fire again in next tick
	if(!makeAbductorTeam())
		message_admins("O evento Abductor não conseguiu encontrar jogadores. Repetição em 30s.")
		spawn(300)
			makeAbductorTeam()

/datum/event/abductor/proc/makeAbductorTeam()
	var/list/mob/dead/observer/candidates = pollCandidates("Você deseja ser considerado para uma equipe de Abducção?", ROLE_ABDUCTOR, 1)

	if(candidates.len >= 2)
		//Oh god why we can't have static functions
		var/number =  ticker.mode.abductor_teams + 1

		var/datum/game_mode/abduction/temp
		if(ticker.mode.config_tag == "abduction")
			temp = ticker.mode
		else
			temp = new

		var/agent_mind = pick(candidates)
		candidates -= agent_mind
		var/scientist_mind = pick(candidates)

		var/mob/living/carbon/human/agent=makeBody(agent_mind)
		var/mob/living/carbon/human/scientist=makeBody(scientist_mind)

		agent_mind = agent.mind
		scientist_mind = scientist.mind

		temp.scientists.len = number
		temp.agents.len = number
		temp.abductors.len = 2*number
		temp.team_objectives.len = number
		temp.team_names.len = number
		temp.scientists[number] = scientist_mind
		temp.agents[number] = agent_mind
		temp.abductors |= list(agent_mind,scientist_mind)
		temp.make_abductor_team(number,preset_scientist=scientist_mind,preset_agent=agent_mind)
		temp.post_setup_team(number)

		ticker.mode.abductor_teams++

		if(ticker.mode.config_tag != "abduction")
			ticker.mode.abductors |= temp.abductors
		processing = 1 //So it will get gc'd
		return 1
	else
		return 0
