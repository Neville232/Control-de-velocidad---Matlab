#include <18F45K50.h>

#use delay(internal=4MHz)
#fuses XT, NOWDT, NOPLLEN, NOLVP
#use rs232(baud=9600, xmit=PIN_C6, rcv=PIN_C7, stream=PC, parity=N, bits=8)

//==================== VARIABLES GLOBALES ====================

int timer2 = 88;                // Se carga timer 2 con 88 para obtener 700 Hz
int poscaler = 1;               // Poscaler solo puede tomar valores de: 1
int int_encoder = 0;            // Contador del encoder
int count = 0;                  // Contador para el Timer0
int resolucion = 8;             // Resolucion del encoder (8 pulsos por vuelta)

int duty = 100;                  // Ciclo de trabajo inicial 
int estado = 0;                 // Motor encendido o apagado
const int16 duty_porcentual[101] = {
    0, 3, 7, 10, 14, 17, 21, 24, 28, 32, 35, 39, 42, 46, 49, 53, 56, 60, 64, 67, 71, 74, 78, 81, 85, 89, 92, 96, 99, 103, 106, 110, 113, 117, 121, 124, 128, 131, 135, 138, 142, 145, 149, 153, 156, 160, 163, 167, 170, 174, 178, 181, 185, 188, 192, 195, 199, 202, 206, 210, 213, 217, 220, 224, 227, 231, 234, 238, 242, 245, 249, 252, 256, 259, 263, 267, 270, 274, 277, 281, 284, 288, 291, 295, 299, 302, 306, 309, 313, 316, 320, 323, 327, 331, 334, 338, 341, 345, 348, 352, 356
};

float rpm_actual = 0.0;         // Almacena el valor actual de RPM
float rpm_anterior = 0.0;       // Almacena el valor anterior de RPM
float rpm = 0.0;                // Almacena el valor filtrado de RPM
float alpha = 0.8;              // Coeficiente de filtro exponencial
float beta = 0.0;               // Ajuste del error

char buffer[5];
int i = 0;
int datos_listos = 0;


//==================== FUNCIONES INTERRUPCIONES ====================

#INT_EXT                            //Interrupcion externa (pulsos del encoder)
void EXT_isr(){
    int_encoder++;                  // Incrementa contador del encoder
}


#INT_TIMER0                         //Interrupcion del Timer0 (calculo de rpm)
void TIMER0_isr(){
    set_timer0(6);                  // Precarga ajustada para 64 ms por interrupción
    count++;                        // Incrementar el contador

    if (count >= 4) {               // 256 ms
        count = 0;                  // Reinicia el contador

        rpm_actual = ((float)int_encoder * 240.0) / (float)resolucion; // Calcula RPM (60 * 4)
        int_encoder = 0;            // Reinicia contador del encoder

        if (rpm_anterior != 0) {    // Aplicar el filtro exponencial
            rpm = (beta + 1) * (alpha * rpm_actual + ((1 - alpha) * rpm_anterior));
        } else {
            rpm = rpm_actual;
        }

        rpm_anterior = rpm;         // Actualiza rpm_anterior

        if (estado == 1) {          // Solo enviar RPM si el motor está encendido
            printf("%.2f -", rpm);  // Imprimir valores en el puerto serial
        }
    }
}


#INT_RDA                            //Interrupcion de recepcion de datos seriales (RS232)
void RDA_isr() {
    char c = getc();
    if (c == 0xFF) {                // Caracter de inicio
        i = 0;                      // Reiniciar el indice del buffer
    }
    buffer[i] = c;
    i++;
    if (i >= 3) {                   // Longitud de la trama de datos
        datos_listos = 1;
        i = 0;                      // Reiniciar el i­ndice del buffer
    }
}


//==================== FUNCIONES ====================
void parsear_trama(char *buffer) {
    if (buffer[0] == 0xFF) {        // Verificar el caracter de inicio
        duty = buffer[1];
        estado = buffer[2];
    }
}

void main(){

    enable_interrupts(INT_RDA);
    enable_interrupts(INT_EXT);
    enable_interrupts(INT_TIMER0);
    enable_interrupts(GLOBAL);

    setup_timer_2(T2_DIV_BY_16, timer2, poscaler);              // Configuracion de Timer 2 para establecer frec. PWM a 700 Hz
    setup_ccp1(CCP_PWM);                                        // Configurar modulo CCP1 en modo PWM
    setup_timer_0(RTCC_INTERNAL | RTCC_8_BIT | RTCC_DIV_256);   // Configuracion del Timer0

    set_pwm1_duty(duty_porcentual[duty]);

    while (true){
        if (datos_listos) {
            datos_listos = 0;
            parsear_trama(buffer);                              // Parsear la trama de datos y actualizar las variables
            
            if(estado){
                set_pwm1_duty(duty_porcentual[duty]);
            }else{
                set_pwm1_duty(0);
            }
            
        } 
    }
    
}
