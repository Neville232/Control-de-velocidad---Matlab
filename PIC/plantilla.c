#include <18F45K50.h>

#use delay(internal=4MHz)
#fuses XT, NOWDT, NOPLLEN, NOLVP
#use rs232(baud=9600, xmit=PIN_C6, rcv=PIN_C7, stream=PC, parity=N, bits=8)


void main(){

    while (true){
        
    }
    
}


