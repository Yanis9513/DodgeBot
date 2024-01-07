	;; RK - Evalbot (Cortex M3 de Texas Instrument)
; programme - Pilotage 2 Moteurs Evalbot par PWM tout en ASM (Evalbot tourne sur lui même)
		
		
		
		AREA    |.text|, CODE, READONLY
		
; This register controls the clock gating logic in normal Run mode
SYSCTL_PERIPH_GPIO EQU		0x400FE108	; SYSCTL_RCGC2_R (p291 datasheet de lm3s9b92.pdf)

; The GPIODATA register is the data register
GPIO_PORTF_BASE		EQU		0x40025000	; GPIO Port F (APB) base: 0x4002.5000 (p416 datasheet de lm3s9B92.pdf)

; The GPIODATA register is the data register
GPIO_PORTD_BASE		EQU		0x40007000		; GPIO Port D (APB) base: 0x4000.7000 (p416 datasheet de lm3s9B92.pdf)

; The GPIODATA register is the data register
GPIO_PORTE_BASE		EQU		0x40024000		; GPIO Port E (APB) base: 0x4002.4000 (p416 datasheet de lm3s9B92.pdf)

; configure the corresponding pin to be an output
; all GPIO pins are inputs by default
GPIO_O_DIR   		EQU 	0x00000400  ; GPIO Direction (p417 datasheet de lm3s9B92.pdf)

; The GPIODR2R register is the 2-mA drive control register
; By default, all GPIO pins have 2-mA drive.
GPIO_O_DR2R   		EQU 	0x00000500  ; GPIO 2-mA Drive Select (p428 datasheet de lm3s9B92.pdf)

; Digital enable register
; To use the pin as a digital input or output, the corresponding GPIODEN bit must be set.
GPIO_O_DEN  		EQU 	0x0000051C  ; GPIO Digital Enable (p437 datasheet de lm3s9B92.pdf)

; Pul_up
GPIO_I_PUR   		EQU 	0x00000510  ; GPIO Pull-Up (p432 datasheet de lm3s9B92.pdf)

; Broches select
BROCHE4_5			EQU		0x30		; led1 & led2 sur broche 4 et 5

BROCHE6				EQU 	0x40		; bouton poussoir 1
	
BROCHE7				EQU		0x80		; bouton poussoir 2

BROCHE6_7			EQU 	0xC0		; bouton poussoit 1 et 2
	
BROCHE0				EQU		0x01		;bumper 1

BROCHE1				EQU 	0x02		;bumper 2
	
BROCHE0_1			EQU  	0x03		;bumper 1 et 2
	
Led_Off				EQU		0x00		;pour eteindre une led 
	
; blinking frequency
DUREE   			EQU     0x0005FFFF
	
; turn frequency
DUREE_TURN   		EQU     0x015FFFFF

; Dodge frequency
DUREE_DODGE			EQU		0x015FFFFF
			
			
		ENTRY
		EXPORT	__main    
		
		;; The IMPORT command specifies that a symbol is defined in a shared object at runtime.
		IMPORT	MOTEUR_INIT					; initialise les moteurs (configure les pwms + GPIO)
		
		IMPORT	MOTEUR_DROIT_ON				; activer le moteur droit
		IMPORT  MOTEUR_DROIT_OFF			; déactiver le moteur droit
		IMPORT  MOTEUR_DROIT_AVANT			; moteur droit tourne vers l'avant
		IMPORT  MOTEUR_DROIT_ARRIERE		; moteur droit tourne vers l'arrière
		IMPORT  MOTEUR_DROIT_INVERSE		; inverse le sens de rotation du moteur droit
		
		IMPORT	MOTEUR_GAUCHE_ON			; activer le moteur gauche
		IMPORT  MOTEUR_GAUCHE_OFF			; déactiver le moteur gauche
		IMPORT  MOTEUR_GAUCHE_AVANT			; moteur gauche tourne vers l'avant
		IMPORT  MOTEUR_GAUCHE_ARRIERE		; moteur gauche tourne vers l'arrière
		IMPORT  MOTEUR_GAUCHE_INVERSE		; inverse le sens de rotation du moteur gauche


__main	

		; ;; Enable the Port F & D peripheral clock 		(p291 datasheet de lm3s9B96.pdf)
		; ;;									
		ldr r6, = SYSCTL_PERIPH_GPIO  			;; RCGC2
        mov r0, #0x00000038  					;; Enable clock sur GPIO D et F où sont branchés les leds (0x28 == 0b101000)
		; ;;														 									      (GPIO::FEDCBA)
        str r0, [r6]
		
		; ;; "There must be a delay of 3 system clocks before any GPIO reg. access  (p413 datasheet de lm3s9B92.pdf)
		nop	   									;; tres tres important....
		nop	   
		nop	   									;; pas necessaire en simu ou en debbug step by step...
	
		;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^CONFIGURATION LED

        ldr r6, = GPIO_PORTF_BASE+GPIO_O_DIR    ;; 1 Pin du portF en sortie (broche 4 : 00010000)
        ldr r0, = BROCHE4_5
        str r0, [r6]
		
		ldr r6, = GPIO_PORTF_BASE+GPIO_O_DEN	;; Enable Digital Function 
        ldr r0, = BROCHE4_5		
        str r0, [r6]
		
		ldr r6, = GPIO_PORTF_BASE+GPIO_O_DR2R	;; Choix de l'intensité de sortie (2mA)
        ldr r0, = BROCHE4_5			
        str r0, [r6]
		
		mov r2, #0x000       					;; pour eteindre LED
     
		mov r3, #BROCHE4_5		;; Allume LED1&2 portF broche 4&5 : 00110000
		
		ldr r8, = GPIO_PORTF_BASE + (BROCHE4_5<<2)  ;; @data Register = @base + (mask<<2) ==> LED1
		;vvvvvvvvvvvvvvvvvvvvvvvFin configuration LED 


		;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^CONFIGURATION switch 1 & 2

		ldr r6, = GPIO_PORTD_BASE+GPIO_I_PUR	;; Pul_up 
        ldr r0, = BROCHE6_7	
        str r0, [r6]
		
		ldr r6, = GPIO_PORTD_BASE+GPIO_O_DEN	;; Enable Digital Function 
        ldr r0, = BROCHE6_7	
        str r0, [r6]     
		
		ldr r7, = GPIO_PORTD_BASE + (BROCHE6_7<<2)  ;; @data Register = @base + (mask<<2) ==> Switcher
		
		
		;vvvvvvvvvvvvvvvvvvvvvvvFin configuration switch 1 & 2
		
		
		;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^CONFIGURATION bumper 1 & 2
		
		ldr r6, = GPIO_PORTE_BASE+GPIO_I_PUR	;; Pul_up 
        ldr r0, = BROCHE0_1	
        str r0, [r6]
		
		ldr r6, = GPIO_PORTE_BASE+GPIO_O_DEN	;; Enable Digital Function 
        ldr r0, = BROCHE0_1	
        str r0, [r6]     
		
		ldr r9, = GPIO_PORTE_BASE + (BROCHE0_1<<2)  ;; @data Register = @base + (mask<<2) ==> Bumper
		;vvvvvvvvvvvvvvvvvvvvvvvFin configuration bumper 
		
		BL	MOTEUR_INIT	

Moteur_Off
		BL MOTEUR_DROIT_OFF
		BL MOTEUR_GAUCHE_OFF
		
ReadState_Launch
		mov r12, #0x00
		ldr r10,[r7]
		CMP r10,#0x80
		str r2, [r8]
		BNE ReadState_Launch      		
		str r3,[r8] 
		
loop	
		; Activer les deux moteurs droit et gauche
		BL	MOTEUR_DROIT_ON
		BL	MOTEUR_GAUCHE_ON
		
		; Evalbot avance droit devant
		BL	MOTEUR_DROIT_AVANT	   
		BL	MOTEUR_GAUCHE_AVANT
		
		ldr r4,[r9]
				
		BL	BumperState
		
		BL  BumperState_Both
		
		BL	ReadState_Stop
		
		str r2, [r8] ;eteindre led1 et led2
		ldr r11, = DUREE 		
		
wait	
		;éteins les deux leds pendant DUREE puis l'allume après DUREE
		BL	BumperState
		BL 	BumperState_Both
		
		subs r11, #1
		BNE wait
		
		str r3, [r8]  							;; Allume LED1&2 portF broche 4&5 : 00110000 (contenu de r3)
        ldr r11, = DUREE						;; pour la duree de la boucle d'attente (wait1)
		
wait1	
		;allume les deux leds pendant DUREE puis l'allume après DUREE
		BL	BumperState
		BL 	BumperState_Both
		
		subs r11, #1
		BNE wait1
		
		b	loop

BumperState
		;compare avec le bumper de droite
		CMP r4,#0x01
		BEQ Turn_Left
		
		;compare avec le bumper de gauche
		CMP r4, #0x02
		BEQ Turn_Right
		BX	LR

Turn_Right
		;tourne à droite puis va tout droit
		ADD r12, r12, #1
		BL 	MOTEUR_GAUCHE_ARRIERE
		ldr r5, = DUREE_TURN
		str r3, [r8] 
		BL	wait_turn
		mov	r4,#0x01
		BL	Go_Straight


Turn_Left
		;tourne à gauche puis va tout droit
		ADD r12, r12, #1
		BL 	MOTEUR_DROIT_ARRIERE
		ldr r5, = DUREE_TURN
		str r3, [r8] 
		BL	wait_turn
		mov	r4,#0x02
		BL	Go_Straight
		
Go_Straight
		;Avance tout droit et tourne dans la direction opposés d'avant
		BL	MOTEUR_DROIT_AVANT	   
		BL	MOTEUR_GAUCHE_AVANT
		ldr r5, = DUREE_DODGE
		str r3, [r8] 
		BL	wait_turn
		
		CMP	r4, #0x01
		BEQ	Left_One
		
		CMP	r4, #0x02
		BEQ	Right_One

Left_One
		;tourne à gauche une seule fois
		BL 	MOTEUR_DROIT_ARRIERE
		ldr r5, = DUREE_TURN
		BL	wait_turn
		b 	loop
		
Right_One
		;tourne à droite une seule fois
		BL 	MOTEUR_GAUCHE_ARRIERE
		ldr r5, = DUREE_TURN
		BL	wait_turn
		b	loop
		
wait_turn
		;attends une certaines durée
		subs r5, #1
		BNE wait_turn
		BX	LR

BumperState_Both
		;compare avec les deux bumpers et renvoi vers l'affichage
		CMP r4, #0x00
		BEQ	Affichage
		BX	LR
		
ReadState_Stop
		;pour envoyer vers l'affiche en cas de clique sur le bouton
		ldr r10,[r7]
		CMP r10,#0x40
		BEQ	Affichage
		BX	LR 

Affichage
		;affiche le nombre d'obstacle et repart au début
		
		
		NOP
        END
