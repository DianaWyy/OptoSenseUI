import processing.net.*;

Server myServer;

int numRow = 1;
int numCol = 1;
int numPixel = numRow * numCol;

float[] gdata = new float[numPixel];
float currValue = 0;
float currDirivative = 0;

ColorMap cm = new ColorMap();
int fpsCounter = 0;
String fpsIndicator = "";
long lastTime = -1;
int countdownTimer = -1;

// for rolling graph
float inByte;
int[] yValues;
int[] yDirivatives;
int w;

// for thresholds
int dirivativeThreshold = 50;
int timeThreshold = 300; // 5s

// for detection results
String stateString = "";

// for saving measurements
Table table;
float measurements [] = new float [8];

void setup() {
  size(700, 700);
  // Starts a myServer on port 2337
  myServer = new Server(this, 2337); 
  background(255);
  lastTime = millis();
  
  // for rolling graph
  w = width-10;
  strokeWeight(3);
  yValues = new int[w];
  yDirivatives = new int[w];
  smooth();
  
  table = new Table();
  for(int i = 0; i < 8; i++){
    table.addColumn("position_" + i);
  }
}

void draw() {
  Client thisClient = myServer.available();

      if (thisClient != null) {
        
        calculateFPS();
        
        String whatClientSaid = thisClient.readString();
        if (whatClientSaid != null) {
          processData(whatClientSaid);
        } 
      }
      
      // dirivative detection
      
      if (abs(currDirivative) > dirivativeThreshold ){
        stateString = "In Use";
        countdownTimer = timeThreshold; // refresh the countdown timer
        
      }else{
        countdownTimer--;
        if(countdownTimer <= 0){
          stateString = "";
        }
      }
      
      background(100);
      
      float size = height/numRow;
      
      int[] rgb = cm.getColor((float) ((currValue)/255.0));
      fill(rgb[0], rgb[1], rgb[2]);
      noStroke();
      //rect(0,0, size-3, size-3);
      
      // show FPS
      fill(255);
      textSize(20);
      textAlign(LEFT);
      text("FPS: "+fpsIndicator, width - 250, 20);
      text("Threshold: "+dirivativeThreshold, width - 250, 40);
      text("Time Hysteresis: "+timeThreshold, width - 250, 60);
      
      // for rolling graph
      float yOffset = 100;
      int currValueDraw = (int) (currValue/1000);
      int currDirivativeDraw = (int) (currDirivative/1000);
      
      // moving rolling buffer
     
      for(int i = 1; i < w; i++) {
        yValues[i-1] = yValues[i];
        yDirivatives[i-1] = yDirivatives[i];
      }
      
      yValues[w-1] = currValueDraw;
      yDirivatives[w-1] = currDirivativeDraw;
      
      // drawing rolling buffer for intensity
      noStroke();
      fill(150);
      rect(0, yOffset, width, 255);
      strokeWeight(3);
      stroke(255);
      for(int i=1; i<w; i++) {
        line(i, yValues[i] + yOffset, i-1, yValues[i-1] + yOffset);
      }
      fill(255);
      text("Raw measurement:", 10, yOffset + 30);
      
      // drawing rolling buffer for dirivative
      noStroke();
      fill(150);
      rect(0, yOffset + 300 , width, 255);
      
      // draw threshold
      stroke(255, 200, 0);
      strokeWeight(1);
      line(0, dirivativeThreshold + yOffset + 300 + 255/2, width, dirivativeThreshold+yOffset + 300 + 255/2);
      line(0, -dirivativeThreshold + yOffset + 300 + 255/2, width, -dirivativeThreshold+yOffset + 300 + 255/2);
      strokeWeight(3);
      stroke(30,144,255);
      for(int i=1; i<w; i++) {
        line(i, yDirivatives[i] + yOffset + 300 + 255/2, i-1, yDirivatives[i-1] + yOffset + 300 + 255/2);
      }
      
      fill(255);
      text("First dirivative:", 10, yOffset + 300+30);
      
      // show detection result
      textAlign(CENTER);
      textSize(80);
      fill(255);
      text(stateString, 250 , 80);
}

void keyPressed(){
 // adjust threshold 
  if(key == CODED){
   if(keyCode == UP){
     dirivativeThreshold+= 5;
   }else if (keyCode == DOWN){
     dirivativeThreshold -= 5;
   }
   
   if(keyCode == LEFT){
     timeThreshold -= 100;
   }else if (keyCode == RIGHT){
     timeThreshold += 100;
   }
  }
  
  // press 0, 1, ..., 7 to save 8 measurements to a csv file
  else if( key>= '0' && key <= '7'){ 
    int index = Integer.parseInt(key+"");
    measurements[index] = currValue;
    
    for(int i = 0; i < measurements.length; i++){
      print(measurements[i]);
      print(' ');
    }
    println();
    
  }else if (key == 's'){
    TableRow newRow = table.addRow();
    for(int i = 0; i < 8; i++){
       newRow.setFloat("position_"+i, measurements[i]); 
    }
    saveTable(table, "data/measurements.csv");
    println("measurements saved into data/measurements.csv");
  }
  
}

void calculateFPS(){
  // calculate frames per second
  long currentTime = millis();
  if(currentTime - lastTime > 1000){
    lastTime = currentTime;
    fpsIndicator = "" + fpsCounter;
    fpsCounter = 0;
  }else{
    fpsCounter++;
  }
}

void processData(String resultString){
  String[] data = split(resultString, " ");
  
      if(data.length != numPixel) return;
      
      for(int i = 0; i < data.length; i++){
        gdata[i] = Float.parseFloat(data[i]);
      }
      
      currDirivative = gdata[0] - currValue;
      currValue = gdata[0];
}
