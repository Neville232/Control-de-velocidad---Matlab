#include <18F45K50.h>
#use delay(internal=4MHz)
#fuses XT, NOWDT, NOPLLEN, NOLVP
#use rs232(baud=9600, xmit=PIN_C6, rcv=PIN_C7, stream=PC, parity=N, bits=8)

// Variables globales para el control PID
float muestreo = 0.256; // Intervalo de muestreo
float Kc = 1; // Ganancia proporcional
float ti = 0; // Tiempo integral
float td = 0; // Tiempo derivativo
int setpoint = 0; // Valor deseado
float e[3] = {0,0,0}; // Arreglo para almacenar las Ãºltimas tres muestras del error
int controlador = 0; // Tipo de controlador: 0 -> P, 1 -> PI, 2 -> PD, 3 -> PID
int proceso_activo = 0; // Variable para iniciar/detener el proceso
int lazo = 0; // Variable para determinar si el sistema estÃ¡ en lazo abierto (0) o lazo cerrado (1)

// Coeficientes del controlador
float q0, q1, q2;

int16 duty = 0;
const int16 duty_lookup[101] = {
    0, 3, 7, 10, 14, 17, 21, 24, 28, 32, 35, 39, 42, 46, 49, 53, 56, 60, 64, 67, 71, 74, 78, 81, 85, 89, 92, 96, 99, 103, 106, 110, 113, 117, 121, 124, 128, 131, 135, 138, 142, 145, 149, 153, 156, 160, 163, 167, 170, 174, 178, 181, 185, 188, 192, 195, 199, 202, 206, 210, 213, 217, 220, 224, 227, 231, 234, 238, 242, 245, 249, 252, 256, 259, 263, 267, 270, 274, 277, 281, 284, 288, 291, 295, 299, 302, 306, 309, 313, 316, 320, 323, 327, 331, 334, 338, 341, 345, 348, 352, 356
};

char buffer[50];
int i = 0;
int data_ready = 0;

int int_encoder = 0; // Contador del encoder
int count = 0; // Contador para el Timer0
float rpm_actual = 0.0; // Almacena el valor actual de RPM
float resolucion = 8; // ResoluciÃ³n del encoder (8 pulsos por vuelta)
float rpm_anterior = 0.0; // Almacena el valor anterior de RPM
float rpm = 0.0; // Almacena el valor filtrado de RPM
float alpha = 0.8; // Coeficiente de filtro exponencial
float beta = 0.03; // Ajuste del error
int u100 = 1700; // 100% de las RPM
int u0 = 0; // RPM porcentual del sistema

// Variables para manejar el cÃ¡lculo de RPM fuera de la interrupciÃ³n
int calcular_rpm = 0;

// FunciÃ³n para actualizar las muestras del error
void actualizar_muestras(float nueva_muestra, float *arr) {
    arr[2] = arr[1];
    arr[1] = arr[0];
    arr[0] = nueva_muestra;
}

// FunciÃ³n para calcular los coeficientes del controlador segÃºn el tipo de controlador
void calcular_coeficientes() {
    if (controlador == 0) {                     // CONTROLADOR P
        q0 = Kc;
        q1 = 0;
        q2 = 0;
    } else if (controlador == 1) {              // CONTROLADOR PI
        q0 = Kc * (1 + muestreo / (2 * ti));
        q1 = -Kc * (1 - muestreo / (2 * ti));
        q2 = 0;
    } else if (controlador == 2) {              // CONTROLADOR PD
        q0 = Kc * (1 + td / muestreo);
        q1 = -Kc * (1 + 2 * td / muestreo);
        q2 = Kc * (td / muestreo);
    } else if (controlador == 3) {              // CONTROLADOR PID
        q0 = Kc * (1 + muestreo / (2 * ti) + td / muestreo);
        q1 = -Kc * (1 - muestreo / (2 * ti) + (2 * td) / muestreo);
        q2 = (Kc * td) / muestreo;
    }
}

// FunciÃ³n para parsear la trama de datos
void parsear_trama(char *buffer) {
    if (buffer[0] == 0xFF) { // Verificar el carÃ¡cter de inicio
        Kc = buffer[1] + buffer[2] / 100.0;
        ti = buffer[3] + buffer[4] / 100.0;
        td = buffer[5] + buffer[6] / 100.0;
        setpoint = buffer[7];
        controlador = buffer[8];
        proceso_activo = buffer[9];
        lazo = buffer[10];
    }
}

// InterrupciÃ³n de recepciÃ³n de datos por RS232
#INT_RDA
void RDA_isr() {
    char c = getc();
    if (c == 0xFF) { // CarÃ¡cter de inicio
        i = 0; // Reiniciar el Ã­ndice del buffer
    }
    buffer[i] = c;
    i++;
    if (i >= 11) { // Longitud de la trama de datos
        data_ready = 1;
        i = 0; // Reiniciar el Ã­ndice del buffer
    }
}

// InterrupciÃ³n externa (pulsos del encoder)
#INT_EXT
void EXT_isr(){
    int_encoder++; // Incrementa contador del encoder
}

// InterrupciÃ³n del Timer0
#INT_TIMER0
void TIMER0_isr(){
    set_timer0(6); // Precarga ajustada para 64 ms por interrupciÃ³n
    count++; // Incrementar el contador

    if (count >= 4) { // 256 ms
        count = 0; // Reinicia el contador
        calcular_rpm = 1; // SeÃ±alar que se debe calcular el RPM
    }
}

void main(){
    int Timer2 = 88; // Se carga timer 2 con 88 para obtener 700 Hz
    int Poscaler = 1; // Poscaler solo puede tomar valores de: 1

    enable_interrupts(INT_RDA);
    enable_interrupts(INT_EXT);
    enable_interrupts(INT_TIMER0);
    enable_interrupts(GLOBAL);

    setup_timer_2(T2_DIV_BY_16, Timer2, Poscaler); // ConfiguraciÃ³n de Timer 2 para establecer frec. PWM a 700 Hz
    setup_ccp1(CCP_PWM); // Configurar mÃ³dulo CCP1 en modo PWM
    setup_timer_0(RTCC_INTERNAL |RTCC_8_BIT | RTCC_DIV_256); // ConfiguraciÃ³n del Timer0

    set_pwm1_duty(duty);

    while (true){
        if (data_ready) {
            // Parsear la trama de datos y actualizar las variables
            parsear_trama(buffer);
            data_ready = 0;
        }

        if (calcular_rpm) {
            calcular_rpm = 0; // Reiniciar la seÃ±al de cÃ¡lculo de RPM
            rpm_actual = (int_encoder * 240.0) / resolucion; // Calcula RPM (60 * 4)
            int_encoder = 0; // Reinicia contador del encoder

            // Aplicar el filtro exponencial
            if (rpm_anterior != 0) {
                rpm = (beta + 1) * (alpha * rpm_actual + ((1 - alpha) * rpm_anterior));
            } else {
                rpm = rpm_actual;
            }
            rpm_anterior = rpm; // Actualiza rpm_anterior

            u0 = (rpm / u100) * 100; // Calcular RPM porcentual

            // Imprimir valores en el puerto serial
            printf("%.2f -", rpm);
        }

        if (proceso_activo) {
            if (lazo == 0) {
                // Modo lazo abierto: ajustar el duty cycle directamente segÃºn el setpoint
                duty = duty_lookup[setpoint];
                set_pwm1_duty(duty); // Ajusta el ciclo de trabajo del PWM
            } else {
                // Modo lazo cerrado: usar el controlador PID
                // Calcular los coeficientes del controlador
                calcular_coeficientes();

                // Calcular la salida del controlador usando las muestras del error y los coeficientes
                float u = q0 * e[0] + q1 * e[1] + q2 * e[2];
                
                // Asegurarse de que 'u' estÃ© dentro del rango de 0 a 100
                if (u < 0) u = 0;
                if (u > 100) u = 100;
                
                duty = duty_lookup[(int)u];
                set_pwm1_duty(duty); // Ajusta el ciclo de trabajo del PWM

                // Calcular el error actual como la diferencia entre el setpoint y la salida del sistema
                float error = setpoint - u0;

                // Actualizar las muestras del error con el nuevo error calculado
                actualizar_muestras(error, e);
            }
        }
    }
}

/*
Ejemplo de trama de datos:
FF 01 32 00 32 00 0A 32 03 01 00

- 0xFF: CarÃ¡cter de inicio
- 1.50: Valor de Kc (1 entero, 50 decimal)
- 0.50: Valor de ti (0 entero, 50 decimal)
- 0.10: Valor de td (0 entero, 10 decimal)
- 50: Valor de setpoint (entero)
- 3: Valor de controlador (Tipo de controlador: 0 -> P, 1 -> PI, 2 -> PD, 3 -> PID)
- 1: Valor de proceso_activo (1 para iniciar el proceso, 0 para detenerlo)
- 0: Valor de lazo (0 para lazo abierto, 1 para lazo cerrado)
*/

/*
Ejemplo de trama de datos:
FF 00 00 00 00 00 00 32 00 01 00

- 0xFF: CarÃ¡cter de inicio
- 0: Valor de Kc (1 entero, 50 decimal)
- 0: Valor de ti (0 entero, 50 decimal)
- 0: Valor de td (0 entero, 10 decimal)
- 50: Valor de setpoint (entero)
- 0: Valor de controlador (Tipo de controlador: 0 -> P, 1 -> PI, 2 -> PD, 3 -> PID)
- 1: Valor de proceso_activo (1 para iniciar el proceso, 0 para detenerlo)
- 0: Valor de lazo (0 para lazo abierto, 1 para lazo cerrado)
*/

// 0 = 00, 10 = 0A, 20 = 14, 30 = 1E, 40 = 28, 50 = 32
// 60 = 3C, 70 = 46, 80 = 50, 90 = 5A, 100 = 64
