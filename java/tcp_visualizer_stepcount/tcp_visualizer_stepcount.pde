import processing.net.*;

Server myServer;

int numRow = 8;
int numCol = 8;
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

// for detection results
String stepCountString = "Step Count: 0";

// for step count
long stepCount = 0;
int stepCountDirivativeThreshold = 5;
boolean footUp = false;
boolean footDown = false;

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
      
      background(100);
      
      float size = height/numRow;
      
      int[] rgb = cm.getColor((float) ((currValue)/255.0));
      fill(rgb[0], rgb[1], rgb[2]);
      noStroke();
      rect(0,0, size-3, size-3);
      
      // show FPS
      fill(255);
      textSize(20);
      textAlign(LEFT);
      text("FPS: "+fpsIndicator, width - 250, 20);
      text("Threshold: "+stepCountDirivativeThreshold, width - 250, 40);
      //text("Time Hysteresis: "+timeThreshold, width - 250, 60);
      
      // for rolling graph
      float yOffset = 100;
      int currValueDraw = (int) (255 - currValue);
      int currDirivativeDraw = (int) (-currDirivative);
      
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
      line(0, stepCountDirivativeThreshold + yOffset + 300 + 255/2, width, stepCountDirivativeThreshold+yOffset + 300 + 255/2);
      line(0, -stepCountDirivativeThreshold + yOffset + 300 + 255/2, width, -stepCountDirivativeThreshold+yOffset + 300 + 255/2);
      strokeWeight(3);
      stroke(30,144,255);
      for(int i=1; i<w; i++) {
        line(i, yDirivatives[i] + yOffset + 300 + 255/2, i-1, yDirivatives[i-1] + yOffset + 300 + 255/2);
      }
      
      fill(255);
      text("First dirivative:", 10, yOffset + 300+30);
      
      // detect step
      if(currDirivative > stepCountDirivativeThreshold){
        footUp = true;
      }
      
      if(currDirivative < stepCountDirivativeThreshold){
        footDown = true;
        
        if(footUp && footDown){
          stepCount += 1;
          stepCountString = "Step Count: " + stepCount;
          footUp = false;
          footDown = false;
        }
      }
      
      
      
      // show detection result
      textAlign(CENTER);
      textSize(30);
      fill(255);
      text(stepCountString, 250 , 40);
}

void keyPressed(){
 // adjust threshold 
  if(key == CODED){
   if(keyCode == UP){
     stepCountDirivativeThreshold += 1;
   }else if (keyCode == DOWN){
     stepCountDirivativeThreshold -= 1;
   }
   
   if(keyCode == LEFT){
     //timeThreshold -= 100;
   }else if (keyCode == RIGHT){
     //timeThreshold += 100;
   }
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
      
      currDirivative = gdata[4] - currValue;
      currValue = gdata[4];
}
