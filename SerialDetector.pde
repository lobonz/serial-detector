import processing.serial.*;

Serial sensorPort;
int baudRate = 9600;
int numSensors = 6; 
int sensors[] = new int[numSensors]; 

boolean serialFound;

Serial watchdogPort;

long updateMillis; 

void setup() {
  size(1620, 480, P2D);

  // Find Serial Port that the sensor is on 
  // checks to see if we get CSV Values Back

  long millisStart; 
  int i = 0; 
  int len = Serial.list().length;  //get number of ports available 
  printArray(Serial.list());   //print list of ports to screen

  serialFound = false;
  String watchdogPortName = "";
  println("Looking for Watchdog . . .");
  for ( i = len-1; i > -1; i--) 
  { 
    println("Testing port " + Serial.list()[i]);
    watchdogPortName = Serial.list()[i];

    try {
      watchdogPort = new Serial(this, watchdogPortName, baudRate);      // Open 1st port in list
    }
    catch(RuntimeException e) {
      //e.printStackTrace();
      continue;//if there is an exception we prob couldnt open the port
    }

    millisStart = millis(); // can't use delay() call in setup()
    while ((millis() - millisStart) < 2000) ; //wait for USB port reset (Guessed at 2 secs) 

    try {
      watchdogPort.clear();    // empty buffer(incase of trash)
    }
    catch(RuntimeException e) {
      //e.printStackTrace();
    }

    millisStart = millis(); // can't use delay() call in setup()
    int l = 5;
    watchdogPort.bufferUntil(10);
    watchdogPort.write("HELO");// -- Send  Hello 
  
    while (!serialFound && l >0)
    {
      while ((millis() - millisStart) < 2000); //pause to collect some data
      String inBuffer = watchdogPort.readStringUntil(10);
      println("Waiting for response from device on " + watchdogPortName);
      //println("Data="+inBuffer);
      l--;
      if (inBuffer != null) {
        if (inBuffer.indexOf("WATCHDOG")>=0 || inBuffer.indexOf("HELO")>=0)
        {
          println("Connected Watchdog on port " + watchdogPortName);
          serialFound = true;
          break;
        }
      }
      if (serialFound){break;}
    }
    if (!serialFound) {
      watchdogPort.stop();
    }else{
      break;
    }
  }
  
  if (!serialFound) {
    println("Could not detect Watchdog");
  }


  serialFound = false;
  String wallPortName = "";
println("Looking for RD Sensor . . .");
for ( i = len-1; i > -1; i--) 
  { 
    wallPortName = Serial.list()[i];          
    if (wallPortName.indexOf("COM")>=0 && !wallPortName.equals(watchdogPortName)) {
      println("Testing port " + Serial.list()[i] + "="+watchdogPortName);
      try {
        sensorPort = new Serial(this, wallPortName, baudRate);      // Open 1st port in list
      }
      catch(RuntimeException e) {
        //e.printStackTrace();
        continue;//if there is an exception we prob couldnt open the port
      }

      millisStart = millis(); // can't use delay() call in setup()
      while ((millis() - millisStart) < 2000) ; //wait for USB port reset (Guessed at 2 secs) 

      try {
        sensorPort.clear();    // empty buffer(incase of trash)
      }
      catch(RuntimeException e) {
        e.printStackTrace();
        continue;//if there is an exception the port is not working
      }

      millisStart = millis(); // can't use delay() call in setup()

      while ((millis() - millisStart) < 1000); //pause to collect some data
      String inBuffer = sensorPort.readStringUntil(10);       //buffer until there is a linefeed ASCII 10
      // if you got any bytes other than the linefeed:
      if (inBuffer != null) {
        println("RECV:"+inBuffer);
        inBuffer = trim(inBuffer);

        String[] num = split(inBuffer, ',');
        // Get the sensor count to confirm we have the expected data            
        //if we have the expected data we have found the port
        if (sensorPort.available() > 0 && num.length == numSensors)   
        { 
          println("Found RD Sensor on com port: " + wallPortName);
          serialFound = true;
          break;    //leave for loop
        } else {
          sensorPort.stop();   //if no 'T', stop port
        }
      }
    }
  }
  if (!serialFound){
    println("Could not detect Sensor Input");
  }




  updateMillis = millis();
}


void draw() {
  //text();
  if ((millis() - updateMillis) > 2000) {
    watchdogPort.write("TIME");// -- Send  Hello
    println("Sensor = "+sensorPort.readStringUntil(10));
    println("Watchdog = "+watchdogPort.readStringUntil(10));
    updateMillis = millis();
  }
}
