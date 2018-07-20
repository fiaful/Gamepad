###[ INFO ]######################################################################################################

# Component: GamepadPaddle
# Author: Francesco Iafulli (fiaful)
# E-mail: fiaful@hotmail.com
# Version: 1.0
# Last modify: 2018-07-20

# What is this:
# E' l'oggetto che consente di gestire paddle virtuali analogici (la paddle è un controller che ruota su se stesso,
# come ad esempio il volante di una automobile).
# Possono essere aggiunti nel contenitore quanti paddle si desideri (generalmente 1 o 2)

# Requirements:
#	- il parent di questo nodo deve essere di tipo GamepadArea se si desidera utilizzare la proprietà show_dinamically
#		per far apparire la paddle dinamicamente alla posizione della pressione del dito sullo schermo. Il suo parent
#		può essere di tipo GamepadContainer se la paddle è sempre visibile sullo schermo ad una posizione fissa.
#	- deve comunque essere contenuto (direttamente o indirettamente) in un nodo di tipo GamepadContainer, altrimenti
#		non funzionerà
#	- la texture di sfondo della paddle deve essere quadrata altrimenti si verificheranno problemi di visualizzazione 
#		a runtime (vedere le immagini di esempio nella cartella assets/Gamepad)
#	- se la paddle deve essere sempre visibile in una posizione fissa, è necessario valorizzare questa posizione nella
#		proprietà static_position.

# Changelog:
#
#

###[ BEGIN ]#####################################################################################################

tool
extends Control

###[ CONSTS ]####################################################################################################

# contiene un valore per definire un angolo non valido
const INVALID_ANGLE = -99

###[ INTERNAL OBJECTS ]##########################################################################################

# texture di sfondo della paddle
onready var bg = $PaddleBackground

# texture del centro della paddle
onready var paddle = $Paddle

# animazione di visualizzazione/nascondimento della paddle
onready var fader = $ShowHideAnimation

onready var timer = $Timer

###[ EXPORTED VARIABLES ]########################################################################################

# indica se la paddle deve essere disabilitata (se true, la paddle non riceverà i tocchi dell'utente)
export var disabled = false

# indica se la paddle deve essere staticamente sempre visualizzata (false) o se questa deve apparire nascosta e
# mostrarsi (true) quando l'utente tocca la sua area (in questo caso deve essere contenuta in un oggetto di tipo
# GamepadArea)
export var show_dynamically = false setget _set_show_dynamically

# questa proprietà contiene il nome dell'oggetto (che viene restituito nell'oggetto finger)
export var gamepad_type = "PADDLE 0"

# texture di sfondo della paddle
export(Texture) var background_texture setget _set_bg_texture, _get_bg_texture

# texture del centro della paddle
export(Texture) var paddle_texture setget _set_texture, _get_texture

# scala della texture del centro della paddle (la dimensione dello sfondo è data dal rect_size dell'oggetto,
# quindi per impostare la dimensione del centro della paddle si usa questa proprietà)
export(Vector2) var paddle_scale setget _set_scale, _get_scale

# contiene la reale posizione della paddle
export var static_position = Vector2(0, 0)

# questa proprietà indica la forza minima da imporre alla paddle per iniziare a considerare validi
# i valori (es. con un valore = 0.5, la paddle inizierà a ruotare solo se l'utente toccherà l'oggetto
# su oltre la metà della distanza tra il centro della paddle ed il bordo)
export var valid_threshold = 0.2

# se impostato a true, il rilascio della paddle resetterà i valori e la posizione della paddle, mentre
# se impostato a false, al rilascio i valori e la posizione resteranno gli ultimi validi
export var reset_on_release = true

# impone un limite inferiore alla rotazione della paddle (limite inferiore e superiore possono essere invertiti)
export var low_limit = 0

# impone un limite alto alla rotazione della paddle (limite inferiore e superiore possono essere invertiti)
export var high_limit = 0

# per utilizzare uniformemente gli oggetti anche in presenza di tastiera, consento di associare
# direttamente degli input map per ruotare la paddle in senso antiorario e orario
export var simulate_counter_clockwise = "ui_left"
export var simulate_clockwise = "ui_right"

# in caso di simulazione con la tastiera, indica lo step di incremento/decremento dell'angolo
export var simulation_increment = 0.05

# in caso di simulazione con la tastiera, indica la velocità di incremento/decremento dell'angolo
export var simulation_delay = 0.01

###[ PRIVATE AND PUBLIC VARIABLES ]##############################################################################

# centro della paddle (ovvero dello sfondo della paddle)
var center_point = Vector2(0,0)

# forza calcolata dal centro della paddle (serve per calcolare l'angolo)
var current_force = Vector2(0,0)

# metà della dimensione dello sfondo della paddle
var half_size = Vector2()

# area del rettangolo costituito da metà delle dimensioni dello sfondo
var squared_half_size_length = 0

# indica se l'angolo di rotazione della paddle si trova all'interno o all'esterno dei limiti imposti
var into_limits = false

# i dati del tocco (in modo che possano essere recuperati negli eventi)
var finger_data = null

# angolo di rotazione della paddle
var angle = -1

# indica se sto ruotando la paddle con i tasti della tastiera oppure no
var simulation = false

# ultimo angolo calcolato (serve per emettere i segnali solo se l'angolo corrente è diverso da quello precedente)
var last_angle = INVALID_ANGLE

# mantiene lo stato della visualizzazione dinamica
var shown = true

# indica la direzione di rotazione nel caso di simulazione con la tastiera
var direction = 0

###[ SIGNALS ]###################################################################################################

# viene emesso quando la paddle ruota, restituendo l'angolo di rotazione e l'oggetto paddle stesso (in modo da 
# poter recuperare altre informazioni (qualsiasi proprietà dell'oggetto) 
signal angle_changed(current_angle, sender)

# viene emesso quando l'utente rilascia il dito dalla paddle (l'angolo sarà sempre invalido, pertanto è inutile 
# passare il sender)
signal paddle_released

###[ METHODS ]###################################################################################################

# costruisce l'albero dei nodi necessari all'oggetto prendendoli dal template
func _init():
	# se non sono già stati caricati
	if get_child_count() > 0: return
	# carico e istanzio il template
	var gamepad_paddle_template = load("res://addons/Gamepad/GamepadPaddleTemplate.tscn").instance()
	# quindi se ci sono oggetti nel template (ovviamente si)
	if gamepad_paddle_template.get_child_count() > 0:
		# prendo ogni oggetto nel template
		for child in gamepad_paddle_template.get_children():
			# se l'oggetto è il timer
			if child is Timer:
				# ne creo il duplicato
				var tmr = child.duplicate()
				# lo aggiungo al mio nodo
				add_child(tmr)
				tmr.wait_time = simulation_delay
				# connetto il suo segnale timeout allo script
				tmr.connect("timeout", self, "_on_timer_timeout")
			else:
				# aggiungo un duplicato al mio nodo
				add_child(child.duplicate())

func _ready():
	# se l'oggetto deve essere visualizzato dinamicamente (ovvero solo quando l'utente tocca lo schermo) lo nascondo
	if show_dynamically:
		_hide_paddle()
	# imposto la sua posizione statica (non ha senso se visualizzato dinamicamente in quanto la sua posizione
	# varierà in base al tocco dell'utente)
	rect_position = static_position	
	# ricavo i restanti valori che mi serviranno più avanti per fare i calcoli
	half_size = bg.rect_size / 2
	center_point = half_size	
	paddle.position = half_size
	squared_half_size_length = half_size.x * half_size.y

# emula la paddle tramite i tasti
func handle_input(event):
	if event is InputEventKey:
		if !((simulate_counter_clockwise and event.is_action(simulate_counter_clockwise)) or \
				(simulate_clockwise and event.is_action(simulate_clockwise))): return
	else:
		return
	# verifica quale tasto è stato premuto
	var cnt = simulate_counter_clockwise and Input.is_action_pressed(simulate_counter_clockwise)
	var clk = simulate_clockwise and Input.is_action_pressed(simulate_clockwise)
	simulation = false
	# se nessuna delle 2 direzioni è premuta, azzero l'angolo e sollevo l'evento di rilascio
	if !cnt and !clk:
		# fermo il timer che si occupa di far ruotare la paddle
		timer.stop()
		handle_up_event(null, null)
	else:		
		# imposto la direzione di rotazione
		if cnt:
			clk = false
			direction = -simulation_increment
		elif clk:
			cnt = false
			direction = simulation_increment
		# ed avvio il timer che si occuperà di far ruotare la paddle
		timer.start()

func _on_timer_timeout():
	# inizializza la posizione del'oggetto
	var ev = InputEventScreenTouch.new()
	ev.position = get_parent().rect_global_position + static_position + half_size
	simulation = true

	# incrementa/decrementa l'angolo
	angle += direction
		
	# se l'angolo è diverso dal precedente
	if angle != last_angle:
		last_angle = angle
		# simulo la rotazione della paddle
		handle_down_event(ev, null)

# l'utente ha toccato lo schermo in corrispondenza della paddle o dell'area che contiene la paddle
func handle_down_event(event, finger):
	# se la paddle è disabilitata esco senza fare nulla (prima però resetto i dati interni)
	if disabled:
		reset()
		return
	# altrimenti imposto i dati del tocco in modo che possano essere recuperati da fuori
	finger_data = finger
	# se la paddle deve essere visualizzata dinamicamente vuol dire che in questo momento non è visibile e quindi la mostro
	if show_dynamically:
		_show_paddle(event)
		
	# se il tocco è avvenuto nella zona dello sfondo della paddle
	if simulation or bg.get_global_rect().has_point(event.position):
		# calcolo la forza e l'angolo, aggiorno la rotazione della paddle ed emetto il segnale
		calculate(event)
	else:
		# altrimenti resetto tutti i dati e esco
		reset()
	
# l'utente ha sollevato il dito con cui aveva toccato la paddle o la sua area
func handle_up_event(event, finger):
	# se la paddle è disabilitata esco senza fare nulla (prima però resetto i dati interni)
	if disabled:
		reset()
		return
	# altrimenti imposto i dati del tocco in modo che possano essere recuperati da fuori
	finger_data = finger
	# se la paddle deve essere visualizzata dinamicamente vuol dire che in questo momento è visibile e quindi la nascondo
	if show_dynamically:
		_hide_paddle()
		
	# resetto i dati interni
	reset()
	# quindi emetto il segnale per comunicare che la paddle è stata rilasciata
	emit_signal("paddle_released")
	
# l'utente ha spostato il dito con cui aveva toccato la paddle o la sua area
func handle_move_event(event, finger):
	# se la paddle è disabilitata esco senza fare nulla (prima però resetto i dati interni)
	if disabled:
		reset()
		return
	# altrimenti imposto i dati del tocco in modo che possano essere recuperati da fuori
	finger_data = finger
	# calcolo la forza, l'angolo, aggiorno la rotazione della paddle ed emetto il segnale
	calculate(event)
	
# calcolo la forza, l'angolo, aggiorno la rotazione della paddle ed emetto il segnale
func calculate(event):
	# ricalcolo la posizione dell'evento in modo che lo 0,0 coincida con lo 0,0 dell'oggetto
	if !simulation:
		var pos = event.position - rect_global_position
		calculate_force(pos)
	update_paddle_pos()
	emit()

func calculate_force(pos):
#	print ("pos: ", pos, " - center_point: ", center_point, " - half_size: ", half_size) 
	# calcolo la forza in relazione alla posizione del mouse e il centro della paddle, e la normalizzo
	current_force.x = (pos.x - center_point.x) / half_size.x
	current_force.y = (pos.y - center_point.y) / half_size.y
	if current_force.length_squared() > 1:
		current_force = current_force / current_force.length()
	# quindi se la forza è minore della soglia di validità, resituisco 0,0 (per comunicare che 
	# non è stato effettuato uno spostamento valido del centro della paddle)
	if (current_force.length() < valid_threshold):
		current_force = Vector2(0,0) 

# aggiorno la rotazione della paddle in modo che graficamente sia coerente
func update_paddle_pos():
	var new_angle
	if !simulation:
		var x = center_point.x + half_size.x * current_force.x
		var y = center_point.y + half_size.y * current_force.y
		new_angle = Vector2(x, y).angle_to_point(center_point)
	else:
		new_angle = angle
	# quindi verifico che il nuovo angolo sia nei limiti
	into_limits = false
	var deg_angle = rad2deg(new_angle) + 180
#	print ([deg_angle, low_limit, high_limit])
	# se low_limit e high_limit sono uguali non devo imporre limiti, ovvero sono sempre nei limiti
	if low_limit != high_limit:
		if low_limit > high_limit:
			if deg_angle <= high_limit:
				into_limits = true
			if deg_angle >= low_limit:
				if deg_angle >= high_limit:
					into_limits = true
		else:
			if deg_angle <= high_limit and deg_angle >= low_limit:
				into_limits = true
	else:
		into_limits = true
		
	# se sono nei limiti, imposto il nuovo angolo ed aggiorno la rotazione della paddle
	if into_limits:
		angle = new_angle
		paddle.rotation = angle

# solo se reset_on_release = true (vedi commento) effettuo un reset dei dati interni, 
# imposto l'angolo della paddle ad un valore invalido e ne aggiorno graficamente la rotazione
func reset():
	if !reset_on_release: return
	calculate_force(center_point)
	update_paddle_pos()
	angle = INVALID_ANGLE
	last_angle = angle
#	emit()
	
# emette il segnale per comunicare il cambiamento dell'angolo della paddle
func emit():
	if into_limits:
		emit_signal("angle_changed", angle, self)
#	print (angle / PI * 180)
#	print (rad2deg(angle) + 180)

# mostra la paddle
func _show_paddle(event):
	# se event è diverso dal null (nel caso in l'utente tocca la paddle o la sua area) calcolo la posizione
	# in base a quella passata nell'evento
	if shown: return
	shown = true
	if event:
		rect_global_position = event.position - center_point
	else:
		# altrimenti la posizione della paddle è quella statica impostata in static_position
		rect_position = static_position
	# avvio l'animazione di visualizzazione
	if fader:
		reset()
		fader.stop()
		fader.play("fade_in", -1, 10)
	
# nasconde la paddle
func _hide_paddle():
	if !shown: return
	shown = false
	# avvia l'animazione di nascondimento
	if fader:
		fader.stop()
		fader.play("fade_out", -1, 10)

###[ SETTER/GETTER ]#############################################################################################

func _get_scale():
	return $Paddle.scale

func _set_scale(value):
#	if !has_node("Paddle"): return
	$Paddle.scale = value
	$Paddle.position = $PaddleBackground.rect_size / 2

func _get_bg_texture():
	return $PaddleBackground.texture

func _set_bg_texture(value):
#	if !has_node("PaddleBackground"): return
	$PaddleBackground.texture = value	
	$Paddle.position = $PaddleBackground.rect_size / 2

func _get_texture():
	return $Paddle.texture
	
func _set_texture(value):
#	if !has_node("PaddleBackground"): return
	$Paddle.texture = value
	$Paddle.position = $PaddleBackground.rect_size / 2

func _set_show_dynamically(value):
	show_dynamically = value
	# se sono nell'editor non faccio nulla (altrimenti mi verrebbe nascosto l'oggetto anche dall'editor)
	if Engine.editor_hint: return
	if value:
		_hide_paddle()
	else:
		_show_paddle(null)

###[ END ]#######################################################################################################