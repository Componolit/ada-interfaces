
with Ada.Unchecked_Conversion;
with Interfaces;
with Musinfo;
with Musinfo.Instance;
with Componolit.Interfaces.Muen;
with Componolit.Interfaces.Muen_Registry;

package body Componolit.Interfaces.Timer.Client with
   SPARK_Mode
is
   package CIM renames Componolit.Interfaces.Muen;
   package Reg renames Componolit.Interfaces.Muen_Registry;

   procedure Check_Event (I : CIM.Session_Index);

   function Create return Client_Session
   is
   begin
      return Client_Session'(Index => CIM.Invalid_Index);
   end Create;

   function Initialized (C : Client_Session) return Boolean
   is
      use type CIM.Session_Index;
   begin
      return C.Index /= CIM.Invalid_Index;
   end Initialized;

   procedure Initialize (C   : in out Client_Session;
                         Cap :        Componolit.Interfaces.Types.Capability)
   is
      pragma Unreferenced (Cap);
      use type CIM.Async_Session_Type;
   begin
      for I in Reg.Registry'Range loop
         if Reg.Registry (I).Kind = CIM.None then
            Reg.Registry (I) := Reg.Session_Entry'(Kind          => CIM.Timer_Client,
                                                   Next_Timeout  => 0,
                                                   Timeout_Set   => False,
                                                   Timeout_Event => Check_Event'Address);
            C.Index := I;
            exit;
         end if;
      end loop;
   end Initialize;

   function Clock (C : Client_Session) return Time
   is
      pragma Unreferenced (C);
      use type Standard.Interfaces.Unsigned_64;
      function To_Time is new Ada.Unchecked_Conversion (Standard.Interfaces.Unsigned_64, Time);
   begin
      return To_Time (Musinfo.Instance.TSC_Schedule_Start * 1000 / (Musinfo.Instance.TSC_Khz / 1000));
   end Clock;

   procedure Set_Timeout (C : in out Client_Session;
                          D :        Duration)
   is
      use type Standard.Interfaces.Unsigned_64;
      function To_Nanosecs is new Ada.Unchecked_Conversion (Duration, Standard.Interfaces.Unsigned_64);
   begin
      Reg.Registry (C.Index).Next_Timeout :=
         Musinfo.Instance.TSC_Schedule_Start + (Musinfo.Instance.TSC_Khz / 1000) * (To_Nanosecs (D) / 1000);
      Reg.Registry (C.Index).Timeout_Set  := True;
   end Set_Timeout;

   procedure Check_Event (I : CIM.Session_Index)
   is
      use type Standard.Interfaces.Unsigned_64;
   begin
      if
         Reg.Registry (I).Timeout_Set
         and then Reg.Registry (I).Next_Timeout < Musinfo.Instance.TSC_Schedule_Start
      then
         Reg.Registry (I).Timeout_Set := False;
         Event;
      end if;
   end Check_Event;

   procedure Finalize (C : in out Client_Session)
   is
   begin
      Reg.Registry (C.Index) := Reg.Session_Entry'(Kind => CIM.None);
      C.Index := CIM.Invalid_Index;
   end Finalize;

end Componolit.Interfaces.Timer.Client;
