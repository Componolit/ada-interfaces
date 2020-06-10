
generic
   pragma Warnings (Off, "* is not referenced");
   with procedure Event;
   pragma Warnings (Off, "* is not referenced");
package Gneiss.Packet.Client with
   SPARK_Mode
is

   pragma Unevaluated_Use_Of_Old (Allow);

   procedure Initialize (Session : in out Client_Session;
                         Cap     :        Capability;
                         Label   :        String;
                         Idx     :        Session_Index := 1);

   procedure Finalize (Session : in out Client_Session) with
      Post => not Initialized (Session);

   procedure Send (Session : in out Client_Session;
                   Data    :        Buffer;
                   Success :    out Boolean) with
      Pre  => Initialized (Session),
      Post => Initialized (Session);

   procedure Receive (Session : in out Client_Session;
                      Data    :    out Buffer;
                      Length  :    out Natural) with
      Pre  => Initialized (Session),
      Post => Initialized (Session);

end Gneiss.Packet.Client;
