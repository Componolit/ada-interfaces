
with System;

package Componolit.Interfaces.Internal.Rom is

   type Client_Session is limited record
      Ifd   : Integer;
      Parse : System.Address;
      Cap   : System.Address;
      Name  : System.Address;
   end record;

end Componolit.Interfaces.Internal.Rom;
