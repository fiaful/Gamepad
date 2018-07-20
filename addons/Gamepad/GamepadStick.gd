###[ INFO ]######################################################################################################

# Component: GamepadStick
# Author: Francesco Iafulli (fiaful)
# E-mail: fiaful@hotmail.com
# Version: 1.0
# Last modify: 2018-07-20

# What is this:
# E' l'oggetto che consente di gestire stick virtuali, analogici o digitali.
# Possono essere aggiunti nel contenitore quanti stick si desideri (generalmente 1 o 2)
# Esistono diversi tipi di stick:
#	- analogici: 
#		restituiscono un vettore 2D forza contenente valori che vanno da 0 a 1 (positivi per le direzioni
#		destra e basso, e negativi per le direzioni sinistra e alto) dipendenti dalla distanza dello stick
#		dal suo centro. 
#		Stick analogici sono:
#			- ANALOG			(consentono qualsiasi direzione)
#			- LEFT/RIGHT		(consentono lo spostamento solo in orizzontale - l'asse y avrà sempre valore 0)
#			- UP/DOWN			(consentono lo spostamento solo in verticale - l'asse x avrà sempre valore 0)
#
#	- digitali:
#		restituiscono un vettore 2D digitale, ovvero i valori di x e y possono valere solo 0, 1, e -1
#		a seconda della direzione (positivi per le direzioni destra e basso, e negativi per le direzioni 
#		sinistra e alto).
#		Stick digitali sono:
#			- DIGITAL 8			(consente lo spostamento dello stick nelle 8 direzioni digitali (su, giù, sinistra, 
#									destra, e relative diagonali)
#			- DIGITAL 4 PLUS	(consente lo spostamento nelle sole 4 direzioni principali disposte cardinalmente
#									(su, giù, destra, e sinistra)
#			- DIGITAL 4 X		(consente lo spostamento nelle 4 direzioni diagonali (alto-sinistra, alto-destra,
#									basso-sinistra, e basso destra)
#			- DIGITAL 4 ISO		(è come il DIGITAL 4 X ma consente di modificare alcuni parametri particolari per
#									visualizzare lo stick in maniera isometrica)
#
#	La direzione corrente, nel caso di stick digitali, viene restituita anche in una lista di nome direction in cui 
#	è possibile verificare se una data direzione è presente (es.: if sender.UP in sender.direction: )
#
#	Nota: è possibile tramutare gli analogici LEFT/RIGHT e UP/DOWN in digitali impostando la proprietà step = 1

# Requirements:
#	- il parent di questo nodo deve essere di tipo GamepadArea se si desidera utilizzare la proprietà show_dinamically
#		per far apparire lo stick dinamicamente alla posizione della pressione del dito sullo schermo. Il suo parent
#		può essere di tipo GamepadContainer se lo stick è sempre visibile sullo schermo ad una posizione fissa.
#	- deve comunque essere contenuto (direttamente o indirettamente) in un nodo di tipo GamepadContainer, altrimenti
#		non funzionerà
#	- la texture di sfondo dello stick deve essere comunque quadrata (width == height), anche nel caso di LEFT/RIGHT,
#		UD/DOWN, o DIGITAL 4 ISO, altrimenti si verificheranno problemi di visualizzazione a runtime (vedere le
#		immagini di esempio nella cartella assets/Gamepad)
#	- se lo stick deve essere sempre visibile in una posizione fissa, è necessario valorizzare questa posizione nella
#		proprietà static_position.

# To do:
#	- inserire un flag per invertire l'asse y

# Changelog:
#
#

###[ BEGIN ]#####################################################################################################

tool
extends Control

###[ CONSTS ]####################################################################################################

# contiene un valore per definire un angolo non valido
const INVALID_ANGLE = -99

###[ ENUMS ]#####################################################################################################

# consente di specificare che tipo di stick si intende gestire
enum STICK_TYPE { _ANALOG, _DIGITAL_8, _DIGITAL_4_PLUS, _DIGITAL_4_X, _DIGITAL_4_ISO, _LEFT_RIGHT, _UP_DOWN }

# contiene le quattro direzioni fondamentali, utilizzato per valorizzare la lista delle direzioni digitali direction
enum DIGITAL_DIRECTIONS { UP, LEFT, DOWN, RIGHT }

###[ INTERNAL OBJECTS ]##########################################################################################

# texture di sfondo dello stick
onready var bg = $StickBackground

# texture del centro dello stick
onready var stick = $Stick

# animazione di visualizzazione/nascondimento dello stick
onready var fader = $ShowHideAnimation

###[ EXPORTED VARIABLES ]########################################################################################

# indica se lo stick deve essere disabilitato (se true, lo stick non riceverà i tocchi dell'utente)
export var disabled = false

# indica se lo stick deve essere staticamente sempre visualizzato (false) o se questo deve apparire nascosto e
# mostrarsi (true) quando l'utente tocca la sua area (in questo caso deve essere contenuto in un oggetto di tipo
# GamepadArea)
export var show_dynamically = false setget _set_show_dynamically

# questa proprietà contiene il nome dell'oggetto (che viene restituito nell'oggetto finger)
export var gamepad_type = "STICK 0"

# indica il tipo dello stick (fare riferimento alla documentazione in alto e all'enum STICK_TYPE)
export(STICK_TYPE) var stick_type = STICK_TYPE._ANALOG

# texture di sfondo dello stick
export(Texture) var background_texture setget _set_bg_texture, _get_bg_texture

# texture del centro dello stick
export(Texture) var stick_texture setget _set_texture, _get_texture

# scala della texture del centro dello stick (la dimensione dello sfondo è data dal rect_size dell'oggetto,
# quindi per impostare la dimensione del centro dello stick si usa questa proprietà)
export(Vector2) var stick_scale setget _set_scale, _get_scale

# contiene la reale posizione dello stick
export var static_position = Vector2(0, 0)

# indica se il centro dello stick deve essere nascosto (true) o meno se esso si trova al centro dell'oggetto
# (ovvero se la sua forza = 0)
export var hide_stick_on_stop = false

# questa proprietà è da utilizzarsi solo se lo stick è di tipo DIGITAL 4 ISO e serve ad indicare di quanti
# pixel deve essere spostato il centro dello stick se si trova nelle posizioni diagonali alte
export var adjust_iso = 0

# questa proprietà indica la forza minima da imporre al centro dello stick per iniziare a considerare validi
# i valori (es. con un valore = 0.5, il centro dello stick non si sposterà fino a quando non sarà raggiunto
# almeno la metà della distanza tra il centro dello stick ed il bordo)
export var valid_threshold = 0.2

# consente di restituire i valori analogici arrotondati per step
# (es.: con un valore = 0.25, lo stick restituirà come forze i soli valori 0, 0.25, 0.5, 0.75, 1)
export var step = 0.0

# per utilizzare uniformemente gli oggetti anche in presenza di tastiera, consento di associare
# direttamente degli input map alle direzioni
# Attenzione: la simulazione non funzionerà correttamente con stick analogici
export var simulate_up = "ui_up"
export var simulate_left = "ui_left"
export var simulate_down = "ui_down"
export var simulate_right = "ui_right"

###[ PRIVATE AND PUBLIC VARIABLES ]##############################################################################

# centro dello stick (ovvero dello sfondo dello stick)
var center_point = Vector2(0,0)

# ultima forza calcolata (serve per emettere i segnali solo se la forza corrente è diversa da quella precedente)
var last_force = Vector2(0,0)

# forza calcolata dal centro dello stick (oppure i valori digitali nel caso di stick digitali)
var current_force = Vector2(0,0)

# metà della dimensione dello sfondo dello stick
var half_size = Vector2()

# metà della dimensione del centro dello stick
var half_stick = Vector2()

# posizione del centro dello stick
var stick_pos = Vector2()

# area del rettangolo costituito da metà delle dimensioni dello sfondo
var squared_half_size_length = 0

# i dati del tocco (in modo che possano essere recuperati negli eventi)
var finger_data = null

# angolo tra la posizione del centro dello stick e l'asse x
var angle = -1

# lista delle direzioni digitali in cui si trova lo stick
var direction = []

# indica se sto simulando lo stick con i tasti della tastiera oppure no
var simulation = false

###[ SIGNALS ]###################################################################################################

# viene emesso quando lo stick si muove, restituendo il vettore della forza (se analogico altrimento valori 0, 1,
# -1 se digitale) e l'oggetto stick stesso (in modo da poter recuperare altre informazioni come l'angolo, le
# direzioni, i dati del tocco, o qualsiasi altra proprietà dell'oggetto) 
signal gamepad_force_changed(current_force, sender)

# viene emesso quando l'utente rilascia il dito dallo stick (la forza sarà sempre 0, l'angolo sarà sempre invalido, 
# e la lista delle direzioni sarà sempre vuota, pertanto è inutile passare il sender)
signal gamepad_stick_released

###[ METHODS ]###################################################################################################

# costruisce l'albero dei nodi necessari all'oggetto prendendoli dal template
func _init():
	# se non sono già stati caricati
	if get_child_count() > 0: return
	# carico e istanzio il template
	var gamepad_stick_template = load("res://addons/Gamepad/GamepadStickTemplate.tscn").instance()
	# quindi se ci sono oggetti nel template (ovviamente si)
	if gamepad_stick_template.get_child_count() > 0:
		# prendo ogni oggetto nel template
		for child in gamepad_stick_template.get_children():
			# e ne aggiungo un duplicato al mio nodo
			add_child(child.duplicate())

func _input(event):
	# verifica se è avvenuto un evento da tastiera, così da poter simulare lo stick tramite i tasti
	if event is InputEventKey:
		if event.is_action(simulate_up) or event.is_action(simulate_down) or event.is_action(simulate_left) or event.is_action(simulate_right):
			handle_input()

func _ready():
	# se l'oggetto deve essere visualizzato dinamicamente (ovvero solo quando l'utente tocca lo schermo) lo nascondo
	if show_dynamically:
		_hide_stick()
	# imposto la sua posizione statica (non ha senso se visualizzato dinamicamente in quanto la sua posizione
	# varierà in base al tocco dell'utente)
	rect_position = static_position
	# ricavo i restanti valori che mi serviranno più avanti per fare i calcoli
	half_size = bg.rect_size / 2
	center_point = half_size	
	stick.position = half_size
	half_stick = (stick.texture.get_size() * stick.scale) / 2
	squared_half_size_length = half_size.x * half_size.y

# emula lo stick tramite i tasti
func handle_input():
	var ev
	# verifica quale tasto è stato premuto
	var up = Input.is_action_pressed(simulate_up)
	var down = Input.is_action_pressed(simulate_down)
	var left = Input.is_action_pressed(simulate_left)
	var right = Input.is_action_pressed(simulate_right)
	simulation = false
	# se nessuna delle 4 direzioni è premuta, azzero la forza così che verrà sollevato l'evento di rilascio
	if !up and !down and !left and !right:
		current_force = Vector2(0, 0)
	else:
		# se almeno una delle 4 direzioni è premuta, inizializza la posizione del'oggetto
		ev = InputEventScreenTouch.new()
		ev.position = get_parent().rect_global_position + static_position + half_size
		simulation = true
		
		# se lo stick è di qualsiasi tipo tranne un DIGITAL 4 diagonale
		if stick_type != STICK_TYPE._DIGITAL_4_X and stick_type != STICK_TYPE._DIGITAL_4_ISO:
			# imposto la forza al valore digitale corrispondente ai tasti premuti
			current_force.x = -1 if left else 1 if right else 0
			current_force.y = -1 if up else 1 if down else 0
		else:
			# altrimenti, se lo stick è di tipo DIGITAL 4 diagonale, decido io la forza in base al tasto premuto
			if up:
				down = false; left = false; right = false
				current_force = Vector2(-1, -1)
			elif left:
				down = false; up = false; right = false
				current_force = Vector2(-1, 1)
			elif down:
				up = false; left = false; right = false
				current_force = Vector2(1, 1)
			elif right:
				down = false; left = false; up = false
				current_force = Vector2(1, -1)

	# se la forza è diversa da 0				
	if current_force.x != 0 or current_force.y != 0:
		# ed è diversa dalla precedente
		if last_force.x != current_force.x or last_force.y != current_force.y:
			# simulo la pressione del dito sullo stick
			handle_down_event(ev, null)
	else:
		# mentre se la forza è 0 ma la precedente non lo era,
		if last_force.x != 0 or last_force.y != 0:
			# simulo il rilascio del dito dallo stick
			handle_up_event(ev, null)

# l'utente ha toccato lo schermo in corrispondenza dello stick o dell'area che contiene lo stick
func handle_down_event(event, finger):
	# se lo stick è disabilitato esco senza fare nulla (prima però resetto i dati interni)
	if disabled:
		reset()
		return
	# altrimenti imposto i dati del tocco in modo che possano essere recuperati da fuori
	finger_data = finger
	# se lo stick deve essere visualizzato dinamicamente vuol dire che in questo momento non è visibile e quindi lo mostro
	if show_dynamically:
		_show_stick(event)
	
	# se il tocco è avvenuto nella zona dello sfondo dello stick
	if simulation or bg.get_global_rect().has_point(event.position):
		# calcolo la forza, aggiorno la posizione del centro dello stick ed emetto il segnale
		calculate(event)
	else:
		# altrimenti resetto tutti i dati e esco
		reset()

# l'utente ha sollevato il dito con cui aveva toccato lo stick o la sua area
func handle_up_event(event, finger):
	# se lo stick è disabilitato esco senza fare nulla (prima però resetto i dati interni)
	if disabled:
		reset()
		return
	# altrimenti imposto i dati del tocco in modo che possano essere recuperati da fuori
	finger_data = finger
	# se lo stick deve essere visualizzato dinamicamente vuol dire che in questo momento è visibile e quindi lo nascondo
	if show_dynamically:
		_hide_stick()
		
	# resetto i dati interni
	reset()
	# quindi emetto il segnale per comunicare che lo stick è stato rilasciato
	emit_signal("gamepad_stick_released")
	
# l'utente ha spostato il dito con cui aveva toccato lo stick o la sua area
func handle_move_event(event, finger):
	# se lo stick è disabilitato esco senza fare nulla (prima però resetto i dati interni)
	if disabled:
		reset()
		return
	# altrimenti imposto i dati del tocco in modo che possano essere recuperati da fuori
	finger_data = finger
	# calcolo la forza, aggiorno la posizione del centro dello stick ed emetto il segnale
	calculate(event)

# calcolo la forza, aggiorno la posizione del centro dello stick ed emetto il segnale
func calculate(event):
	# ricalcolo la posizione dell'evento in modo che lo 0,0 coincida con lo 0,0 dell'oggetto
	var pos = event.position - rect_global_position
	calculate_force(pos)
	update_stick_pos()
	emit()

func calculate_force(pos):
#	print ("pos: ", pos, " - center_point: ", center_point, " - half_size: ", half_size) 
	if !simulation:
		# calcolo la forza in relazione alla posizione del mouse e il centro dello stick, e la normalizzo
		current_force.x = (pos.x - center_point.x) / half_size.x
		current_force.y = (pos.y - center_point.y) / half_size.y
		if current_force.length_squared() > 1:
			current_force = current_force / current_force.length()
		# quindi se la forza è minore della soglia di validità, resituisco 0,0 (per comunicare che 
		# non è stato effettuato uno spostamento valido del centro dello stick)
		if (current_force.length() < valid_threshold):
			current_force = Vector2(0,0)
	# effettuo aggiustamenti vari alla forza in baso a che tipo di stick sto gestendo
	select_force()

# aggiorno la posizione del centro dello stick in modo che graficamente sia coerente
func update_stick_pos():
	stick_pos.x = center_point.x + half_size.x * current_force.x
	stick_pos.y = center_point.y + half_size.y * current_force.y
	# questa funzione serve solo se lo stick è di tipo DIGITAL 4 ISO
	adjust_stick_pos()
	stick.position = Vector2(stick_pos)
	# calcolo anche l'angolo tra la posizione dello stick e l'asse x
	angle = stick.position.angle_to_point(center_point)
	# infine gestisco la visualizzazione o meno del centro dello stick se deve essere
	# gestita in base al valore di hide_stick_on_stop (vedi commento)
	if hide_stick_on_stop and current_force.x == 0 and current_force.y == 0:
		stick.hide()
	else:
		stick.show()

# effettuo un reset dei dati interni, ovvero faccio si che la forza sia impostata a 0,
# il centro dello stick torni graficamente al centro, e sia impostato un angolo invalido
func reset():
#	calculate_force(center_point)
	current_force = Vector2(0,0)
	last_force = Vector2(0,0)
	update_stick_pos()
	angle = INVALID_ANGLE
#	emit()

# emette il segnale per comunicare il cambiamento della forza dello stick	
func emit():
	if current_force.x != last_force.x or current_force.y != last_force.y:
		# solo se la forza corrente è diversa da quella precedente
		last_force = Vector2(current_force.x, current_force.y)
		emit_signal("gamepad_force_changed", current_force, self)

# se lo stick è di tipo DIGITAL 4 ISO, e la posizione del centro dello stick capita in una
# diagonale alta, viene aggiustata graficamente la posizione
func adjust_stick_pos():
	if stick_type != STICK_TYPE._ANALOG and stick_type != null:
		if stick_type == STICK_TYPE._DIGITAL_4_ISO and adjust_iso != 0 and current_force.y == -1:
			if stick_pos.x < half_stick.x + adjust_iso:
				stick_pos.x = half_stick.x + adjust_iso
			elif stick_pos.x > rect_size.x - half_stick.x - adjust_iso:
				stick_pos.x = rect_size.x - half_stick.x - adjust_iso
		else:
			if stick_pos.x < half_stick.x:
				stick_pos.x = half_stick.x
			elif stick_pos.x > rect_size.x - half_stick.x:
				stick_pos.x = rect_size.x - half_stick.x
		if stick_pos.y < half_stick.y:
			stick_pos.y = half_stick.y
		elif stick_pos.y > rect_size.y - half_stick.y:
			stick_pos.y = rect_size.y - half_stick.y

# qui la forza viene adattata in base al tipo di stick che sto gestendo
func select_force():
	match stick_type:
		STICK_TYPE._DIGITAL_8:
			# la forza viene semplicemente convertita in digitale
			to_digital()
		STICK_TYPE._DIGITAL_4_PLUS:
			# il minore dei due assi viene azzerato in modo che possano
			# essere restituite solo forze cardinali 
			if abs(current_force.x) > abs(current_force.y):
				current_force.y = 0
			else:
				current_force.x = 0
			# quindi la forza viene convertita in digitale
			to_digital()
		STICK_TYPE._DIGITAL_4_X, STICK_TYPE._DIGITAL_4_ISO:
			# salvo la forza analogica prima di convertirla in digitale
			# in modo da poter capire effettivamente dove si trova il 
			# centro dello stick
			var curr = Vector2(current_force.x, current_force.y)
			# converto la forza in digitale
			to_digital()
			# determino quindi in quale diagonale mi trovo
			if abs(current_force.x) == 1:
				if curr.y > 0.35:
					current_force.y = 1
				else:
					current_force.y = -1
			else:
				if abs(current_force.y) == 1:
					if curr.x > 0.35:
						current_force.x = 1
					else:
						current_force.x = -1
		STICK_TYPE._LEFT_RIGHT:
			# azzero l'asse y
			current_force.y = 0
			# quindi, essendo un controllo analogico, lo sottopondo allo step
			to_steps()
		STICK_TYPE._UP_DOWN:
			# azzero l'asse x
			current_force.x = 0
			# quindi, essendo un controllo analogico, lo sottopondo allo step
			to_steps()
		_:
			# ANALOG
			# essendo un controllo analogico, lo sottopondo allo step
			to_steps()
	# popolo la lista delle direzioni in base ai valori digitali ottenuti
	direction = []
	if current_force.x < 0:
		direction.append(DIGITAL_DIRECTIONS.LEFT)
	elif current_force.x > 0:
		direction.append(DIGITAL_DIRECTIONS.RIGHT)
	if current_force.y < 0:
		direction.append(DIGITAL_DIRECTIONS.UP)
	elif current_force.y > 0:
		direction.append(DIGITAL_DIRECTIONS.DOWN)
		

func to_steps():
	# se lo step vale 0 (o meno) non applico lo step ed esco
	if step <= 0:
		return
	# se lo step vale 1 (o più) converto direttamente in digitale ed esco
	if step >= 1:
		to_digital()
		return
	# altrimenti applico lo step
	var modx = int(current_force.x / step) * step if abs(current_force.x) < 0.99 else 1 * sign(current_force.x)
	var mody = int(current_force.y / step) * step if abs(current_force.y) < 0.99 else 1 * sign(current_force.y)
	current_force = Vector2(modx, mody)

# digitalizza la forza corrente
func to_digital():
	current_force = current_force.normalized()
	current_force.x = stepify(current_force.x, 1)
	current_force.y = stepify(current_force.y, 1)

# mostra lo stick
func _show_stick(event):
	# se event è diverso dal null (nel caso in l'utente tocca lo stick o la sua area) calcolo la posizione
	# in base a quella passata nell'evento
	if event:
		rect_global_position = event.position - center_point
	else:
		# altrimenti la posizione dello stick è quella statica impostata in static_position
		rect_position = static_position
	# avvio l'animazione di visualizzazione
	if fader:
		if !simulation: reset()
		fader.stop()
		fader.play("fade_in", -1, 10)

# nasconde lo stick	
func _hide_stick():
	# avvia l'animazione di nascondimento
	if fader:
		fader.stop()
		fader.play("fade_out", -1, 10)

###[ SETTER/GETTER ]#############################################################################################

func _get_scale():
#	if !has_node("Stick"): return Vector2(1.0, 1.0)
	return $Stick.scale

func _set_scale(value):
#	if !has_node("Stick"): return
	$Stick.scale = value
	$Stick.position = $StickBackground.rect_size / 2

func _get_bg_texture():
#	if !has_node("StickBackground"): return null
	return $StickBackground.texture

func _set_bg_texture(value):
#	if !has_node("StickBackground"): return
	$StickBackground.texture = value	
	$Stick.position = $StickBackground.rect_size / 2

func _get_texture():
#	if !has_node("Stick"): return null
	return $Stick.texture
	
func _set_texture(value):
#	if !has_node("Stick"): return
	$Stick.texture = value
	$Stick.position = $StickBackground.rect_size / 2

func _set_show_dynamically(value):
	show_dynamically = value
	# se sono nell'editor non faccio nulla (altrimenti mi verrebbe nascosto l'oggetto anche dall'editor)
	if Engine.editor_hint: return
	if value:
		_hide_stick()
	else:
		_show_stick(null)

###[ END ]#######################################################################################################