DECLARE PARAMETER alt IS SHIP:APOAPSIS.

FUNCTION executeNode {

	SET done TO FALSE.
	SET nd to nextnode.

	SET maxAccel TO SHIP:MAXTHRUST/SHIP:MASS.
	SET burnDuration TO nd:deltav:mag/maxAccel.
	
	//timewarp to start of maneuver
	KUNIVERSE:TIMEWARP:WARPTO( TIME:SECONDS+(NEXTNODE:ETA-(burnDuration/2)) ).
	
	SET np TO nd:deltav.
	LOCK STEERING TO np.
	
	WAIT UNTIL VANG(np, SHIP:FACING:VECTOR) < 0.25.
	
	WAIT UNTIL nd:ETA <= (burnDuration/2).
	
	SET throttleSet to 0.
	LOCK THROTTLE TO throttleSet.
	
	SET dv0 TO nd:deltav.
	UNTIL done {
		
			SET maxAccel TO SHIP:MAXTHRUST/SHIP:MASS.
			SET throttleSet TO MIN(nd:deltav:mag/maxAccel, 1).
			
			IF vdot(dv0, nd:deltav) < 0
			{
				LOCK THROTTLE TO 0.
				BREAK.
			}
			
			IF nd:deltav:mag < 0.1
			{
				WAIT UNTIL vdot(dv0, nd:deltav) < 0.5.
				LOCK THROTTLE TO 0.
				SET done TO TRUE.
			}
	
	}
	
	UNLOCK STEERING.
	UNLOCK THROTTLE.
	WAIT 1.
	
	REMOVE nd.
	SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
}

//Create maneuver node for circularization and calculate deltav for circularization
SET rAP TO alt+BODY:RADIUS. //circularization altitude in meters from the surface
SET rPE TO SHIP:PERIAPSIS.

SET dvCirc TO SQRT(BODY:MU/rAP) - SQRT( (rPE*BODY:MU) / (rAP*(rPE+rAP)/2) ).
SET n TO NODE(ETA:APOAPSIS, 0, 0, dvCirc).

ADD n.

executeNode().