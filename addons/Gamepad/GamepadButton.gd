###[ INFO ]######################################################################################################

# Component: GamepadButton
# Author: Francesco Iafulli (fiaful)
# E-mail: fiaful@hotmail.com
# Version: 1.0
# Last modify: 2018-07-20

# What is this:
# E' l'oggetto che consente di gestire i pulsanti del gamepad
# Possono essere aggiunti nel contenitore quanti button si desideri

# Requirements:
#	- il parent di questo nodo deve essere di tipo GamepadArea se si desidera utilizzare la proprietà show_dinamically
#		per far apparire il button dinamicamente alla posizione della pressione del dito sullo schermo. Il suo parent
#		può essere di tipo GamepadContainer se il button è sempre visibile sullo schermo in una posizione fissa.
#	- deve comunque essere contenuto (direttamente o indirettamente) in un nodo di tipo GamepadContainer, altrimenti
#		non funzionerà
#	- la texture del button deve essere quadrata altrimenti si verificheranno problemi di visualizzazione 
#		a runtime (vedere le immagini di esempio nella cartella assets/Gamepad)
#	- se il button deve essere sempre visibile in una posizione fissa, è necessario valorizzare questa posizione nella
#		proprietà static_position.

# Changelog:
#
#

###[ BEGIN ]#####################################################################################################

tool
extends Control

###[ INTERNAL OBJECTS ]##########################################################################################

# mantiene l'aspetto del button
onready var button = $ButtonFace

# gestisce l'autofire del button
onready var timer = $AutofireTimer

# gestisce visualizzazione/nascondimento del button
onready var fader = $ShowHideAnimation

###[ EXPORTED VARIABLES ]########################################################################################

# indica se il button deve essere disabilitato (se true, il button non riceverà i tocchi dell'utente e il suo aspetto
# verrà mutato visualizzando la texture_disabled se impostata)
export var disabled = false setget _set_disabled

# indica se il button deve essere staticamente sempre visualizzato (false) o se questo deve apparire nascosto e
# mostrarsi (true) quando l'utente tocca la sua area (in questo caso deve essere contenuto in un oggetto di tipo
# GamepadArea)
export var show_dynamically = false setget _set_show_dynamically

# questa proprietà contiene il nome dell'oggetto (che viene restituito nell'oggetto finger)
export var gamepad_type = "BUTTON 0"

# texture del button nello stato rilasciato
export(Texture) var texture_normal setget _set_texture_normal, _get_texture_normal

# texture del button nello stato premuto
export(Texture) var texture_pressed setget _set_texture_pressed, _get_texture_pressed

# texture del button nello stato disabilitato
export(Texture) var texture_disabled setget _set_texture_disabled, _get_texture_disabled

# contiene la reale posizione del button
export var static_position = Vector2(0, 0)

# indica l'intervallo di tempo tra un fire e l'altro quando il button rimane premuto
# se vale 0, l'utente dovrà rilasciare e premere nuovamente il button per emettere un nuovo segnale di fire
export var autofire_delay = 0.0

# per utilizzare uniformemente gli oggetti anche in presenza di tastiera, consento di associare
# direttamente un input map per premere il button
export var simulate_action = "ui_select"

###[ SIGNALS ]###################################################################################################

# viene emesso quando il button è premuto (una sola volta)
signal down(sender)

# viene emesso quando il button è rilasciato (una sola volta)
signal up(sender)

# viene emesso quando il pulsante è premuto ed agli intervalli dell'autofire
signal fire(sender)

###[ PRIVATE AND PUBLIC VARIABLES ]##############################################################################

# centro del button (ovvero della sua texture)
var center_point = Vector2(0,0)

# i dati del tocco (in modo che possano essere recuperati negli eventi)
var finger_data = null

# indica lo stato de button (se premuto - true - o rilasciato - false)
var is_pressed = false

# indica se sto simulando il button con la tastiera oppure no
var simulation = false

# mantiene lo stato della visualizzazione dinamica
var shown = true

###[ METHODS ]###################################################################################################

# costruisce l'albero dei nodi necessari all'oggetto prendendoli dal template
func _init():
	# se non sono già stati caricati
	if get_child_count() > 0: return
	# carico e istanzio il template
	var gamepad_button_template = load("res://addons/Gamepad/GamepadButtonTemplate.tscn").instance()
	# quindi se ci sono oggetti nel template (ovviamente si)
	if gamepad_button_template.get_child_count() > 0:
		# prendo ogni oggetto nel template
		for child in gamepad_button_template.get_children():
			# se l'oggetto è il timer
			if child is Timer:
				# ne creo il duplicato
				var tmr = child.duplicate()
				# lo aggiungo al mio nodo
				add_child(tmr)
				# connetto il suo segnale timeout allo script
				tmr.connect("timeout", self, "_on_AutofireTimer_timeout")
			else:
				# aggiungo un duplicato al mio nodo
				add_child(child.duplicate())

func _ready():
	# se l'oggetto deve essere visualizzato dinamicamente (ovvero solo quando l'utente tocca lo schermo) lo nascondo
	if show_dynamically:
		_hide_button()
	# imposto la sua posizione statica (non ha senso se visualizzato dinamicamente in quanto la sua posizione
	# varierà in base al tocco dell'utente)
	rect_position = static_position
	# ricavo i restanti valori che mi serviranno più avanti per fare i calcoli
	center_point = self.rect_size / 2

# emula il button tramite tastiera
func handle_input(event):
	# verifica quale tasto è stato premuto
	simulation = false
	# se il tasto premuto corrisponde a quello indicato
	if simulate_action and Input.is_action_pressed(simulate_action):
		simulation = true
		# e il button non era precedentemente premuto
		if !is_pressed:
			# inizializzo la posizione del'oggetto
			var ev = InputEventScreenTouch.new()
			ev.position = get_parent().rect_global_position + static_position + center_point
			# simulo la pressione del dito sul button
			handle_down_event(ev, null)
	else:
		# mentre se il tasto corrispondente non è premuto e il button lo era,
		if is_pressed:
			# simulo il rilascio del dito dal button
			handle_up_event(null, null)

# l'utente ha toccato lo schermo in corrispondenza del button o dell'area che contiene il button
func handle_down_event(event, finger):
	# se il button è disabilitato esco senza fare nulla (prima però resetto i dati interni)
	if disabled:
		is_pressed = false
		button.pressed = false
		return
	# altrimenti imposto i dati del tocco in modo che possano essere recuperati da fuori
	finger_data = finger
	# se il button deve essere visualizzato dinamicamente vuol dire che in questo momento non è visibile e quindi lo mostro
	if show_dynamically:
		_show_button(event)
	
	# comunico che il button è stato premuto
	emit_signal("down", self)
	# quindi gestisco il fire (e l'autofire)
	fire()
	
# l'utente ha sollevato il dito con cui aveva toccato il button o la sua area
func handle_up_event(event, finger):
	# se il button è disabilitato esco senza fare nulla (prima però resetto i dati interni)
	if disabled:
		is_pressed = false
		button.pressed = false
		return
	# altrimenti imposto i dati del tocco in modo che possano essere recuperati da fuori
	finger_data = finger
	# se il button deve essere visualizzato dinamicamente vuol dire che in questo momento è visibile e quindi lo nascondo
	if show_dynamically:
		_hide_button()

	# gestisco la fine del fire (e dell'autofire)
	fire_stop()
	# comunico che il button è stato rilasciato
	emit_signal("up", self)

# l'utente ha spostato il dito con cui aveva toccato il button o la sua area
func handle_move_event(event, finger):
	# non faccio nulla
	pass
#	if disabled: return

func _on_AutofireTimer_timeout():
	# il timer dell'autofire, semplicemente emette segnali fire all'intervallo stabilito, continuamente
	emit_signal("fire", self)

# gestione del fire (può essere richiamata anche esternamente)
func fire():
	if disabled: 
		# proprio perchè questa funzione può essere richiamata anche esternamente, 
		# se il button è disabilitato esco senza fare nulla (prima però resetto i dati interni)
		is_pressed = false
		button.pressed = false
		return
	# imposto lo stato di premuto
	button.pressed = true
	is_pressed = true
	# emetto il segnale fire
	emit_signal("fire", self)
	# e se l'autofire è impostato (ovvero se il suo delay è > 0)
	if autofire_delay > 0:
		# avvio il timer per l'autofire
		timer.wait_time = autofire_delay
		timer.start()

# gestione della fine del fire (può essere richiamata anche esternamente)
func fire_stop():
	# resetto lo stato interno
	button.pressed = false
	is_pressed = false
	# se il timer dell'autofire era partito, lo arresto
	timer.stop()	

# mostra il button
func _show_button(event):
	# se event è diverso dal null (nel caso in l'utente tocca il button o la sua area) calcolo la posizione
	# in base a quella passata nell'evento
	if shown: return
	shown = true
	if event:
		rect_global_position = event.position - center_point
	else:
		# altrimenti la posizione del button è quella statica impostata in static_position
		rect_position = static_position
	# avvio l'animazione di visualizzazione
	if fader:
		fader.stop()
		fader.play("fade_in", -1, 10)

# nasconde il button
func _hide_button():
	if !shown: return
	shown = false
	# avvia l'animazione di nascondimento
	if fader:
		fader.stop()
		fader.play("fade_out", -1, 10)

###[ SETTER/GETTER ]#############################################################################################

func _get_texture_normal():
	return $ButtonFace.texture_normal
	
func _set_texture_normal(value):
#	if !has_node("ButtonFace"): return
	$ButtonFace.texture_normal = value

func _get_texture_pressed():
	return $ButtonFace.texture_pressed
	
func _set_texture_pressed(value):
#	if !has_node("ButtonFace"): return
	$ButtonFace.texture_pressed = value

func _get_texture_disabled():
	return $ButtonFace.texture_disabled
	
func _set_texture_disabled(value):
#	if !has_node("ButtonFace"): return
	$ButtonFace.texture_disabled = value

func _set_disabled(value):
	disabled = value
#	if !has_node("ButtonFace"): return
	$ButtonFace.disabled = value
	
func _set_show_dynamically(value):
	show_dynamically = value
	# se sono nell'editor non faccio nulla (altrimenti mi verrebbe nascosto l'oggetto anche dall'editor)
	if Engine.editor_hint: return
	if value:
		_hide_button()
	else:
		_show_button(null)

###[ END ]#######################################################################################################