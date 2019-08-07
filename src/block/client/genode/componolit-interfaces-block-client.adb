
with Ada.Unchecked_Conversion;
with System;
with Cxx;
with Cxx.Block;
with Cxx.Block.Client;
with Cxx.Genode;
use all type Cxx.Bool;

package body Componolit.Interfaces.Block.Client
is

   type Request_Handle is record
      Valid   : Boolean;
      Tag     : Cxx.Unsigned_Long;
      Success : Boolean;
   end record;

   type Request_Handle_Cache is array (Integer range 1 .. 128) of Request_Handle;

   H_Cache : Request_Handle_Cache := (others => (False, 0, False));

   function Null_Request return Request
   is
   begin
      return Request'(Packet => Cxx.Block.Client.Packet_Descriptor'(Offset       => 0,
                                                                    Bytes        => 0,
                                                                    Opcode       => -1,
                                                                    Tag          => 0,
                                                                    Block_Number => 0,
                                                                    Block_Count  => 0),
                      Status => Componolit.Interfaces.Internal.Block.Raw);
   end Null_Request;

   function Kind (R : Request) return Request_Kind
   is
   begin
      case R.Packet.Opcode is
         when 0 => return Read;
         when 1 => return Write;
         when 2 => return Sync;
         when 3 => return Trim;
         when others =>
            raise Constraint_Error;
      end case;
   end Kind;

   function Status (R : Request) return Request_Status
   is
   begin
      case R.Status is
         when Componolit.Interfaces.Internal.Block.Raw          => return Raw;
         when Componolit.Interfaces.Internal.Block.Allocated    => return Allocated;
         when Componolit.Interfaces.Internal.Block.Pending      => return Pending;
         when Componolit.Interfaces.Internal.Block.Ok           => return Ok;
         when Componolit.Interfaces.Internal.Block.Error        => return Error;
      end case;
   end Status;

   function Start (R : Request) return Id
   is
   begin
      return Id (R.Packet.Block_Number);
   end Start;

   function Length (R : Request) return Count
   is
   begin
      return Count (R.Packet.Block_Count);
   end Length;

   function Identifier (R : Request) return Request_Id
   is
   begin
      return Request_Id'Val (R.Packet.Tag);
   end Identifier;

   procedure Allocate_Request (C : in out Client_Session;
                               R : in out Request;
                               K :        Request_Kind;
                               S :        Id;
                               L :        Count;
                               I :        Request_Id;
                               E :    out Result)
   is
      use type Cxx.Unsigned_Long;
      Opcode : Integer;
      Res    : Integer;
   begin
      case K is
         when Read  => Opcode := 0;
         when Write => Opcode := 1;
         when Sync  => Opcode := 2;
         when Trim  => Opcode := 3;
         when others => Opcode := -1;
      end case;
      R.Packet.Block_Count := 0;
      Cxx.Block.Client.Allocate_Request (C.Instance, R.Packet, Opcode,
                                         Cxx.Genode.Uint64_T (S),
                                         Cxx.Unsigned_Long (L),
                                         Cxx.Unsigned_Long (Request_Id'Pos (I)),
                                         Res);
      if R.Packet.Block_Count > 0 and Res = 0 then
         R.Status := Componolit.Interfaces.Internal.Block.Allocated;
         E        := Success;
      else
         if Res = 1 then
            E := Out_Of_Memory;
         else
            E := Unsupported;
         end if;
      end if;
   end Allocate_Request;

   pragma Warnings (Off, "formal parameter ""C"" is not modified");
   --  Cxx.Block.Client.Update_Response_Queue modifies state
   procedure Update_Response_Queue (C : in out Client_Session;
                                    H : in out Request_Handle)
   is
      State   : Integer;
      Success : Integer;
      Tag     : Cxx.Unsigned_Long;
   begin
      if not H.Valid then
         Cxx.Block.Client.Update_Response_Queue (C.Instance, State, Tag, Success);
         if State = 1 then
            H := Request_Handle'(Valid   => True,
                                 Tag     => Tag,
                                 Success => Success = 1);
         end if;
      end if;
   end Update_Response_Queue;
   pragma Warnings (On, "formal parameter ""C"" is not modified");

   procedure Update_Request (C : in out Client_Session;
                             R : in out Request)
   is
      use type Cxx.Unsigned_Long;
   begin
      for I in H_Cache'Range loop
         Update_Response_Queue (C, H_Cache (I));
         if
            H_Cache (I).Valid
            and then H_Cache (I).Tag = R.Packet.Tag
         then
            R.Status := (if
                            H_Cache (I).Success
                         then
                            Componolit.Interfaces.Internal.Block.Ok
                         else
                            Componolit.Interfaces.Internal.Block.Error);
            H_Cache (I) := Request_Handle'(Valid   => False,
                                           Tag     => 0,
                                           Success => False);
         end if;
      end loop;
   end Update_Request;

   function Create return Client_Session
   is
   begin
      return Client_Session'(Instance => Cxx.Block.Client.Constructor);
   end Create;

   function Instance (C : Client_Session) return Client_Instance
   is
   begin
      return Client_Instance (Cxx.Block.Client.Get_Instance (C.Instance));
   end Instance;

   function Initialized (C : Client_Session) return Boolean
   is
   begin
      return Cxx.Block.Client.Initialized (C.Instance) = Cxx.Bool'Val (1);
   end Initialized;

   procedure Crw (C : Client_Instance;
                  O : Integer;
                  B : Size;
                  T : Cxx.Unsigned_Long;
                  L : Count;
                  D : System.Address);

   procedure Crw (C : Client_Instance;
                  O : Integer;
                  B : Size;
                  T : Cxx.Unsigned_Long;
                  L : Count;
                  D : System.Address)
   is
      Data : Buffer (1 .. B * L) with
         Address => D;
   begin
      case O is
         when 1 =>
            Write (C, Request_Id'Val (T), Data);
         when 0 =>
            Read (C, Request_Id'Val (T), Data);
         when others =>
            null;
      end case;
   end Crw;

   procedure Initialize (C           : in out Client_Session;
                         Cap         :        Componolit.Interfaces.Types.Capability;
                         Path        :        String;
                         Buffer_Size :        Byte_Length := 0) with
      SPARK_Mode => Off
   is
      C_Path : constant String := Path & Character'Val (0);
      subtype C_Path_String is String (1 .. C_Path'Length);
      subtype C_String is Cxx.Char_Array (1 .. C_Path'Length);
      function To_C_String is new Ada.Unchecked_Conversion (C_Path_String,
                                                            C_String);
   begin
      Cxx.Block.Client.Initialize (C.Instance,
                                   Cap,
                                   To_C_String (C_Path),
                                   Event'Address,
                                   Crw'Address,
                                   Cxx.Genode.Uint64_T (Buffer_Size));
   end Initialize;

   procedure Finalize (C : in out Client_Session)
   is
   begin
      Cxx.Block.Client.Finalize (C.Instance);
   end Finalize;

   procedure Enqueue (C : in out Client_Session;
                      R : in out Request)
   is
   begin
      Cxx.Block.Client.Enqueue (C.Instance, R.Packet);
      R.Status := Componolit.Interfaces.Internal.Block.Pending;
   end Enqueue;

   procedure Submit (C : in out Client_Session)
   is
   begin
      Cxx.Block.Client.Submit (C.Instance);
   end Submit;

   procedure Read (C : in out Client_Session;
                   R :        Request)
   is
   begin
      Cxx.Block.Client.Read (C.Instance, R.Packet);
   end Read;

   procedure Release (C : in out Client_Session;
                      R : in out Request)
   is
   begin
      Cxx.Block.Client.Release (C.Instance, R.Packet);
      R.Status := Componolit.Interfaces.Internal.Block.Raw;
   end Release;

   function Writable (C : Client_Session) return Boolean
   is
   begin
      return Cxx.Block.Client.Writable (C.Instance) /= Cxx.Bool'Val (0);
   end Writable;

   function Block_Count (C : Client_Session) return Count
   is
   begin
      return Count (Cxx.Block.Client.Block_Count (C.Instance));
   end Block_Count;

   function Block_Size (C : Client_Session) return Size
   is
   begin
      return Size (Cxx.Block.Client.Block_Size (C.Instance));
   end Block_Size;

end Componolit.Interfaces.Block.Client;
