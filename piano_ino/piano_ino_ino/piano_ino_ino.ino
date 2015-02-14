/*:...........................PIANO ARDUINO.........................
..........................ADILMAR COELHO DANTAS.....................
..........................akanehar@gmail.com........................*/

#include <CapacitiveSensorDue.h>

int leda = 10;
int ledb = 11;
int som = 13;

CapacitiveSensorDue cs_4_2 = CapacitiveSensorDue(4,2);	        // ligue um resitor ao pino 4 e 2 e uma ligacao ao pino 2 para o sensor capacitivo 
CapacitiveSensorDue cs_4_6 = CapacitiveSensorDue(4,6);	
//CapacitiveSensorDue cs_4_8 = CapacitiveSensorDue(4,8);	
void setup()					
{
	Serial.begin(9600);
         pinMode(leda, OUTPUT); 
         pinMode(ledb, OUTPUT);  
         pinMode(som,OUTPUT);
}

void loop()					
{
	long start = millis();
	long total1 = cs_4_2.read(30);
	long total2 = cs_4_6.read(30);
	//long total3 = cs_4_8.read(30);
	
	//Serial.print(millis() - start);	// check on performance in milliseconds
	
        if(total1 != -1){
        //Serial.print("\n");				// tab character for debug windown spacing
	//Serial.print("a");
        tone(13,2999,800);
        digitalWrite(leda, HIGH);   // turn the LED on (HIGH is the voltage level)
        delay(100);               // wait for a second
        digitalWrite(leda, LOW); 
        
        
	
	}

        if(total2 != -1){
         //Serial.print("\n");
         //Serial.print("s");
         tone(13,3830,100);
         digitalWrite(ledb, HIGH);   // turn the LED on (HIGH is the voltage level)
         delay(100);               // wait for a second
         digitalWrite(ledb, LOW);
	
          
   }
	delay(10);						
}

