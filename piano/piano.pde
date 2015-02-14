//import cc.arduino.*;
import arb.soundcipher.*;
import processing.serial.*;
Serial myPort;  
int val;  
int which=0;
 
SoundCipher sc;
boolean[] keysNotePlay;
int[] keysNoteMap;
//int valor=1;
 
void setup(){
  sc = new SoundCipher(this);
  keysNotePlay = new boolean[127];
  keysNoteMap = new int[127];
  keysNoteMap['a'] = 59;
  keysNoteMap['s'] = 60;
  keysNoteMap['d'] = 62;
  keysNoteMap['f'] = 64;
  keysNoteMap['g'] = 65;
  keysNoteMap['h'] = 67;
  keysNoteMap['j'] = 69;
  keysNoteMap['w'] = 61;
  keysNoteMap['e'] = 63;
  keysNoteMap['t'] = 66;
  keysNoteMap['y'] = 68;
  keysNoteMap['u'] = 70;
  //keysNoteMap['i'] = 71;
  size (600,400);
 frameRate(10);
  
  myPort = new Serial(this, "COM1", 9600);
}
 
void keyReleased(){
  keysNotePlay[key] = false;
  
}
 
// keep processing 'alive'
void draw() {
  fill(255);
  if( keyPressed && keysNotePlay['a'] == true){
    fill(204);
  }
  rect (10, 10, 30, 100);
     
  fill(255);
    if( keyPressed && keysNotePlay['s'] == true){
    fill(204);
  }
  rect (40, 10, 30, 100);
    fill(255);
    if( keyPressed && keysNotePlay['d'] == true){
    fill(204);
  }
  rect (70, 10, 30, 100);
    fill(255);
    if( keyPressed && keysNotePlay['f'] == true){
    fill(204);
  }
  rect (100, 10, 30, 100);
    fill(255);
    if( keyPressed && keysNotePlay['g'] == true){
    fill(204);
  }
   
  rect (130, 10, 30, 100);
    fill(255);
    if( keyPressed && keysNotePlay['h'] == true){
    fill(204);
  }
   
  rect (160, 10, 30, 100);
    fill(255);
    if( keyPressed && keysNotePlay['j'] == true){
    fill(204);
  }
   
  rect (190, 10, 30, 100);
   
   
  //ireng
  fill(0);
  if( keyPressed && keysNotePlay['w'] == true){
    fill(204);
  }
  rect (32,10,15,60);
  fill(0);
  if( keyPressed && keysNotePlay['e'] == true){
    fill(204);
  }
  rect (62,10,15,60);
  fill(0);
  if( keyPressed && keysNotePlay['t'] == true){
    fill(204);
  }
  rect (122,10,15,60);
  fill(0);
  if( keyPressed && keysNotePlay['y'] == true){
    fill(204);
  }
  rect (152,10,15,60);
  fill(0);
  if( keyPressed && keysNotePlay['u'] == true){
    fill(204);
  }
  rect (182,10,15,60);
  
  /*if(valor==1 && keysNotePlay[key] == false){
    sc.playNote(keysNoteMap['i'], 100, 1);
    keysNotePlay[key] = true;
  }*/
  
  /*fill(0);
  if( keyPressed && keysNotePlay['i'] == true){
    fill(204);
  }
  rect (212,10,15,60);*/
   
  /*if( keyPressed && keysNotePlay[key] == false){
    sc.playNote(keysNoteMap[key], 100, 1);
    keysNotePlay[key] = true;
  }*/
  
  while (myPort.available() > 0) {
    String inBuffer = myPort.readStringUntil('\n');
    if (inBuffer != null) {                
    String myString = new String(inBuffer); 
    String myString2 = trim(myString);
  if (myString2.equals("a")) {
    which = 1;
  } 
  
   if (myString2.equals("s")) {
    which = 2;
  } 
 
  switch (which) {
    case 1:
      
      sc.playNote(keysNoteMap['a'], 100, 1);
      //myPort.clear();
    break;
    case 2:
     
     sc.playNote(keysNoteMap['d'], 100, 1);
     //myPort.clear();
      break;
  }
    }
  }
}
