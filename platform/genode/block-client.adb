
with Ada.Unchecked_Conversion;
with Cxx;
with Cxx.Block;
with Cxx.Genode;
use all type Cxx.Bool;

package body Block.Client is

   function Create_Device return Device
   is
   begin
      return Device' (Instance => Cxx.Block.Client.Constructor);
   end Create_Device;

   procedure Initialize_Device (D : in out Device; Path : String)
   is
      C_Path : constant String := Path & Character'Val(0);
      subtype C_Path_String is String (1 .. C_Path'Length);
      subtype C_String is Cxx.Char_Array (1 .. C_Path'Length);
      function To_C_String is new Ada.Unchecked_Conversion (C_Path_String, C_String);
   begin

      Cxx.Block.Client.Initialize (D.Instance, To_C_String (C_Path));
   end Initialize_Device;

   procedure Finalize_Device (D : in out Device)
   is
   begin
      Cxx.Block.Client.Finalize (D.Instance);
   end Finalize_Device;

   function Convert_Request (R : Request) return Cxx.Block.Client.Request.Class
   is
      Cr : Cxx.Block.Client.Request.Class := Cxx.Block.Client.Request.Class' (
         Kind => Cxx.Block.Client.None,
         Uid => Cxx.Unsigned_Char_Array (R.Priv),
         Start => 0,
         Length => 0,
         Status => Cxx.Block.Client.Raw);
   begin
      case R.Kind is
         when None =>
            null;
         when Sync =>
            Cr.Kind := Cxx.Block.Client.Sync;
         when Read | Write =>
            Cr.Kind := (if R.Kind = Read then Cxx.Block.Client.Read else Cxx.Block.Client.Write);
            Cr.Start := Cxx.Genode.Uint64_T (R.Start);
            Cr.Length := Cxx.Genode.Uint64_T (R.Length);
            if R.Status = Raw then
               Cr.Status := Cxx.Block.Client.Raw;
            end if;
            if R.Status = Ok then
               Cr.Status := Cxx.Block.Client.Ok;
            end if;
            if R.Status = Error then
               Cr.Status := Cxx.Block.Client.Error;
            end if;
            if R.Status = Acknowledged then
               Cr.Status := Cxx.Block.Client.Ack;
            end if;
      end case;
      return Cr;
   end Convert_Request;

   function Convert_Request (CR : Cxx.Block.Client.Request.Class) return Request
   is
      R : Request ((case CR.Kind is
                     when Cxx.Block.Client.None => None,
                     when Cxx.Block.Client.Read => Read,
                     when Cxx.Block.Client.Write => Write,
                     when Cxx.Block.Client.Sync => Sync));
   begin
      R.Priv := Private_Data (CR.Uid);
      case R.Kind is
         when None | Sync =>
            null;
         when Read | Write =>
            R.Start := Id (CR.Start);
            R.Length := Count (CR.Length);
            R.Status :=
               (case CR.Status is
                  when Cxx.Block.Client.Raw => Raw,
                  when Cxx.Block.Client.Ok => Ok,
                  when Cxx.Block.Client.Error => Error,
                  when Cxx.Block.Client.Ack => Acknowledged);
      end case;
      return R;
   end Convert_Request;

   procedure Submit_Read (D : Device; R : Request)
   is
   begin
      Cxx.Block.Client.Submit_Read (D.Instance, Convert_Request (R));
   end Submit_Read;

   procedure Submit_Sync (D : Device; R : Request)
   is
   begin
      Cxx.Block.Client.Submit_Sync (D.Instance, Convert_Request (R));
   end Submit_Sync;

   procedure Submit_Write (D : Device; R : Request; B : Buffer)
   is
      subtype Local_Buffer is Buffer (1 .. B'Length);
      subtype Local_U8_Array is Cxx.Genode.Uint8_T_Array (1 .. B'Length);
      function Convert_Buffer is new Ada.Unchecked_Conversion (Local_Buffer, Local_U8_Array);
      Data : Local_U8_Array := Convert_Buffer (B);
   begin
      Cxx.Block.Client.Submit_Write (
         D.Instance,
         Convert_Request (R),
         Data,
         Cxx.Genode.Uint64_T (B'Length));
   end Submit_Write;

   function Next (D : Device) return Request
   is
   begin
      return Convert_Request (Cxx.Block.Client.Next (D.Instance));
   end Next;

   procedure Read (D : Device; R : in out Request; B : out Buffer)
   is
      subtype Local_Buffer is Buffer (1 .. B'Length);
      subtype Local_U8_Array is Cxx.Genode.Uint8_T_Array (1 .. B'Length);
      function Convert_Buffer is new Ada.Unchecked_Conversion (Local_U8_Array, Local_Buffer);
      Data : Local_U8_Array := (others => 0);
      Req : Cxx.Block.Client.Request.Class := Convert_Request (R);
   begin
      Cxx.Block.Client.Read (
         D.Instance,
         Req,
         Data,
         Cxx.Genode.Uint64_T (B'Length));
      B := Convert_Buffer (Data);
      R := Convert_Request (Req);
   end Read;

   procedure Acknowledge (D : Device; R : in out Request)
   is
   begin
      Cxx.Block.Client.Acknowledge (D.Instance, Convert_Request (R));
      R.Status := Ok;
   end Acknowledge;

   function Writable (D : Device) return Boolean
   is
   begin
      return Cxx.Block.Client.Writable (D.Instance) /= 0;
   end Writable;

   function Block_Count (D : Device) return Count
   is
   begin
      return Count (Cxx.Block.Client.Block_Count (D.Instance));
   end Block_Count;

   function Block_Size (D : Device) return Size
   is
   begin
      return Size (Cxx.Block.Client.Block_Size (D.Instance));
   end Block_Size;

   function Maximal_Transfer_Size (D : Device) return Unsigned_Long
   is
      pragma Unreferenced (D);
   begin
      return 1024 * 1024;
   end Maximal_Transfer_Size;

end Block.Client;
