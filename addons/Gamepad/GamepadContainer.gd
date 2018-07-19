###[ INFO ]######################################################################################################

# Component: GamepadContainer
# Author: Francesco Iafulli (fiaful)
# Version: 1.0
# Last modify: 2018-07-18

# What is this:
# E' il nodo che andrà a contenere tutti gli oggetti che costruiranno il gamepad.
# Di fatto, è l'oggetto che cattura l'input multitouch sullo schermo, legando ogni touch ad uno specifico oggetto
# del gamepad.

# Requirements:
#	- l'area di questo oggetto deve essere estesa a tutta la zone che si vuole rendere sensibile al tocco
#	- tutti gli oggetti appartenenti al gamepad dovranno essere contenuti in questo oggetto

# To do:
#   - gestire lo scroll sugli assi x e y
#   - gestire lo swipe sugli assi x e y
#   - gestire lo zoom-in e zoom-out (pinch in/out)

# Changelog:
#
#

###[ BEGIN ]#####################################################################################################

extends Control

###[ EXPORTED VARIABLES ]########################################################################################

# indica se l'intero gamepad deve essere disabilitato (se true, nessuno degli oggetti contenuti riceverà i tocchi
# dell'utente
export var disabled = false

###[ SIGNALS ]###################################################################################################

# viene emesso quando avviene un qualsiasi tocco (in caso di più tocchi simultanei, viene emesso per ogni tocco)
signal finger_down(finger_data)
# viene emesso quando qualsiasi tocco ha fine (in caso di fine di più tocchi simultanei, viene emesso per ogni tocco)
signal finger_up(finger_data)
# viene emesso quando qualsiasi dito si muove sullo schermo (in caso di movimento di più dita, viene emesso per ogni dito)
signal finger_move(finger_data)

# Nota: finger_data è un oggetto, di tipo finger, che mantiene le informazioni su cosa è accaduto.
# la classe Finger è definita in fondo a questo file

###[ PRIVATE AND PUBLIC VARIABLES ]##############################################################################

# mantiene un elenco (in forma di dizionario dove la chiave è l'indice del tocco) di tutti i tocchi attualmente attivi
var fingers = {}

###[ METHODS ]###################################################################################################

func _input(event):
	# se il contenitore è disabilitato, non faccio nulla
	if disabled:
		return
	# se l'evento è un tocco premuto
	if event is InputEventScreenTouch:
		if event.is_pressed():
			# creo, se non esistente (altrimenti l'aggiorna), una nuova voce Finger nel dizionario
			fingers[event.index] = Finger.new()
			# impostandone i dati di base (indice, l'oggetto su cui è avvenuto il tocco, la posizione del tocco)
			fingers[event.index].set_finger(event.index, _find_object_by_position(event), event.position)
			# emetto il segnale del tocco avvenuto
			emit_signal("finger_down", fingers[event.index])
			# se il dito ha premuto lo schermo su un oggetto del gamepad, propago l'evento a quell'oggetto
			if fingers[event.index].object:
				fingers[event.index].object.handle_down_event(event, fingers[event.index])
		else:
			# mentre se l'evento è un tocco rilasciato ed era stato memorizzato
			if fingers.has(event.index):
				# imposto le informazioni sul dito dicendo che non è più premuto
				fingers[event.index].pressed = false
				# ed emetto il segnale di dito rilasciato, passando tutte le informazioni raccolte finora
				emit_signal("finger_up", fingers[event.index])
				# se il dito era premuto su un oggetto del gamepad, comunico a quell'oggetto che il dito è stato sollevato
				if fingers[event.index].object:
					fingers[event.index].object.handle_up_event(event, fingers[event.index])
				# dunque pulisco le informazioni del dito dal dizionario in modo che possano essere reinserire se necessario
				fingers[event.index].reset_finger()
				fingers.erase(event.index)

	# se invece l'evento è un trascinamento del dito
	if event is InputEventScreenDrag:
		# controllo di avere le informazioni per quel dito e, se ce l'ho,
		if fingers.has(event.index):
			# aggiorno le informazioni sulla posizione
			fingers[event.index].position = event.position
			# ed emetto il segnale di spostamento del dito
			emit_signal("finger_move", fingers[event.index])
			# quindi se al dito era associato un oggetto del gamepad, comunico lo spostamento a quell'oggetto
			if fingers[event.index].object:
				fingers[event.index].object.handle_move_event(event, fingers[event.index])

# questa funzione verifica se alle date coordinate (estratte dall'evento), è presente un oggetto del gamepad.
# se è presente, lo ritorna, altrimenti restituisce null
func _find_object_by_position(event):
	for child in get_children():
		if "gamepad_type" in child and child.get_global_rect().has_point(event.position):
			return child
	return null
	
	
###[ THE FINGER CLASS ]##########################################################################################

class Finger:

# What is this
# Questa classe è un contenitore di dati per le informazioni del dito

###[ PRIVATE AND PUBLIC VARIABLES ]##############################################################################
	
	# contiene l'indice del tocco,
	var index = -1
	# il tipo dell'oggetto su cui il tocco è avvenuto (UNKNOWN è se il tocco non ha sotto di sè oggetti del gamepad)
	# il suo valore è dato dalla proprietà gamepad_type dell'oggetto del gamepad su cui è avvenuto il tocco
	var type = "UNKNOWN"
	# se il dito è premuso sullo schermo oppure no
	var pressed = false
	# la posizione del tocco
	var position = Vector2()
	# l'oggetto collegato al dito
	var object = null

###[ METHODS ]###################################################################################################
	
	func set_finger(_index, _object, _position, _type=""):
		index = _index
		type = _type if _type else _object.gamepad_type if _object else "UNKNOWN"
		print (type)
		pressed = true
		position = _position
		object = _object
	
	func reset_finger():
		index = -1
		type = "UNKNOWN"
		pressed = false
		position.x = -1
		position.y = -1
		object = null
		
	func to_string():
		var d = {
			"index": index,
			"type": type,
			"pressed": pressed,
			"position": position,
			"object": object
		}
		return str(d)
		
###[ END ]#######################################################################################################