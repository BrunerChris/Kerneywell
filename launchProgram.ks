//execute by run launchProgram(apoapsis, turn). where apoapsis and turn are scalars greater 
//than 0 and neither parameter is required.

DECLARE PARAMETER apoAlt IS 90000.
DECLARE PARAMETER turnAlt IS 7000.
SET terminate TO FALSE.

FUNCTION pitch_of_vector { // pitch_of_vector returns the pitch of the vector relative to the ship (number range -90 to  90)
    PARAMETER vecT.

    RETURN 90 - VANG(SHIP:UP:VECTOR, vecT).
}

FUNCTION jettison_fairing { //jettison any fairings on the spacecraft
	
	FOR part IN SHIP:MODULESNAMED("ModuleProceduralFairing") {
		part:DOEVENT("deploy").
	}
	
	FOR part IN SHIP:MODULESNAMED("ProceduralFairingDecoupler") {
		part:DOEVENT("jettison").
	}
	
}

FUNCTION deploy_attachments { //deploy solar panels and antennas

	PANELS ON.
	
	SET antennas TO LIST().
	FOR antenna IN SHIP:MODULESNAMED("ModuleRTAntenna") {
		IF antenna:PART:MODULES:CONTAINS("ModuleAnimateGeneric") {
			antennas:ADD(antenna:PART).
		}
	}
	
	FOR antenna IN antennas {
		antenna:GETMODULE("ModuleRTAntenna"):DOACTION("Activate",TRUE).
	}
	
}

LOCK STEERING TO HEADING(90,90).
LOCK THROTTLE TO (1.0).

WHEN THROTTLE <> 0 THEN{

	STAGE.
	
	WHEN ALTITUDE > 1000 THEN { //at 1000m pitch to 85deg above horizon eastbound
		
		SET prevPitch TO 85.
		SET prevHeading TO 90.
		LOCK STEERING TO HEADING(prevHeading, prevPitch).
		
	}
	
	//pitch change logic here
	WHEN ALTITUDE > turnAlt THEN { 
		
		IF(NOT SAS){

			SET progradeAngle TO pitch_of_vector(SHIP:SRFPROGRADE:FOREVECTOR).
			SET prevPitch TO MIN(MAX(prevPitch, progradeAngle-5), progradeAngle+5).
			
			LOCK STEERING TO HEADING(prevHeading, prevPitch-5).
			
			SET now TO TIME:SECONDS.
			WAIT UNTIL TIME:SECONDS > now+3.
			
			PRINT(progradeAngle + " , " + prevPitch).
			SET prevPitch TO SHIP:FACING:PITCH.
			
			WHEN prevPitch +10 >= progradeAngle OR prevPitch -10 <= progradeAngle THEN {
			
				LOCK STEERING TO HEADING(prevHeading, prevPitch).
				UNLOCK STEERING.
				SAS ON.

				WAIT 0.
				SET SASMODE TO "PROGRADE".

			}
			
		}
		
		PRESERVE.
	}
	
	WHEN ALTITUDE > 0.95 * BODY:ATM:HEIGHT {

		jettison_fairing.
		
		WHEN ALTITUDE > BODY:ATM:HEIGHT {
			deploy_attachments.
		}

	}
	
}

//autostaging logic
WHEN MAXTHRUST = 0 THEN {
	STAGE.
	PRESERVE.
}

//cut throttle and setup for circularizing
WHEN SHIP:APOAPSIS + 5000 >= apoAlt THEN { 
	LOCK THROTTLE TO 0.
	UNLOCK THROTTLE.
	UNLOCK STEERING.
	SAS OFF.
	
	//RUN circularizeProgram.
	
	SET terminate TO TRUE.
}

WAIT UNTIL terminate.
