classdef serialPortClass < handle

  properties
    streamSelector = [];
    regex_pattern = '';
    serialPortPath = '';
    inBuffer = '';
    serial_01 = '';
  endproperties

  methods
    function self = serialPortClass(baudrate)    # Constructor
      close self.serial_01;
      disp('Searching Serial Port ... ')
      i = 0;
      do
        i = i + 1;
        disp(i)
        self.serialPortPath = self.checkSerialPort(baudrate);
      until (!isempty(self.serialPortPath) || i == 3)
      if (!isempty(self.serialPortPath))
        disp("Serial Port found:")
        disp(self.serialPortPath)
      else
        disp("No Device found!");
      endif
      if (!isempty(self.serialPortPath))
        self.clearPort();
        disp('Receiving data!')
      endif
    endfunction

    function clearPort(self)
      flush(self.serial_01);
      posLF = 0;
      do
        bytesAvailable = self.serial_01.NumBytesAvailable;
        if (bytesAvailable > 0)
          #disp("Bytes availabe:");
          #disp(bytesAvailable);
          ## Daten werden vom SerialPort gelesen
          inSerialPort = char(read(self.serial_01,bytesAvailable));
          posLF        = index(inSerialPort,char(10),"last");
        endif
      until (posLF > 0);
      # erst ab dem letzten \n geht es los
      self.inBuffer = inSerialPort(posLF+1:end);
    endfunction

    function portReturn = checkSerialPort(self,baudrate)
      fehler = false;
      ports = serialportlist();
      portIndex = 1;
      port_found = false;
      portReturn = '';
      while(portIndex <= length(ports) && !port_found)
        #disp(ports{portIndex})
        try
          clear self.serial_01;
          disp(ports{portIndex});
          self.serial_01 = serialport(ports{portIndex},baudrate);
        catch
          fehler = true;
          disp(lasterror.message);
        end_try_catch
        if (fehler == false)
          #pause(1)
          #flush(serial_01);
          pause(2)
          bytesAvailable = self.serial_01.NumBytesAvailable;
          if (bytesAvailable > 0)
            inSerialPort = char(read(self.serial_01,bytesAvailable));
            firstCRLF    = index(inSerialPort, "\r\n","first");
            lastCRLF     = index(inSerialPort, "\r\n","last");
            if (lastCRLF > firstCRLF)
              inChar   = inSerialPort(firstCRLF:lastCRLF);
              values   = strsplit(inChar, {':',',','\n','\r'});
              data = unique(values);
              filtered_data = {};
              for i = 1:numel(data)
                if !any(isstrprop(data{i}, 'digit'))
                  if !isempty(data{i})
                    filtered_data{end+1} = data{i};
                  endif
                endif
              endfor
              if !isempty(filtered_data)
                msg = [self.serial_01.Port ,"\n"];
                for i = 1:length(filtered_data)
                  msg = [msg,filtered_data{i},";"];
                endfor
                portReturn = self.serial_01.Port;
                port_found = true;
                disp(msg);
              endif
              #disp(filtered_data)
            endif
          endif                       # bytesAvailable
          # clear serial_01;
        else                          # fehler == false
          fehler = false;
        endif
        portIndex = portIndex + 1;
      endwhile
    endfunction

    function [bytesAvailable,inChar] = readPort(self)
      bytesAvailable = self.serial_01.NumBytesAvailable;
      inSerialPort   = char(read(self.serial_01,bytesAvailable));
      self.inBuffer  = [self.inBuffer inSerialPort];
      posLF          = index(self.inBuffer,char(10),"last");
      inChar         = '';
      if (posLF > 0)
        inChar   = self.inBuffer(1:posLF);
        self.inBuffer = self.inBuffer(posLF+1:end);
      endif
    endfunction

    function countMatches = parseInput(self,inChar,dataStream)
      matches = regexp(inChar, self.regex_pattern, 'tokens'); # Regular Expression auswerten
      countMatches   = length(matches);                       # Wert wird ausgegeben
      for i = 1:countMatches
        streamName = matches{i}{1};
        adc        = str2num(matches{i}{2});
        sample_t   = str2num(matches{i}{3});
        j = self.streamSelector(streamName);     # Sample einem dataStream zuweisen
        dataStream(j).addSample(adc,sample_t);   # Hier uebernimmt dataStream die Arbeit
      endfor
    endfunction

  endmethods
end
