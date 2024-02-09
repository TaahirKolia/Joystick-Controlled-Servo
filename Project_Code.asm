;______________________________________________________________________________
;| Name :  Taahir	        Surname : Kolia				       |
;| Student Number : 2423748						       |
;| Project Title: Joystick Controlled Servo				       |
;|_____________________________________________________________________________|
    
    
    
 ; TODO INSERT CONFIG CODE HERE USING CONFIG BITS GENERATOR
 __CONFIG _CONFIG1, _FEXTOSC_ECM & _RSTOSC_HFINT1 & _CLKOUTEN_OFF & _CSWEN_ON & _FCMEN_ON
 ;set HFINTOSC to have a frequenecy of 1MHz 
 ;(when OSCFRQ IS 4MHz and and CDIV has clock divider of 4)
 __CONFIG _CONFIG3, _WDTCPS_WDTCPS_31 & _WDTE_OFF & _WDTCWS_WDTCWS_7 & _WDTCCS_SC
 ;watch dog timer is disabled
 
#include "p16f18446.inc"
    
RES_VECT  CODE    0x0000            ; processor reset vector
    GOTO    START                   ; go to beginning of program
    
MAIN_PROG CODE                      ; let linker place main program

START

;_______________________________________________________________________________
 
; Variable declaration 
 
    ShiftedValue1 equ 0x50	 ; stores ADRESH after one logical right shift
    ReducedValue equ 0x51	 ; stores ADRESH after two logical right shifts 
				 ; and subtracting 5
;_______________________________________________________________________________
 
 ;Port initialisation

  banksel TRISA	
  clrf TRISA			;TRISA is an output
  clrf ANSELA			;ANSELA is digital
  clrf LATA			;LATA is on 
    
  bsf TRISA, 4			;TRISA,4 is an input
  banksel ANSELA
  bsf ANSELA, 4			;ANSELA,4 is analogue

;_______________________________________________________________________________
 
 ;Configuring the clock divider
 
 banksel OSCCON1														
 bsf OSCCON1,0			;set the clock divider to 2									
 bcf OSCCON1,1			;results in HFINTOSC having									
 bcf OSCCON1,2			;a frequency of 2MHz										
 bcf OSCCON1,3		
 
;_______________________________________________________________________________
                                                                   
 ;Configuring the PWM module
 
 banksel TRISA			;TRISA,1 is an input                                                           
 bsf TRISA,1			;PWM pin is disabled	

 banksel PWM6CON		;the PWM6CON register is cleared
 clrf PWM6CON			;therefore the pwm signal is disabled 

 banksel T2PR			;move a value of 77
 movlw b'01001101'		;to the T2PR register
 movwf T2PR			;to get a period of 20ms
				
 banksel PWM6DCH		;load the PWM6DCH register with the MSB
 movlw b'00000110'		;these bits will be changed using ADRESH
 movwf PWM6DCH			;to vary the pulse width and duty cycle

 banksel PWM6DCL		;load the PWM6DCL [7:6] bits with the LSB
 movlw b'01000000'		;these bits will be changed using ADRESL
 movwf PWM6DCL			;to vary the pulse width and duty cycle	

;_______________________________________________________________________________

 ;Configuring the Timer2 module
 
 banksel T2CLKCON
 movlw b'0001'			;timer clock source is set as FOSC/4
 movwf T2CLKCON
 
 banksel T2CON				 
 bsf T2CON,7			;Timer2 is enabled
 bsf T2CON,6			;with a 1:128 prescaler 
 bsf T2CON,5
 bsf T2CON,4

;_______________________________________________________________________________

 ;Configuring the PWM module
 			
 banksel TRISA			;TRISA,1 is an output
 bcf TRISA,1			;PWM pin is enabled
 
 banksel RA1PPS
 movlw b'001101'		;move the signal from PWM6OUT
 movwf RA1PPS			;to the RA1 register
 
 banksel PWM6CON
 bsf PWM6CON,7			;turn the PWM module on
 bcf PWM6CON,5		
 bcf PWM6CON,4			;PWM signal is set to normal
 
;_______________________________________________________________________________
 
 ;Configuring the ADC
 
 
 banksel ADCON0
 bsf ADCON0,7			 ;the ADC module is enabled
 bsf ADCON0,6			 ;the ADC is in continuous mode
 bcf ADCON0,4			 ;clock supplied by FOSC
 bcf ADCON0,2			 ;ADRES is left justified
 bsf ADCON0,0			 ;ADC conversion is in progress
 
 banksel ADPCH
 movlw b'000100'		 ;move the value from the RA4 register
 movwf ADPCH			 ;to the ADPCH
 
 banksel ADCLK
 movlw b'000001'		 ; ADC clock frequency is FOSC/4
 movwf ADCLK
 
;_______________________________________________________________________________
 
 ;Operations to transfer the ADC values to the PWM registers
 
  ADRES_TO_PWM6DC:
    
    
	banksel ADRESH			; logical right shift the value in 
	lsrf    ADRESH, 0		; ADRESH to divide the value in ADRESH 
					; by 2 and store it in the w register
					
	banksel 0x50			; move the value of ADRESH stored in the 
	movwf   ShiftedValue1		; w register to the f register of the variable
	lsrf    ShiftedValue1, 0	; logical right shift the value in ADRESH  
					; to divide the value in ADRESH
					; by 2 and store it in the w register
					
	sublw   b'0101'			; subtract 5 from the w register 
 
	banksel 0x51			; store the value from the w register in the 
	movwf ReducedValue		; the f reister of the variable
	movf ReducedValue,w		; move the value of the variable from 
					; the f register to the w register
	
	banksel PWM6DCH			; move the value of the w register to the
	movwf	PWM6DCH			; PWM6DCH register 
	bcf PWM6DCH,7			; clear bit 7 and 6 of the PWM6DCH register 
	bcf PWM6DCH,6
	
	banksel ADRESL			; move the value of ADRESL from the
	movf ADRESL,W			; f register to the w register
	
	banksel PWM6DCL			; move the value from the w register to
	movwf PWM6DCL			; the f register of PWM6DCL

    
    goto    ADRES_TO_PWM6DC
 
;____________________________________________________________________________
 
 
    
    END