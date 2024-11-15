pkg load signal
clear all
close all

dataStream = [];

readData = load("pulsoxy_daten.txt");
streamCount = (length(readData.dataMatrix)/3)

for i = 1:streamCount
  dataStream(i).name = readData.dataMatrix{(i-1)*3+1};
  dataStream(i).array = readData.dataMatrix{(i-1)*3+2};
  dataStream(i).t     = readData.dataMatrix{(i-1)*3+3};
endfor

rot = dataStream(1).array(1:300);
ir =  dataStream(2).array(1:300);

# Maxima bestimmen (Distance = 7 empirisch ermittelt)
# ===================================================
[max_rot,rot_n] = findpeaks(rot,"MinPeakDistance",7);
[max_ir,ir_n] = findpeaks(ir,"MinPeakDistance",7);

# Minima bestimmen
# ================
for i = 1:length(rot_n)-1
  # fuer rot
  min_rot(i) = rot(rot_n(i));
  for n = rot_n(i):rot_n(i+1)
    if (rot(n) < min_rot(i))
      min_rot(i) = rot(n);
      min_rot_n(i) = n;
    endif
  endfor
  # fuer ir
  min_ir(i) = ir(ir_n(i));
  for n = ir_n(i):ir_n(i+1)
    if (ir(n) < min_ir(i))
      min_ir(i) = ir(n);
      min_ir_n(i) = n;
    endif
  endfor
endfor

a= -45.06;
b= 30.364;
c= 94.845;

# Fuer alle gefundenen Maxima und Minima
# AC / DC, R, Z und SPO2-Werte bestimmen
for i=1:length(min_rot)-1

  AC_ROT(i)=max_rot(i)-min_rot(i);
  AC_IR(i) =max_ir(i)-min_ir(i);

  R_ROT(i)= AC_ROT(i) / max_rot(i);
  R_IR(i) = AC_IR(i) / max_ir(i);

  Z(i) = R_ROT(i) / R_IR(i);
  SPO2(i) = a * (Z(i)^2) + b * Z(i) + c;

endfor

figure(1)

subplot(2,1,1)
plot(rot,"color","red","linewidth",2)
hold on
plot(rot_n,max_rot,"marker",'o',"linestyle","none","color","black","linewidth",2)
plot(min_rot_n,min_rot,"marker",'o',"linestyle","none","color","black","linewidth",2)
title("RED-Value")
subplot(2,1,2)
plot(ir,"color","blue","linewidth",2)
hold on
plot(ir_n,max_ir,"marker",'o',"linestyle","none","color","black","linewidth",2)
plot(min_ir_n,min_ir,"marker",'o',"linestyle","none","color","black","linewidth",2)
title("IR-Value")

figure(2)
hold on
#plot(AC_ROT,"color","red")
#plot(AC_IR,"color","blue")
plot(R_ROT,"color","red","marker",'o')
plot(R_IR,"color","blue","marker",'o')
#plot(Z,"color","green")
title('R-ROT und R-IR')

figure(3)
plot(SPO2,"color","black","marker",'o')
title('SpO2')
clc
disp('SpO2-Wert:')
Messanzahl = length(max_rot)
Mittelwert = mean(SPO2)
Standardab = std(SPO2)
