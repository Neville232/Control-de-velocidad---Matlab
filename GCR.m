G = tf(1, [6.89 1]);
C = tf([4.35*4.76 4.35], [4.76 0]);
Gc = G*C;
Gcr = feedback(Gc, 1);
step(Gcr)