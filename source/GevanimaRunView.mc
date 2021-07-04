using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;

class GevanimaRunView extends Ui.DataField {
    hidden var timerTime = 0, currentSpeed = 0, currentCadence = 0, currentHeartRate = 0, currentPower = 0, currentLocationAccuracy = 0, currentTimeHour = System.getClockTime().hour, currentTimeMinute = System.getClockTime().min;  
    hidden var averageSpeed = 0, averageCadence = 0, averageHeartRate = 0, averagePower = 0;
    hidden var maxSpeed = 0, maxCadence = 0, maxHeartRate = 0, maxPower = 0;
    hidden var onTimerLapTime = 0, onTimerLapDistance = 0, elapsedTime = 0, elapsedDistance = 0, totalAscent = 0, totalDescent = 0, trainingEffect = 0, calories = 0;
    hidden var lapSpeed = 0, lapTime = 0, lapDistance = 0, battery = 0;
    hidden var unitPace = 1000.0, unitDist = 1000.0;
  	
    // true     => Force the backlight to stay on permanently
    // false    => Use the defined backlight timeout as normal  
    hidden var uBacklight = false;
    hidden var mTimerRunning = false;
    hidden var mStartStopPushed = 0;    // Timer value when the start/stop button was last pushed   
    
    hidden var xCenter = 0, yCenter = 0, minRad = 0, hourRad = 0, minAngle = 0, hourAngle = 0; 
    hidden var twoPI = Math.PI *2;
    
    hidden var currentSport = UserProfile.getCurrentSport();
    hidden var heartRateZones = UserProfile.getHeartRateZones(currentSport); //min zone 1, max zone 1, max zone 2, max zone 3, max zone 4, max zone 5
	hidden var cadenceZones = [100, 153, 164, 174, 183, 200]; 
    hidden var heartRateZonesColors = [Gfx.COLOR_LT_GRAY, Gfx.COLOR_BLUE, Gfx.COLOR_GREEN, Gfx.COLOR_ORANGE, Gfx.COLOR_RED];
    hidden var cadenceZonesColors = [Gfx.COLOR_RED, Gfx.COLOR_ORANGE, Gfx.COLOR_GREEN, Gfx.COLOR_BLUE, Gfx.COLOR_PURPLE];
    hidden var locationAccuracyColors = [Gfx.COLOR_PURPLE, Gfx.COLOR_RED, Gfx.COLOR_ORANGE, Gfx.COLOR_BLUE, Gfx.COLOR_GREEN];

	hidden var backgroundColor, textColor, headerColor;
	hidden var center = Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER;

    // Set your layout here. Anytime the size of obscurity of
    // the draw context is changed this will be called.
    function onLayout(dc) {
    	xCenter = dc.getWidth() / 2;
        yCenter = dc.getHeight() / 2;
        // Analog clock
        minRad = 8/10.0 * xCenter;
      	hourRad = 2/4.0 * minRad;
        return true;
    }

    // Display the value you computed here. This will be called
    // once a second when the data field is visible.
    function onUpdate(dc) {
        setColors(dc);
		drawValues(dc);
    }

    function initialize() {
        DataField.initialize();
    }

    // The given info object contains all the current workout information.
    // Calculate a value and save it locally in this method.
    // Note that compute() and onUpdate() are asynchronous, and there is no
    // guarantee that compute() will be called before onUpdate().
    function compute(info) {   
        currentSpeed = info.currentSpeed != null ? info.currentSpeed : 0.0f;        
        currentCadence = info.currentCadence != null ? info.currentCadence : 0.0f;
        currentHeartRate = info.currentHeartRate != null ? info.currentHeartRate : 0.0f;
		currentPower = info.currentPower != null ? info.currentPower : 0.0f;
		currentLocationAccuracy = info.currentLocationAccuracy != null ? info.currentLocationAccuracy : 0d;
		timerTime = info.timerTime != null ? info.timerTime : 0.0f;   

		currentTimeHour = System.getClockTime().hour;
		currentTimeMinute = System.getClockTime().min;

    	battery =  System.getSystemStats().battery != null ?  System.getSystemStats().battery : 0.0f;

        averageSpeed = info.averageSpeed != null ? info.averageSpeed : 0.0f;
        averageCadence = info.averageCadence != null ? info.averageCadence : 0.0f;
        averageHeartRate = info.averageHeartRate != null ? info.averageHeartRate : 0.0f;
        averagePower = info.averagePower != null ? info.averageSpeed : 0.0f;
        
        maxSpeed = info.maxSpeed != null ? info.maxSpeed : 0.0f;
        maxCadence = info.maxCadence != null ? info.maxCadence : 0.0f;
        maxHeartRate = info.maxHeartRate != null ? info.maxHeartRate : 0.0f;
        maxPower = info.maxPower != null ? info.maxPower : 0.0f;
                 
        elapsedTime = info.elapsedTime != null ? info.elapsedTime : 0.0f;
        elapsedDistance = info.elapsedDistance != null ? info.elapsedDistance : 0.0f;
        totalAscent = info.totalAscent != null ? info.totalAscent : 0.0f;
        totalDescent = info.totalDescent != null ? info.totalDescent : 0.0f;
    	trainingEffect = info.trainingEffect != null ? info.trainingEffect : 0.0f;
    	calories = info.calories != null ? info.calories : 0.0f;

    	lapTime = timerTime - onTimerLapTime;
    	lapDistance = elapsedDistance - onTimerLapDistance;    	
    	lapSpeed = lapTime != 0 ? lapDistance / lapTime * 1000 : lapSpeed;
    	
        // If enabled, switch the backlight on in order to make it stay on
        if (uBacklight) {
            Attention.backlight(true);
        }
    }
    
    // Timer transitions from stopped to running state
    function onTimerStart() {
        startStopPushed();
        mTimerRunning = true;
    }


    // Timer transitions from running to stopped state
    function onTimerStop() {
        startStopPushed();
        mTimerRunning = false;
    }


    // Timer transitions from paused to running state (i.e. resume from Auto Pause is triggered)
    function onTimerResume() {
        mTimerRunning = true;
    }


    // Timer transitions from running to paused state (i.e. Auto Pause is triggered)
    function onTimerPause() {
        mTimerRunning = false;
    }

    function onTimerLap() {      	
      	onTimerLapTime = timerTime; 
      	onTimerLapDistance = elapsedDistance;
    }
	
    function setColors(dc) {
        backgroundColor = (self has :getBackgroundColor) ? getBackgroundColor() : Gfx.COLOR_WHITE;
        if (backgroundColor == Gfx.COLOR_BLACK) {
            textColor = Gfx.COLOR_WHITE;	
            headerColor = Gfx.COLOR_LT_GRAY;
        } else {
            textColor = Gfx.COLOR_BLACK;
            headerColor = Gfx.COLOR_DK_GRAY;            
        }
        dc.setColor(backgroundColor, backgroundColor);
        dc.clear(); 
    }
    
    function drawValues(dc) {
    	// Analog clock
    	minAngle = (currentTimeMinute/60.0)*twoPI;
    	hourAngle = ((currentTimeHour%12)/12.0)*twoPI;
    	dc.setColor(headerColor, Gfx.COLOR_TRANSPARENT);
        dc.setPenWidth(5);
        dc.drawLine(xCenter, yCenter,
        (xCenter + hourRad * Math.sin(hourAngle+minAngle/12)),
        (yCenter - hourRad * Math.cos(hourAngle+minAngle/12)));
        dc.setPenWidth(3);
        dc.drawLine(xCenter, yCenter,
        (xCenter + minRad * Math.sin(minAngle)),
        (yCenter - minRad * Math.cos(minAngle)));
        
        // Horizontal
        dc.setPenWidth(7);
        for (var j = 0; j < 5; ++j) {
			dc.setColor(cadenceZonesColors[j], Gfx.COLOR_TRANSPARENT);
			dc.drawLine(xCenter-95+j*40, yCenter,xCenter-65+j*40, yCenter);
		}
		dc.setColor(backgroundColor, backgroundColor);
    	dc.fillCircle(xCenter+60, yCenter, 8);
		dc.setColor(textColor, textColor);
    	dc.fillCircle(xCenter+60, yCenter, 4);
		
        // Arcs
        drawZoneBarsArcs(dc, yCenter+1, xCenter, yCenter, currentHeartRate, heartRateZones, 0.0, 30.0, heartRateZonesColors);
        drawZoneBarsArcs(dc, yCenter+1, xCenter, yCenter, currentCadence, cadenceZones, 180.0, 30.0, cadenceZonesColors);
                
        // Values
        dc.setColor(textColor, Gfx.COLOR_TRANSPARENT);

        dc.drawText(xCenter+75, yCenter-30, Gfx.FONT_NUMBER_MEDIUM, currentCadence.format("%03d"), center);
        dc.drawText(xCenter+15, yCenter-30, Gfx.FONT_NUMBER_MEDIUM, frmtPace(currentSpeed), center);
        dc.drawText(xCenter-55, yCenter-30, Gfx.FONT_NUMBER_MEDIUM, frmtDist(elapsedDistance), center);

        dc.drawText(xCenter-75, yCenter+24, Gfx.FONT_NUMBER_MEDIUM, currentHeartRate.format("%03d"), center);
        dc.drawText(xCenter-15, yCenter+24, Gfx.FONT_NUMBER_MEDIUM, frmtPace(lapSpeed), center);
        dc.drawText(xCenter+55, yCenter+24, Gfx.FONT_NUMBER_MEDIUM, frmtDist(lapDistance), center); 
       
		dc.drawText(xCenter+35, yCenter-70, Gfx.FONT_MEDIUM, totalAscent.format("%0d"), center);
        dc.drawText(xCenter+25, yCenter+70, Gfx.FONT_MEDIUM, frmtTime(lapTime), center);        
		dc.drawText(xCenter-25, yCenter-70, Gfx.FONT_MEDIUM, frmtTime(elapsedTime), center);
        dc.drawText(xCenter-35, yCenter+70, Gfx.FONT_MEDIUM, battery.format("%0d"), center);
		
		// Headers
		dc.setColor(headerColor, Gfx.COLOR_TRANSPARENT);

		dc.drawText(xCenter+30, yCenter-54, Gfx.FONT_SYSTEM_XTINY , "ASC", center);
		dc.drawText(xCenter-30, yCenter-54, Gfx.FONT_SYSTEM_XTINY , "CURRENT", center);
		dc.drawText(xCenter+60, yCenter-54, Gfx.FONT_SYSTEM_XTINY , "CD", center);

		dc.drawText(xCenter+30, yCenter+54, Gfx.FONT_SYSTEM_XTINY , "LAP", center);
		dc.drawText(xCenter-30, yCenter+54, Gfx.FONT_SYSTEM_XTINY , "BAT", center);
		dc.drawText(xCenter-60, yCenter+54, Gfx.FONT_SYSTEM_XTINY , "HR", center);

        drawRectangles(dc, currentLocationAccuracy, xCenter, yCenter+84, locationAccuracyColors);
	}

    function drawRectangles(dc, amt, posX, posY, pallete){
        var x = posX - (amt * 7 + (amt - 1) * 5) / 2;
        dc.setColor(pallete[amt], pallete[amt]);
        for (var i = 0; i < amt; i++) {
            dc.fillRectangle(x + i * 12, posY, 7, 7);
        }
    }
	
	function drawZoneBarsArcs(dc, radius, centerX, centerY, measurement, zones, angStart, angDiff, cirColor){
		var zone = 0;
		measurement = measurement > zones[5] ? zones[5] : measurement;
		for (var j = 4; j >= 0; --j) {
			dc.setColor(cirColor[j], Gfx.COLOR_TRANSPARENT);
			if (measurement>zones[j]&&zone==0){
				dc.setPenWidth(14); zone = j+1;
				dc.drawArc(centerX, centerY, radius - 14/2, 1, angStart-j*angDiff, angStart-(j+1)*angDiff+2);
			} else {
				dc.setPenWidth(8);
				dc.drawArc(centerX, centerY, radius - 8/2, 1, angStart-j*angDiff, angStart-(j+1)*angDiff+2);
			}
			
		}	
		if (zone!=0){
			var angPin = angStart - (angDiff*(zone-1)+(measurement-zones[zone-1])*1.0/(zones[zone]-zones[zone-1])*angDiff);
			dc.setColor(backgroundColor, backgroundColor);
			dc.setPenWidth(14);
			dc.drawArc(centerX, centerY, radius - 7, 0, angPin - 3.5, angPin + 3.5);
			dc.setColor(textColor, textColor);
			dc.setPenWidth(14);
			dc.drawArc(centerX, centerY, radius - 7, 0, angPin - 1.5, angPin + 1.5);
		}
		return zone;
	}	

    function frmtPace(mps) {
    	var s = 0;
    	if (mps > 0.2778) {
        	s = (unitPace/mps).toLong();        
        	return (s / 60).format("%0d") + ":" + (s % 60).format("%02d");
        } else {
        	return "";
        }
    }
    
    function frmtDist(m) {
        var s = m/unitPace;
        if (s<(10*unitPace)){
        	return s.format("%0.2f");
        } else if (s<(100*unitPace)){
        	return s.format("%0.1f");
        } else  {
        	return s.format("%0.0f");
        }
    }

    // if less than hour n:ss, if more h:nn.S (S = s/10)
    function frmtTime(msec) {
        var s = msec / 1000;
        if (s<3600){
        	return (s/60).format("%d") + ":" + (s%60).format("%02d");
        } else {
        	return (s/3600).format("%d") + ":" + ((s/60)%60).format("%02d") + "." + (s%60/10).format("%1d");
        }
    }

    // Start/stop button was pushed - emulated via timer start/stop
    // If the button was double pressed quickly, toggle
    // the force backlight feature (see in compute(), above).
    function startStopPushed() {
        var info = Activity.getActivityInfo();
        var doublePressTimeMs = null;
        if ( mStartStopPushed > 0  &&  info.elapsedTime > 0 ) {
            doublePressTimeMs = info.elapsedTime - mStartStopPushed;
        }
        if ( doublePressTimeMs != null  &&  doublePressTimeMs < 1000 ) {
            uBacklight = !uBacklight;
            if (uBacklight != true) { Attention.backlight(false); }
        }
        mStartStopPushed = info.elapsedTime;
    }    
}