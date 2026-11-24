extends PanelContainer

var agentHash : Agent

func render(agent : Agent):
	$VBoxContainer/Row1/NAME.text = agent.name
	$VBoxContainer/Row1/LV.text = "LV. " + str(agent.level)
	$VBoxContainer/HPBAR.max_value = agent._HPHash
	$VBoxContainer/HPBAR.value = agent.HP
	agentHash = agent

func _process(delta):
	if agentHash:
		#print(agentHash," ", agentHash.HP, " - ", agentHash._HPHash)
		$VBoxContainer/HPBAR.value = lerp($VBoxContainer/HPBAR.value,agentHash.HP,delta * 2)
