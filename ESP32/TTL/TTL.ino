#include <HardwareSerial.h>

// Crear una instancia de HardwareSerial para UART2
HardwareSerial MySerial(2);

void setup() {
  // Iniciar la comunicación serial por defecto (UART0) a 115200 baudios
  Serial.begin(9600);

  // Configurar UART2 con los pines predeterminados (TX: GPIO17, RX: GPIO16) y velocidad de 9600 baudios
  MySerial.begin(9600, SERIAL_8N1, 16, 17);

  // Mensaje de inicio
  Serial.println("ESP32 como convertidor TTL iniciado.");
}

void loop() {
  // Leer datos de la consola serial por defecto (UART0) y enviarlos a UART2
  if (Serial.available()) {
    while (Serial.available()) {
      char data = Serial.read();
      MySerial.write(data);
    }
  }

  // Leer datos de UART2 y enviarlos a la consola serial por defecto (UART0)
  if (MySerial.available()) {
    while (MySerial.available()) {
      char data = MySerial.read();
      Serial.write(data);
    }
  }
}