
with System;
with RFLX.Session;
with Gneiss.Protocoll;
with Gneiss_Epoll;
with Gneiss_Platform;
with Componolit.Runtime.Debug;

package body Gneiss.Message.Client with
   SPARK_Mode
is

   function Get_Event_Address return System.Address;
   type RFLX_String is array (RFLX.Session.Length_Type range <>) of Character;
   package Proto is new Gneiss.Protocoll (Character, RFLX_String);

   procedure Init (Session  : in out Client_Session;
                   Label    :        String;
                   Success  :        Boolean;
                   Filedesc :        Integer);
   function Init_Cap is new Gneiss_Platform.Create_Initializer_Cap (Client_Session, Init);

   function Get_Event_Address return System.Address with
      SPARK_Mode => Off
   is
   begin
      return Event'Address;
   end Get_Event_Address;

   function Create_Request (Label : RFLX_String) return Proto.Message is
      (Proto.Message'(Length      => Label'Length,
                      Action      => RFLX.Session.Request,
                      Kind        => RFLX.Session.Message,
                      Name_Length => 0,
                      Payload     => Label));

   procedure Init (Session  : in out Client_Session;
                   Label    :        String;
                   Success  :        Boolean;
                   Filedesc :        Integer)
   is
      use type Gneiss_Epoll.Epoll_Fd;
      S : Integer;
   begin
      Componolit.Runtime.Debug.Log_Debug ("Init " & Label);
      if Label /= Session.Label.Value (Session.Label.Value'First .. Session.Label.Last) then
         return;
      end if;
      Session.Epoll_Fd := -1;
      if Success then
         Gneiss_Epoll.Add (Session.Epoll_Fd, Filedesc, Get_Event_Address, S);
         if S = 0 then
            Session.File_Descriptor := Filedesc;
         end if;
      end if;
      Event;
   end Init;

   C_Label : RFLX_String (1 .. 255);
   procedure Initialize (Session : in out Client_Session;
                         Cap     :        Capability;
                         Label   :        String)
   is
      Succ : Boolean;
   begin
      Componolit.Runtime.Debug.Log_Debug ("Initialize " & Label);
      case Status (Session) is
         when Initialized | Pending =>
            return;
         when Uninitialized =>
            if Label'Length > 255 then
               return;
            end if;
            Session.Label.Last := Session.Label.Value'First + Label'Length - 1;
            Session.Label.Value
               (Session.Label.Value'First
                .. Session.Label.Value'First + Label'Length - 1) := Label;
            for I in C_Label'Range loop
               C_Label (I) := Session.Label.Value (Positive (I));
            end loop;
            Session.Epoll_Fd := Cap.Epoll_Fd;
            Gneiss_Platform.Call (Cap.Register_Initializer,
                                  Init_Cap (Session),
                                  RFLX.Session.Message, Succ);
            if Succ then
               Proto.Send_Message
                  (Cap.Broker_Fd,
                   Create_Request (C_Label (C_Label'First ..
                                            RFLX.Session.Length_Type (Session.Label.Last))));
            else
               Init (Session, Label, False, -1);
            end if;
      end case;
   end Initialize;

   function Available (Session : Client_Session) return Boolean is (False);

   procedure Write (Session : in out Client_Session;
                    Content :        Message_Buffer)
   is
   begin
      null;
   end Write;

   procedure Read (Session : in out Client_Session;
                   Content :    out Message_Buffer)
   is
   begin
      null;
   end Read;

   procedure Finalize (Session : in out Client_Session)
   is
   begin
      null;
   end Finalize;

end Gneiss.Message.Client;
