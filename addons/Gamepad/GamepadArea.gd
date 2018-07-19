###[ INFO ]######################################################################################################

# Component: GamepadArea
# Author: Francesco Iafulli (fiaful)
# Version: 1.0
# Last modify: 2018-07-18

# What is this:
# E' un nodo facoltativo. Le sue funzioni sono 2 (una esclude l'altra):
#	- consentire agli elementi del gamepad di essere visualizzati solo quando lo schermo viene toccato e nel punto
#		in cui viene toccato, ed essere invisibili il restante tempo
#	- raggruppare oggetti sempre visibili del gamepad in modo da poter essere disabilitati in maniera cumulativa

# Requirements:
#	- il parent di questo nodo deve essere di tipo GamepadContainer, altrimenti gli eventi non verranno intercettati
#	- l'area di questo oggetto deve essere estesa a tutta la zona che si desidera avere sesibile per la visualizzazione
#		dell'oggetto del gamepad in maniera dinamica -oppure- deve essere estesa in modo da poter contenere tutti
#		gli oggetti che si desidera abilitare/disabilitare contemporaneamente
#	- dovrà essere contenuto un solo oggetto se questo deve essere visualizzato in maniera dinamica, altrimenti
#		tutti gli oggetti che si desirea abilitare/disabilitare contemporaneamente dovranno essere qui contenuti

# To do:
#   - gestire una eventuale visualizzazione dell'area al tocco qualora lo si desideri

# Changelog:
#
#

###[ BEGIN ]#####################################################################################################

extends Control

###[ CONSTS ]####################################################################################################

# è utilizzato per discriminare se questo nodo è un'area (viene controllata la presenza di questa costante, se c'è il nodo
# è di tipo GamepadArea, altrimenti no
const is_area = true

###[ EXPORTED VARIABLES ]########################################################################################

# indica se l'intera area (e gli oggetti in essa contenuti) devono essere disabilitati (se true, nessuno degli oggetti 
# contenuti riceverà i tocchi dell'utente)
export var disabled = false

# questa proprietà contiene il nome dell'oggetto (che viene restituito nell'oggetto finger)
export var gamepad_type = "AREA 0"

###[ METHODS ]###################################################################################################

# dal GamepadContainer viene richiamato questo metodo se l'utente tocca quest'area
func handle_down_event(event, finger):
	# se l'oggetto è disabilitato esco, non propagando l'evento agli oggetti contenuti
	if disabled:
		return
	# altrimenti per ogni oggetto contenuto
	for child in get_children():
		# se l'oggetto è un oggetto del gamepad
		if child.has_method("handle_down_event"):
			# aggiorno l'oggetto associato all'istanza corrente di finger
			finger.set_finger(finger.index, child, finger.position)
			# quindi chiedo all'oggetto contenuto di gestire l'evento
			child.handle_down_event(event, finger)
	
func handle_up_event(event, finger):
	# se l'oggetto è disabilitato esco, non propagando l'evento agli oggetti contenuti
	if disabled:
		return
	# altrimenti per ogni oggetto contenuto
	for child in get_children():
		# se l'oggetto è un oggetto del gamepad
		if child.has_method("handle_up_event"):
			# aggiorno l'oggetto associato all'istanza corrente di finger
			finger.set_finger(finger.index, child, finger.position)
			# quindi chiedo all'oggetto contenuto di gestire l'evento
			child.handle_up_event(event, finger)
	
func handle_move_event(event, finger):
	# se l'oggetto è disabilitato esco, non propagando l'evento agli oggetti contenuti
	if disabled:
		return
	# altrimenti per ogni oggetto contenuto
	for child in get_children():
		# se l'oggetto è un oggetto del gamepad
		if child.has_method("handle_move_event"):
			# aggiorno l'oggetto associato all'istanza corrente di finger
			finger.set_finger(finger.index, child, finger.position)
			# quindi chiedo all'oggetto contenuto di gestire l'evento
			child.handle_move_event(event, finger)

###[ END ]#######################################################################################################