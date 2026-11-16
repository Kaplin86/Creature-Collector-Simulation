extends PanelContainer
class_name BodypartPreviewer

var partHash : BodyPart

signal updated
signal delete

func displayPart(part : BodyPart):
	%HPSpin.value = part.HP
	%ATKSpin.value = part.ATK
	%DEFspin.value = part.DEF
	%SpAspin.value = part.SpA
	%SpDspin.value = part.SpD
	%SPSpin.value = part.SP
	partHash = part

func onUpdate(ya : float):
	if partHash:
		partHash.HP = %HPSpin.value
		partHash.ATK = %ATKSpin.value
		partHash.DEF = %DEFspin.value
		partHash.SpA = %SpAspin.value
		partHash.SpD = %SpDspin.value
		partHash.SP = %SPSpin.value
		updated.emit()

func setName(text : String):
	$Vbox/HBoxContainer2/Name.text = text
	


func _on_delete_pressed():
	delete.emit()
