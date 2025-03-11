#include <16f877a.h>

#use delay(clock=4MHz)
//#fuses XT, NOWDT, NOPLLEN, NOLVP
#use rs232(baud=9600, xmit=PIN_C6, rcv=PIN_C7, stream=PC, parity=N, bits=8)

#define ARRAY_SIZE 40 // 256 ms * 40 = 10.24 seconds

// Pre-calculated RPM values for a first-order system with a settling time of 10 seconds
/*    
    int16 rpm_values[ARRAY_SIZE] = {
        0, 136, 259, 370, 470, 560, 642, 716, 782, 842,
        897, 946, 990, 1030, 1066, 1098, 1127, 1154, 1178, 1199,
        1219, 1236, 1252, 1267, 1280, 1291, 1302, 1311, 1320, 1328,
        1335, 1341, 1347, 1352, 1356, 1361, 1364, 1368, 1371, 1374
    };
*/

int16 rpm_values[ARRAY_SIZE] = {
    0, 35, 70, 105, 140, 175, 210, 245, 280, 315,
    350, 385, 420, 455, 490, 525, 560, 595, 630, 665,
    700, 735, 770, 805, 840, 875, 910, 945, 980, 1015,
    1050, 1085, 1120, 1155, 1190, 1225, 1260, 1295, 1330, 1365
};

volatile int datos_listos = 0;
volatile int i = 0;
char buffer[3];
int imprimir = 0;
int bucle = 0;
#INT_RDA
void RDA_isr() {
    char c = getc();
    if (c == 0xFF) { // Caracter de inicio
        i = 0; // Reinicia el índice del buffer
    }
    buffer[i] = c;
    i++;
    if (i >= 3) { // Longitud de la trama de datos
        datos_listos = 1;
        i = 0; // Reinicia el índice del buffer
    }
    if(buffer[0] == 0xFF && buffer[2] == 0x01){
       imprimir = 1;
       bucle = 1;
    }else{
      imprimir = 0;
    }
}

void main() {
    enable_interrupts(INT_RDA);
    enable_interrupts(GLOBAL);

    // Continuar enviando el valor final hasta recibir la trama FF 00 00
    while (true) {
    
        if(imprimir){
            // Enviar los valores pre-calculados
          if(bucle){
          
          for (int j = 0; j < ARRAY_SIZE; j++) {
              printf("%ld -\n", rpm_values[j]); // Send RPM value via serial
              delay_ms(256); // Wait for 256 ms
          }
          
          bucle = 0;
          
          }
        
        
        printf("1395 -\n"); // Send final RPM value via serial
        delay_ms(256); // Wait for 256 ms
         
        }
         
        // Verificar si se ha recibido la trama FF 00 00
        if (datos_listos) {
            datos_listos = 0;
            if (buffer[0] == 0xFF && buffer[1] == 0x00 && buffer[2] == 0x00) {
                break; // Salir del bucle si se recibe la trama FF 00 00
            }
        }
    }
}
